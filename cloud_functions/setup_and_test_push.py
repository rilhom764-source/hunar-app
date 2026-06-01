#!/usr/bin/env python3
"""
Push Notification Setup & Test Tool for Hunar App.

This script:
1. Verifies Firebase Admin SDK configuration
2. Checks Firestore for FCM tokens
3. Sends a test push notification
4. Processes any pending notifications

SETUP:
  1. Go to Firebase Console: https://console.firebase.google.com/
  2. Select project "usto1-17806"
  3. Project Settings -> Service accounts
  4. Select "Python" as language
  5. Click "Generate new private key" -> Download JSON
  6. Save as: /home/user/flutter_app/cloud_functions/service-account-key.json

USAGE:
  python3 setup_and_test_push.py
  python3 setup_and_test_push.py --test-token=YOUR_FCM_TOKEN
  python3 setup_and_test_push.py --daemon
"""

import json
import os
import sys
import time

def find_service_account_key():
    """Find a valid Firebase service account key."""
    paths = [
        './service-account-key.json',
        '../service-account-key.json',
        '/opt/flutter/service-account-key.json',
        '/opt/flutter/firebase-admin-sdk.json',
        os.path.expanduser('~/service-account-key.json'),
    ]
    
    env_key = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', '')
    if env_key:
        paths.insert(0, env_key)
    
    for path in paths:
        if not os.path.exists(path):
            continue
        try:
            with open(path, 'r') as f:
                data = json.load(f)
            if data.get('type') == 'service_account':
                return path, data
            else:
                print(f"  {path}: not a service account key (found: {data.get('type', list(data.keys())[:3])})")
        except Exception as e:
            print(f"  {path}: error reading - {e}")
    
    return None, None


def main():
    print("=" * 60)
    print("  HUNAR - Push Notification Setup & Test")
    print("=" * 60)
    print()
    
    # Step 1: Find service account key
    print("[1/4] Looking for Firebase Service Account Key...")
    key_path, key_data = find_service_account_key()
    
    if not key_path:
        print()
        print("  ERROR: Firebase Service Account Key NOT FOUND!")
        print()
        print("  This key is REQUIRED to send push notifications.")
        print("  Without it, notifications are queued in Firestore")
        print("  but NEVER delivered to devices.")
        print()
        print("  HOW TO GET IT:")
        print("  1. Open: https://console.firebase.google.com/")
        print("  2. Select project: usto1-17806")
        print("  3. Click gear icon -> Project settings")
        print("  4. Go to 'Service accounts' tab")
        print("  5. Select 'Python' as language")
        print("  6. Click 'Generate new private key'")
        print("  7. Download the JSON file")
        print("  8. Save it here:")
        print("     /home/user/flutter_app/cloud_functions/service-account-key.json")
        print()
        print("  Then run this script again.")
        print("=" * 60)
        return False
    
    print(f"  Found: {key_path}")
    print(f"  Project: {key_data.get('project_id', 'unknown')}")
    print()
    
    # Step 2: Initialize Firebase
    print("[2/4] Initializing Firebase Admin SDK...")
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore, messaging
        
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
        print("  Firebase initialized successfully!")
    except Exception as e:
        print(f"  ERROR: {e}")
        return False
    print()
    
    # Step 3: Check Firestore for FCM tokens
    print("[3/4] Checking Firestore for registered devices...")
    db = firestore.client()
    
    try:
        tokens = list(db.collection('fcm_tokens').stream())
        print(f"  Registered devices: {len(tokens)}")
        
        for doc in tokens:
            data = doc.to_dict()
            token = data.get('token', '')
            uid = data.get('userId', doc.id)
            platform = data.get('platform', '?')
            print(f"    - User {uid[:12]}... [{platform}] token: {token[:20]}...")
        
        if not tokens:
            print("  No devices registered! Open the app on your phone first.")
            print("  The app will automatically register the device for push notifications.")
            
    except Exception as e:
        print(f"  ERROR reading tokens: {e}")
    print()
    
    # Step 4: Check pending notifications
    print("[4/4] Checking pending notifications...")
    try:
        pending = list(
            db.collection('pending_notifications')
              .where('sent', '==', False)
              .limit(100)
              .stream()
        )
        print(f"  Pending (unsent): {len(pending)}")
        
        queue = list(
            db.collection('push_queue')
              .where('processed', '==', False)
              .limit(100)
              .stream()
        )
        print(f"  Queue (unprocessed): {len(queue)}")
        
    except Exception as e:
        print(f"  ERROR: {e}")
    
    print()
    print("=" * 60)
    
    # Send test push if --test-token provided
    test_token = None
    daemon_mode = '--daemon' in sys.argv
    
    for arg in sys.argv[1:]:
        if arg.startswith('--test-token='):
            test_token = arg.split('=', 1)[1]
    
    if test_token:
        print()
        print("Sending TEST push notification...")
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title='Hunar - Test',
                    body='Push-notifications work! / Push-uvedomleniya rabotayut!',
                ),
                data={'type': 'test'},
                token=test_token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='hunar_notifications',
                        icon='@mipmap/ic_launcher',
                        color='#2E7D32',
                        sound='default',
                    ),
                ),
            )
            response = messaging.send(message)
            print(f"  SUCCESS! Message ID: {response}")
        except Exception as e:
            print(f"  FAILED: {e}")
    elif tokens:
        # Try sending test to first registered device
        print()
        print("Sending test push to first registered device...")
        first_token = tokens[0].to_dict().get('token', '')
        if first_token:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title='Hunar - Test',
                        body='Push-notifications are working!',
                    ),
                    data={'type': 'test'},
                    token=first_token,
                    android=messaging.AndroidConfig(
                        priority='high',
                        notification=messaging.AndroidNotification(
                            channel_id='hunar_notifications',
                            icon='@mipmap/ic_launcher',
                            color='#2E7D32',
                            sound='default',
                        ),
                    ),
                )
                response = messaging.send(message)
                print(f"  SUCCESS! Message ID: {response}")
            except Exception as e:
                print(f"  FAILED: {e}")
    
    # Process pending notifications
    if pending or queue:
        print()
        print("Processing pending notifications...")
        from send_push import process_pending_notifications, process_push_queue
        sent1, err1 = process_pending_notifications()
        sent2, err2 = process_push_queue()
        print(f"  Sent: {sent1 + sent2}, Errors: {err1 + err2}")
    
    if daemon_mode:
        print()
        print("Starting daemon mode (checking every 10 seconds)...")
        print("Press Ctrl+C to stop")
        from send_push import run_daemon
        run_daemon(interval=10)
    
    return True


if __name__ == '__main__':
    main()
