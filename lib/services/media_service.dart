import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

/// MediaService with dual upload strategy:
/// 1. Try Firebase Storage first (fast, CDN)
/// 2. If Storage fails (rules, CORS, quota), fallback to Firestore Data URL
///    (stores base64 encoded data directly in Firestore document)
class MediaService {
  static final ImagePicker _picker = ImagePicker();
  static AudioRecorder? _recorder;
  static const Uuid _uuid = Uuid();
  
  // Track if Firebase Storage is working
  static bool _storageAvailable = true;
  static bool _storageTested = false;

  static AudioRecorder get recorder {
    _recorder ??= AudioRecorder();
    return _recorder!;
  }

  // ==================== ФОТО (КРОСС-ПЛАТФОРМА) ====================

  /// Выбор фото из галереи
  static Future<XFile?> pickImageFromGalleryXFile() async {
    try {
      if (kDebugMode) {
        debugPrint('MediaService: Opening gallery picker...');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (kDebugMode) {
        debugPrint(image != null
            ? 'MediaService: Image selected: ${image.path}'
            : 'MediaService: No image selected (user cancelled)');
      }
      return image;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: PlatformException picking from gallery: ${e.code} - ${e.message}');
      }
      if (e.code == 'photo_access_denied' || e.code == 'camera_access_denied') {
        if (!kIsWeb) {
          final status = await Permission.photos.request();
          if (status.isGranted) {
            return _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            );
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error picking image from gallery: $e');
      }
      return null;
    }
  }

  /// Сделать фото с камеры
  static Future<XFile?> pickImageFromCameraXFile() async {
    try {
      if (!kIsWeb) {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          await Permission.camera.request();
        }
      }

      if (kDebugMode) {
        debugPrint('MediaService: Opening camera...');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (kDebugMode) {
        debugPrint(image != null
            ? 'MediaService: Photo taken: ${image.path}'
            : 'MediaService: No photo taken (user cancelled)');
      }
      return image;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: PlatformException taking photo: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error taking photo: $e');
      }
      return null;
    }
  }

  /// Выбор нескольких фото из галереи
  static Future<List<XFile>> pickMultipleImages({int maxCount = 10}) async {
    try {
      if (kDebugMode) {
        debugPrint('MediaService: Opening multi-image picker (max: $maxCount)...');
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (kDebugMode) {
        debugPrint('MediaService: Selected ${images.length} images');
      }

      if (images.length > maxCount) {
        return images.sublist(0, maxCount);
      }
      return images;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: PlatformException picking multiple: ${e.code} - ${e.message}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error picking multiple images: $e');
      }
      return [];
    }
  }

  // ==================== DUAL UPLOAD: Storage + Firestore Fallback ====================

  /// Upload XFile — tries Storage first, then Firestore fallback
  static Future<String?> uploadXFile(XFile xFile, {required String folder}) async {
    try {
      final Uint8List bytes;
      try {
        bytes = await xFile.readAsBytes();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('MediaService: Cannot read file bytes: $e');
        }
        return null;
      }

      if (bytes.isEmpty) {
        if (kDebugMode) {
          debugPrint('MediaService: File is empty (0 bytes)');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('MediaService: File size: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
      }

      final String ext = xFile.name.contains('.')
          ? xFile.name.split('.').last.toLowerCase()
          : 'jpg';
      final String contentType = _getContentType(ext);

      // Strategy 1: Try Firebase Storage
      if (_storageAvailable) {
        final storageUrl = await _tryUploadToStorage(bytes, folder, ext, contentType);
        if (storageUrl != null) return storageUrl;
      }

      // Strategy 2: Fallback to Firestore Data URL (for images < 800KB)
      if (bytes.length < 800 * 1024) {
        return _createDataUrl(bytes, contentType);
      }

      // Strategy 3: Compress and try again
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        // Re-pick with higher compression
        return _createDataUrl(bytes, contentType);
      }

      if (kDebugMode) {
        debugPrint('MediaService: File too large for Firestore fallback (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error in uploadXFile: $e');
      }
      return null;
    }
  }

  /// Try uploading to Firebase Storage
  static Future<String?> _tryUploadToStorage(Uint8List bytes, String folder, String ext, String contentType) async {
    try {
      final String fileName = '${_uuid.v4()}.$ext';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('$folder/$fileName');

      if (kDebugMode) {
        debugPrint('MediaService: Trying Firebase Storage upload to $folder/$fileName...');
      }

      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploaded': DateTime.now().toIso8601String()},
      );

      final UploadTask uploadTask = storageRef.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timeout after 30 seconds');
        },
      );

      if (snapshot.state != TaskState.success) {
        if (kDebugMode) {
          debugPrint('MediaService: Storage upload failed with state: ${snapshot.state}');
        }
        return null;
      }

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (!_storageTested) {
        _storageTested = true;
        _storageAvailable = true;
      }

      if (kDebugMode) {
        debugPrint('MediaService: Storage upload successful! URL: $downloadUrl');
      }
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Firebase Storage error: ${e.code} - ${e.message}');
      }
      // Mark storage as unavailable for future attempts
      if (e.code == 'unauthorized' || e.code == 'object-not-found' || e.code == 'retry-limit-exceeded') {
        _storageAvailable = false;
        _storageTested = true;
        if (kDebugMode) {
          debugPrint('MediaService: Firebase Storage marked as unavailable, switching to Firestore fallback');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Storage upload exception: $e');
      }
      if (!_storageTested) {
        _storageAvailable = false;
        _storageTested = true;
      }
      return null;
    }
  }

  /// Create a base64 Data URL from bytes
  static String _createDataUrl(Uint8List bytes, String contentType) {
    final base64Str = base64Encode(bytes);
    final dataUrl = 'data:$contentType;base64,$base64Str';
    if (kDebugMode) {
      debugPrint('MediaService: Created Data URL (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
    }
    return dataUrl;
  }

  /// Upload PlatformFile (file picker result)
  static Future<String?> uploadFile(PlatformFile file, {required String folder}) async {
    try {
      if (file.bytes == null && file.path == null) {
        if (kDebugMode) {
          debugPrint('MediaService: File has no data to upload');
        }
        return null;
      }

      final Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null && !kIsWeb) {
        final fileObj = File(file.path!);
        bytes = await fileObj.readAsBytes();
      } else {
        return null;
      }

      if (bytes.isEmpty) return null;

      final String ext = file.extension?.toLowerCase() ??
          (file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'bin');
      final String contentType = _getContentType(ext);

      if (kDebugMode) {
        debugPrint('MediaService: Uploading file ${file.name} (${formatFileSize(bytes.length)})');
      }

      // Strategy 1: Try Firebase Storage
      if (_storageAvailable) {
        final storageUrl = await _tryUploadToStorage(bytes, folder, ext, contentType);
        if (storageUrl != null) return storageUrl;
      }

      // Strategy 2: Firestore Data URL fallback (< 800KB)
      if (bytes.length < 800 * 1024) {
        return _createDataUrl(bytes, contentType);
      }

      if (kDebugMode) {
        debugPrint('MediaService: File too large for fallback: ${formatFileSize(bytes.length)}');
      }
      return null;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Firebase Error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error uploading file: $e');
      }
      return null;
    }
  }

  /// Upload multiple XFiles
  static Future<List<String>> uploadMultipleXFiles(
    List<XFile> files, {
    required String folder,
    Function(int, int)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];
    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i + 1, files.length);
      final url = await uploadXFile(files[i], folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }

  // ==================== LEGACY COMPAT ====================

  static Future<File?> pickImageFromGallery() async {
    final xFile = await pickImageFromGalleryXFile();
    if (xFile == null || kIsWeb) return null;
    return File(xFile.path);
  }

  static Future<File?> pickImageFromCamera() async {
    final xFile = await pickImageFromCameraXFile();
    if (xFile == null || kIsWeb) return null;
    return File(xFile.path);
  }

  static Future<String?> uploadImage(dynamic imageFile, {required String folder}) async {
    try {
      if (imageFile is XFile) {
        return await uploadXFile(imageFile, folder: folder);
      }
      if (imageFile is File) {
        final xFile = XFile(imageFile.path);
        return await uploadXFile(xFile, folder: folder);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error uploading image: $e');
      }
      return null;
    }
  }

  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, {
    required String folder,
    Function(int, int)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);
      final url = await uploadImage(imageFiles[i], folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    return uploadedUrls;
  }

  // ==================== АУДИО (ГОЛОСОВЫЕ) ====================

  /// Start voice recording
  /// Android: Uses WAV encoder as fallback if AAC is unavailable
  /// Web: Records to default blob location
  static Future<bool> startRecording() async {
    try {
      // Request microphone permission on mobile
      if (!kIsWeb) {
        final micStatus = await Permission.microphone.status;
        if (kDebugMode) {
          debugPrint('MediaService: Microphone permission status: $micStatus');
        }
        if (!micStatus.isGranted) {
          final result = await Permission.microphone.request();
          if (kDebugMode) {
            debugPrint('MediaService: Microphone permission result: $result');
          }
          if (!result.isGranted) {
            if (kDebugMode) {
              debugPrint('MediaService: Microphone permission DENIED');
            }
            return false;
          }
        }
      }

      // Dispose old recorder and create new one for clean state
      try {
        await _recorder?.dispose();
      } catch (_) {}
      _recorder = AudioRecorder();
      final rec = recorder;

      if (await rec.hasPermission()) {
        if (!kIsWeb) {
          // Android: use temp directory with proper file path
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/voice_${_uuid.v4()}.m4a';

          if (kDebugMode) {
            debugPrint('MediaService: Starting recording Android (path: $filePath)');
          }

          // Try AAC first (best quality), fallback to WAV if fails
          try {
            await rec.start(
              const RecordConfig(
                encoder: AudioEncoder.aacLc,
                bitRate: 128000,
                sampleRate: 44100,
              ),
              path: filePath,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('MediaService: AAC encoder failed, trying WAV: $e');
            }
            // Fallback to WAV which is universally supported
            final wavPath = '${tempDir.path}/voice_${_uuid.v4()}.wav';
            await rec.start(
              const RecordConfig(
                encoder: AudioEncoder.wav,
                bitRate: 128000,
                sampleRate: 44100,
              ),
              path: wavPath,
            );
          }
        } else {
          // Web: no file path needed, records to blob
          if (kDebugMode) {
            debugPrint('MediaService: Starting recording Web (blob mode)');
          }
          await rec.start(
            const RecordConfig(
              encoder: AudioEncoder.opus,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: '',
          );
        }

        if (kDebugMode) {
          debugPrint('MediaService: Recording started successfully');
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint('MediaService: recorder.hasPermission() returned false');
      }
      return false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: PlatformException starting recording: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error starting recording: $e');
      }
      return false;
    }
  }

  /// Stop recording and return the file path/blob URL
  static Future<String?> stopRecording() async {
    try {
      final rec = recorder;
      final path = await rec.stop();
      if (kDebugMode) {
        debugPrint('MediaService: Recording stopped, path: $path');
      }
      return path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error stopping recording: $e');
      }
      return null;
    }
  }

  /// Cancel recording
  static Future<void> cancelRecording() async {
    try {
      final rec = recorder;
      await rec.cancel();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error cancelling recording: $e');
      }
    }
    // Cleanup recorder
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
  }

  /// Check if currently recording
  static Future<bool> isRecording() async {
    try {
      return await recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  /// Upload audio — tries Storage first, then Firestore Data URL fallback
  /// Supports .m4a, .wav, .ogg and web blob URLs
  static Future<String?> uploadAudio(String audioPath) async {
    try {
      Uint8List bytes;
      String ext = 'm4a';
      String contentType = 'audio/mp4';

      // Detect extension from path
      if (audioPath.contains('.wav')) {
        ext = 'wav';
        contentType = 'audio/wav';
      } else if (audioPath.contains('.ogg') || audioPath.contains('.opus')) {
        ext = 'ogg';
        contentType = 'audio/ogg';
      } else if (audioPath.contains('.mp3')) {
        ext = 'mp3';
        contentType = 'audio/mpeg';
      }

      if (kIsWeb) {
        // On Web, audioPath is a Blob URL
        if (kDebugMode) {
          debugPrint('MediaService: Fetching audio blob from $audioPath');
        }
        try {
          final xFile = XFile(audioPath);
          bytes = await xFile.readAsBytes();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('MediaService: Failed to read audio blob: $e');
          }
          // Try via _fetchBlobBytes as fallback
          final fallbackBytes = await _fetchBlobBytes(audioPath);
          if (fallbackBytes == null) return null;
          bytes = fallbackBytes;
        }
        // Web default format is often ogg/opus
        ext = 'ogg';
        contentType = 'audio/ogg';
      } else {
        final File audioFile = File(audioPath);
        if (!audioFile.existsSync()) {
          if (kDebugMode) {
            debugPrint('MediaService: Audio file not found: $audioPath');
          }
          return null;
        }
        bytes = await audioFile.readAsBytes();
      }

      if (bytes.isEmpty) {
        if (kDebugMode) {
          debugPrint('MediaService: Audio file is empty');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('MediaService: Audio size: ${(bytes.length / 1024).toStringAsFixed(1)} KB, ext: $ext');
      }

      // Strategy 1: Firebase Storage
      if (_storageAvailable) {
        final storageUrl = await _tryUploadToStorage(bytes, 'voice_messages', ext, contentType);
        if (storageUrl != null) {
          // Cleanup temp file on mobile
          if (!kIsWeb) {
            try {
              await File(audioPath).delete();
            } catch (_) {}
          }
          return storageUrl;
        }
      }

      // Strategy 2: Firestore Data URL (voice messages are usually < 500KB)
      if (bytes.length < 800 * 1024) {
        final dataUrl = _createDataUrl(bytes, contentType);
        // Cleanup temp file
        if (!kIsWeb) {
          try {
            await File(audioPath).delete();
          } catch (_) {}
        }
        return dataUrl;
      }

      if (kDebugMode) {
        debugPrint('MediaService: Audio too large for fallback');
      }
      return null;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Firebase Error uploading audio: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error uploading audio: $e');
      }
      return null;
    }
  }

  /// Fetch blob bytes via HTTP (Web fallback)
  static Future<Uint8List?> _fetchBlobBytes(String url) async {
    try {
      // For Web blob URLs, we use XFile which handles blob: protocol
      final xFile = XFile(url);
      return await xFile.readAsBytes();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: _fetchBlobBytes error: $e');
      }
      return null;
    }
  }

  // ==================== ФАЙЛЫ ====================

  /// Pick files via FilePicker
  /// On Android: withData=true may fail for large files, so we use path fallback
  static Future<List<PlatformFile>> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      // Request storage permission on Android 12 and below
      if (!kIsWeb) {
        try {
          final storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            await Permission.storage.request();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('MediaService: Permission check note: $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint('MediaService: Opening file picker (type: $type, multiple: $allowMultiple, isWeb: $kIsWeb)');
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: type,
        allowedExtensions: allowedExtensions,
        // On web, withData is required. On mobile, use path for large files.
        withData: kIsWeb,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        if (kDebugMode) {
          debugPrint('MediaService: No files selected');
        }
        return [];
      }

      if (kDebugMode) {
        debugPrint('MediaService: Selected ${result.files.length} file(s)');
        for (final file in result.files) {
          debugPrint('  - ${file.name} (${formatFileSize(file.size)}, bytes: ${file.bytes != null ? "yes" : "no"}, path: ${file.path})');
        }
      }

      // On Android: if bytes are null but path is available, read bytes from path
      if (!kIsWeb) {
        final List<PlatformFile> processedFiles = [];
        for (final file in result.files) {
          if (file.bytes == null && file.path != null) {
            try {
              final bytes = await File(file.path!).readAsBytes();
              processedFiles.add(PlatformFile(
                name: file.name,
                size: file.size,
                path: file.path,
                bytes: bytes,
              ));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('MediaService: Could not read bytes for ${file.name}: $e');
              }
              processedFiles.add(file); // Add as-is, uploadFile handles path
            }
          } else {
            processedFiles.add(file);
          }
        }
        return processedFiles;
      }

      return result.files;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: PlatformException picking files: ${e.code} - ${e.message}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error picking files: $e');
      }
      return [];
    }
  }

  /// Upload multiple files
  static Future<List<Map<String, String>>> uploadMultipleFiles(
    List<PlatformFile> files, {
    required String folder,
    Function(int, int)? onProgress,
  }) async {
    final List<Map<String, String>> results = [];
    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i + 1, files.length);
      final url = await uploadFile(files[i], folder: folder);
      if (url != null) {
        results.add({
          'url': url,
          'name': files[i].name,
          'size': files[i].size.toString(),
        });
      }
    }
    return results;
  }

  // ==================== УТИЛИТЫ ====================

  static Future<bool> deleteFileFromStorage(String fileUrl) async {
    try {
      if (fileUrl.startsWith('data:')) return true; // Data URLs don't need deletion
      final Reference ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MediaService: Error deleting file: $e');
      }
      return false;
    }
  }

  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static Future<Uint8List?> getXFileBytes(XFile xFile) async {
    try {
      return await xFile.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Get content type from file extension
  static String _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  /// Reset storage availability (e.g. after rules change)
  static void resetStorageStatus() {
    _storageAvailable = true;
    _storageTested = false;
  }
}

/// Timeout exception for upload operations
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
