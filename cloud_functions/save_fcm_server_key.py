#!/usr/bin/env python3
"""
Save FCM Server Key to Firestore for Hunar Push Notifications.

This script saves the FCM Legacy Server Key to Firestore
so the Flutter app can read it and send push notifications directly.

HOW TO GET THE SERVER KEY:
  1. Open Firebase Console: https://console.firebase.google.com/
  2. Select project "usto1-17806"
  3. Click gear icon → Project settings
  4. Go to "Cloud Messaging" tab
  5. Find "Cloud Messaging API (Legacy)" section
  6. If DISABLED → click 3-dot menu → "Manage API in Google Cloud Console" → Enable it
  7. Copy the "Server key" value
  8. Paste it below and run this script

ALTERNATIVE (without this script):
  Go to Firebase Console → Firestore Database
  Create document: app_config/fcm
  Add field: serverKey = "YOUR_SERVER_KEY_HERE"

USAGE:
  python3 save_fcm_server_key.py YOUR_SERVER_KEY_HERE
"""

import sys
import os
import json


def main():
    if len(sys.argv) < 2:
        print("=" * 60)
        print("  HUNAR — Save FCM Server Key")
        print("=" * 60)
        print()
        print("Usage: python3 save_fcm_server_key.py YOUR_SERVER_KEY")
        print()
        print("HOW TO GET THE SERVER KEY:")
        print("  1. Open: https://console.firebase.google.com/")
        print("  2. Select project 'usto1-17806'")
        print("  3. Gear icon → Project settings")
        print("  4. 'Cloud Messaging' tab")
        print("  5. 'Cloud Messaging API (Legacy)' section")
        print("  6. If disabled → enable it via Google Cloud Console")
        print("  7. Copy 'Server key'")
        print("  8. Run: python3 save_fcm_server_key.py PASTE_KEY_HERE")
        print()
        print("OR set it manually in Firestore:")
        print("  Collection: app_config")
        print("  Document: fcm")
        print("  Field: serverKey = 'YOUR_KEY'")
        print("=" * 60)
        return

    server_key = sys.argv[1].strip()
    
    if not server_key.startswith('AAAA') and not server_key.startswith('key='):
        print("WARNING: Server key usually starts with 'AAAA...'")
        print(f"  You entered: {server_key[:20]}...")
        
    if server_key.startswith('key='):
        server_key = server_key[4:]
    
    print(f"Server key: {server_key[:15]}...{server_key[-5:]}")
    print(f"Length: {len(server_key)} characters")
    print()

    # Try to save to Firestore using firebase-admin
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
        
        # Try various service account paths
        sa_paths = [
            os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', ''),
            './service-account-key.json',
            '../service-account-key.json',
            '/opt/flutter/service-account-key.json',
        ]
        
        initialized = False
        for path in sa_paths:
            if not path or not os.path.exists(path):
                continue
            try:
                with open(path) as f:
                    data = json.load(f)
                if data.get('type') != 'service_account':
                    continue
                cred = credentials.Certificate(path)
                firebase_admin.initialize_app(cred)
                initialized = True
                print(f"Firebase initialized with: {path}")
                break
            except Exception:
                continue
        
        if not initialized:
            try:
                firebase_admin.initialize_app()
                initialized = True
                print("Firebase initialized with default credentials")
            except Exception:
                pass
        
        if initialized:
            db = firestore.client()
            db.collection('app_config').document('fcm').set({
                'serverKey': server_key,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })
            print("Server key saved to Firestore: app_config/fcm")
            print()
            print("Push notifications are now ENABLED!")
            print("The Flutter app will automatically load this key on startup.")
            return
            
    except ImportError:
        pass
    except Exception as e:
        print(f"Firestore save failed: {e}")

    # Fallback: show manual instructions
    print()
    print("Could not save automatically. Please set it MANUALLY:")
    print()
    print("  1. Open: https://console.firebase.google.com/")
    print("  2. Select project 'usto1-17806'")
    print("  3. Go to 'Firestore Database'")
    print("  4. Create collection: 'app_config'")
    print("  5. Create document with ID: 'fcm'")
    print("  6. Add field:")
    print(f"     Name: serverKey")
    print(f"     Type: string")
    print(f"     Value: {server_key}")
    print()
    print("After saving, the app will send push notifications on next restart!")


if __name__ == '__main__':
    main()
