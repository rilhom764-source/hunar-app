## Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

## Prevent obfuscation of types which use ButterKnife annotations
-dontwarn io.flutter.embedding.**

## ==========================================
## IMAGE PICKER - CRITICAL for photo functionality
## ==========================================
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-keep class androidx.core.content.FileProvider$SimplePathStrategy { *; }
-keep class com.ustoconnect.connect.** { *; }

## AndroidX Core (required for FileProvider, camera, gallery)
-keep class androidx.core.** { *; }
-keep class androidx.appcompat.** { *; }
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.** { *; }

## ExifInterface (used by image_picker for image rotation)
-keep class androidx.exifinterface.** { *; }

## ==========================================
## PERMISSION HANDLER - CRITICAL for runtime permissions
## ==========================================
-keep class com.baseflow.permissionhandler.** { *; }

## ==========================================
## RECORD (Audio Recording)
## ==========================================
-keep class com.llfbandit.record.** { *; }
-keep class com.llfbandit.record.record.** { *; }

## ==========================================
## AUDIOPLAYERS (Audio Playback)
## ==========================================
-keep class xyz.luan.audioplayers.** { *; }

## ==========================================
## PATH PROVIDER
## ==========================================
-keep class io.flutter.plugins.pathprovider.** { *; }

## ==========================================
## CACHED NETWORK IMAGE
## ==========================================
-keep class com.baseflow.cachednetworkimage.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

## ==========================================
## Firebase
## ==========================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## Firebase Storage - CRITICAL for uploads
-keep class com.google.firebase.storage.** { *; }
-keep class com.google.firebase.storage.FirebaseStorage { *; }
-keep class com.google.firebase.storage.StorageReference { *; }
-keep class com.google.firebase.storage.UploadTask { *; }
-keep class com.google.firebase.storage.FileDownloadTask { *; }

## Firebase Auth
-keep class com.google.firebase.auth.** { *; }

## Firestore / gRPC
-keep class io.grpc.** { *; }
-keep class com.google.cloud.** { *; }

## ==========================================
## Google Maps
## ==========================================
-keep class com.google.android.gms.maps.** { *; }

## ==========================================
## Geolocator
## ==========================================
-keep class com.baseflow.geolocator.** { *; }

## ==========================================
## Shared Preferences
## ==========================================
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## ==========================================
## OkHttp (required by Firebase gRPC and network operations)
## ==========================================
-dontwarn com.squareup.okhttp.CipherSuite
-dontwarn com.squareup.okhttp.ConnectionSpec
-dontwarn com.squareup.okhttp.TlsVersion
-dontwarn com.squareup.okhttp.**
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

## ==========================================
## General Android
## ==========================================
## Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

## Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Don't warn about missing classes
-dontwarn java.lang.invoke.StringConcatFactory
-dontwarn javax.annotation.**
-dontwarn sun.misc.**
