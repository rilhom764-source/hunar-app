#!/usr/bin/env python3
"""
One-time setup script to save FCM Server Key to Firestore.
This allows the Flutter app to send push notifications directly via FCM HTTP API.

STEPS:
1. Go to Firebase Console -> Project Settings -> Cloud Messaging
2. If "Cloud Messaging API (Legacy)" is disabled, click "Manage API in Google Cloud Console" 
   and enable "Firebase Cloud Messaging API" (Legacy)
3. Copy the "Server key" 
4. Run this script: python3 setup_fcm_key.py YOUR_SERVER_KEY

ALTERNATIVE: Use Firebase Cloud Messaging API (V1) — requires Service Account Key.
"""

import sys
import os

# Try to use firebase-admin
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("firebase-admin not installed. Installing...")
    os.system("pip install firebase-admin==7.1.0")
    import firebase_admin
    from firebase_admin import credentials, firestore


def setup_via_admin_sdk(server_key):
    """Use Firebase Admin SDK to write the server key to Firestore."""
    # Try to find admin SDK key
    possible_paths = [
        '/opt/flutter/firebase-admin-sdk.json',
        os.environ.get('FIREBASE_ADMIN_KEY', ''),
    ]
    
    # The firebase-admin-sdk.json in /opt/flutter/ is actually google-services.json format
    # We need a real service account key with private_key field
    # For now, try to initialize with default credentials or existing key
    
    for path in possible_paths:
        if path and os.path.exists(path):
            try:
                import json
                with open(path) as f:
                    data = json.load(f)
                # Check if it's a real service account key (has private_key)
                if 'private_key' in data:
                    cred = credentials.Certificate(path)
                    firebase_admin.initialize_app(cred)
                    db = firestore.client()
                    db.collection('app_config').document('fcm').set({
                        'serverKey': server_key,
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                    })
                    print(f"Server key saved to Firestore (app_config/fcm)")
                    return True
                else:
                    print(f"  {path} is not a service account key (no private_key field)")
            except Exception as e:
                print(f"  Error with {path}: {e}")
    
    print("\nNo valid Firebase Admin SDK service account key found.")
    print("You can set the server key manually in Firestore:")
    print(f"  Collection: app_config")
    print(f"  Document:   fcm")
    print(f"  Field:      serverKey = {server_key}")
    print(f"\nOr set it via Firebase Console -> Firestore -> app_config -> fcm -> serverKey")
    return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 setup_fcm_key.py YOUR_FCM_SERVER_KEY")
        print()
        print("To get your Server Key:")
        print("1. Go to Firebase Console -> Project Settings -> Cloud Messaging")
        print("2. Under 'Cloud Messaging API (Legacy)' section")
        print("3. Copy the 'Server key'")
        print()
        print("If Legacy API is disabled:")
        print("  Click 'Manage API in Google Cloud Console'")
        print("  Enable 'Firebase Cloud Messaging API'")
        return
    
    server_key = sys.argv[1].strip()
    
    if not server_key.startswith('AAAA') and not server_key.startswith('BI'):
        print("WARNING: FCM Server Key usually starts with 'AAAA...' (Legacy) or 'BI...' (VAPID)")
        print(f"Your key starts with: {server_key[:10]}...")
    
    print(f"FCM Server Key: {server_key[:20]}...")
    print()
    
    # Try Admin SDK first
    if not setup_via_admin_sdk(server_key):
        print()
        print("=" * 60)
        print("MANUAL SETUP REQUIRED")
        print("=" * 60)
        print()
        print("Go to Firebase Console -> Firestore Database")
        print("Create collection 'app_config' if it doesn't exist")
        print("Create document 'fcm' with field:")
        print(f"  serverKey (string) = {server_key}")
        print()
        print("After this, the Flutter app will load the key on startup")
        print("and send push notifications directly via FCM HTTP API.")


if __name__ == '__main__':
    main()
