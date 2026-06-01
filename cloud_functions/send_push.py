#!/usr/bin/env python3
"""
Push Notification Sender for Hunar App.
Reads pending_notifications from Firestore and sends via FCM Admin SDK.

REQUIREMENTS:
  pip install firebase-admin==7.1.0

SETUP:
  1. Go to Firebase Console -> Project Settings -> Service accounts
  2. Select "Python" -> "Generate new private key"
  3. Save the JSON file

USAGE:
  # One-time run:
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json python3 send_push.py

  # Daemon mode (checks every 10 seconds):
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json python3 send_push.py --daemon

  # OR specify path directly:
  python3 send_push.py --key=/path/to/service-account.json
  python3 send_push.py --key=/path/to/service-account.json --daemon
"""

import firebase_admin
from firebase_admin import credentials, firestore, messaging
import sys
import os
import time
import json


def init_firebase(key_path=None):
    """Initialize Firebase Admin SDK with service account key."""
    # Priority: CLI arg > env var > default paths
    possible_paths = []
    
    if key_path:
        possible_paths.append(key_path)
    
    env_key = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', '')
    if env_key:
        possible_paths.append(env_key)
    
    env_key2 = os.environ.get('FIREBASE_ADMIN_KEY', '')
    if env_key2:
        possible_paths.append(env_key2)
    
    # Default paths
    possible_paths.extend([
        '/opt/flutter/firebase-admin-sdk.json',
        '/opt/flutter/firebase-service-account.json',
        '/opt/flutter/service-account.json',
        os.path.expanduser('~/firebase-service-account.json'),
        os.path.expanduser('~/service-account.json'),
    ])
    
    for path in possible_paths:
        if not os.path.exists(path):
            continue
        try:
            # Verify it's a real service account key (not google-services.json)
            with open(path, 'r') as f:
                data = json.load(f)
            if data.get('type') != 'service_account':
                print(f"  Skipping {path}: not a service account key (type={data.get('type', 'unknown')})")
                continue
            
            cred = credentials.Certificate(path)
            firebase_admin.initialize_app(cred)
            print(f"Firebase initialized with: {path}")
            print(f"  Project ID: {data.get('project_id', 'unknown')}")
            return True
        except Exception as e:
            print(f"  Error with {path}: {e}")
            continue
    
    # Try default credentials (for Cloud Functions / Cloud Run / GCE)
    try:
        firebase_admin.initialize_app()
        print("Firebase initialized with default credentials (Application Default Credentials)")
        return True
    except Exception as e:
        print(f"\nFailed to initialize Firebase: {e}")
        print("\n" + "="*60)
        print("HOW TO FIX:")
        print("="*60)
        print("1. Go to Firebase Console: https://console.firebase.google.com/")
        print("2. Open your project -> Project Settings -> Service accounts")
        print("3. Select 'Python' as language")
        print("4. Click 'Generate new private key' -> Download JSON")
        print("5. Run: python3 send_push.py --key=/path/to/downloaded-key.json")
        print("="*60)
        return False


def process_pending_notifications():
    """Process pending_notifications collection — send via FCM Admin SDK."""
    db = firestore.client()
    
    # Query: not yet processed/sent
    pending = list(
        db.collection('pending_notifications')
          .where('sent', '==', False)
          .limit(100)
          .stream()
    )
    
    if not pending:
        return 0, 0
    
    sent_count = 0
    error_count = 0
    
    for doc in pending:
        data = doc.to_dict()
        token = data.get('token', '')
        title = data.get('title', '')
        body = data.get('body', '')
        extra_data = data.get('data', {})
        target_user = data.get('targetUserId', '')
        
        # If no token, try to look up by targetUserId
        if not token and target_user:
            try:
                token_doc = db.collection('fcm_tokens').document(target_user).get()
                if token_doc.exists:
                    token = token_doc.to_dict().get('token', '')
            except Exception:
                pass
        
        if not token:
            doc.reference.update({'sent': True, 'error': 'No FCM token found'})
            continue
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data={str(k): str(v) for k, v in extra_data.items()} if extra_data else {},
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='hunar_notifications',
                        icon='@mipmap/ic_launcher',
                        color='#2E7D32',
                        sound='default',
                        click_action='FLUTTER_NOTIFICATION_CLICK',
                    ),
                ),
            )
            
            response = messaging.send(message)
            doc.reference.update({
                'sent': True,
                'sentAt': firestore.SERVER_TIMESTAMP,
                'fcmResponse': response,
            })
            sent_count += 1
            print(f"  SENT: [{data.get('type', '?')}] {title} -> user:{target_user[:8]}...")
            
        except messaging.UnregisteredError:
            doc.reference.update({'sent': True, 'error': 'Token expired/unregistered'})
            # Clean up expired token
            if target_user:
                try:
                    db.collection('fcm_tokens').document(target_user).delete()
                except Exception:
                    pass
            error_count += 1
        except messaging.SenderIdMismatchError:
            doc.reference.update({'sent': True, 'error': 'SenderIdMismatch - wrong project'})
            error_count += 1
        except Exception as e:
            doc.reference.update({'sent': True, 'error': str(e)[:500]})
            error_count += 1
            print(f"  ERROR: {e}")
    
    return sent_count, error_count


def process_push_queue():
    """Process push_queue for topic-based notifications."""
    db = firestore.client()
    
    queue = list(
        db.collection('push_queue')
          .where('processed', '==', False)
          .limit(50)
          .stream()
    )
    
    if not queue:
        return 0, 0
    
    sent_count = 0
    error_count = 0
    
    for doc in queue:
        data = doc.to_dict()
        title = data.get('title', '')
        body = data.get('body', '')
        target_topic = data.get('targetTopic', '')
        extra_data = data.get('data', {})
        
        try:
            if target_topic:
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data={str(k): str(v) for k, v in extra_data.items()} if extra_data else {},
                    topic=target_topic,
                    android=messaging.AndroidConfig(
                        priority='high',
                        notification=messaging.AndroidNotification(
                            channel_id='hunar_notifications',
                            sound='default',
                        ),
                    ),
                )
                response = messaging.send(message)
                sent_count += 1
                print(f"  TOPIC [{target_topic}]: {title} -> {response}")
            
            doc.reference.update({
                'processed': True,
                'processedAt': firestore.SERVER_TIMESTAMP,
            })
            
        except Exception as e:
            doc.reference.update({'processed': True, 'error': str(e)[:500]})
            error_count += 1
            print(f"  TOPIC ERROR: {e}")
    
    return sent_count, error_count


def get_stats():
    """Get notification queue stats."""
    db = firestore.client()
    
    pending = len(list(db.collection('pending_notifications').where('sent', '==', False).limit(500).stream()))
    queue = len(list(db.collection('push_queue').where('processed', '==', False).limit(500).stream()))
    tokens = len(list(db.collection('fcm_tokens').limit(500).stream()))
    
    print(f"\nStats:")
    print(f"  Pending notifications: {pending}")
    print(f"  Push queue:            {queue}")
    print(f"  FCM tokens registered: {tokens}")
    return pending, queue, tokens


def run_once():
    """Process all pending notifications once."""
    total_sent = 0
    total_errors = 0
    
    print("\n--- Processing pending_notifications ---")
    sent, errors = process_pending_notifications()
    total_sent += sent
    total_errors += errors
    if sent or errors:
        print(f"  Result: {sent} sent, {errors} errors")
    else:
        print("  (empty)")
    
    print("--- Processing push_queue ---")
    sent, errors = process_push_queue()
    total_sent += sent
    total_errors += errors
    if sent or errors:
        print(f"  Result: {sent} sent, {errors} errors")
    else:
        print("  (empty)")
    
    return total_sent, total_errors


def run_daemon(interval=10):
    """Run as a daemon, checking every N seconds."""
    print(f"\nStarting push notification daemon (interval: {interval}s)")
    print("Press Ctrl+C to stop\n")
    
    total_sent = 0
    total_errors = 0
    cycles = 0
    
    while True:
        try:
            sent, errors = run_once()
            total_sent += sent
            total_errors += errors
            cycles += 1
            
            if cycles % 30 == 0:  # Stats every 5 minutes
                print(f"\n=== Daemon stats: {total_sent} total sent, {total_errors} total errors, {cycles} cycles ===")
                get_stats()
                
        except KeyboardInterrupt:
            print(f"\n\nDaemon stopped. Total: {total_sent} sent, {total_errors} errors")
            break
        except Exception as e:
            print(f"Daemon error: {e}")
        
        time.sleep(interval)


if __name__ == '__main__':
    # Parse args
    key_path = None
    daemon_mode = '--daemon' in sys.argv
    interval = 10
    show_stats = '--stats' in sys.argv
    
    for arg in sys.argv[1:]:
        if arg.startswith('--key='):
            key_path = arg.split('=', 1)[1]
        elif arg.startswith('--interval='):
            interval = int(arg.split('=', 1)[1])
    
    if not init_firebase(key_path):
        sys.exit(1)
    
    if show_stats:
        get_stats()
        sys.exit(0)
    
    if daemon_mode:
        run_daemon(interval)
    else:
        run_once()
        get_stats()
        print("\nDone!")
