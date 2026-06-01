import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/message_model.dart';
import '../providers/app_state_provider.dart';
import '../services/firebase_service.dart';
import '../services/media_service.dart';
import '../widgets/voice_message_player.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final fbUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                l10n.tr('nav_messages'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            Expanded(
              child: fbUser == null
                  ? _buildNotLoggedIn(l10n)
                  : _ChatListBody(userId: fbUser.uid, l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(LocalizationProvider l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.login_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(l10n.tr('messages_login_required'), style: const TextStyle(fontSize: 16, color: AppColors.slateGray)),
        ],
      ),
    );
  }
}

/// Real-time chat list from Firestore
class _ChatListBody extends StatelessWidget {
  final String userId;
  final LocalizationProvider l10n;

  const _ChatListBody({required this.userId, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.chatThreadsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(l10n.tr('messages_error'), style: const TextStyle(color: AppColors.slateGray)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    FirebaseService.resetFirestoreAccess();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Повторить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final threads = snapshot.data ?? [];

        if (threads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 16),
                Text(l10n.tr('messages_empty'), style: const TextStyle(fontSize: 16, color: AppColors.slateGray)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(l10n.tr('messages_empty_desc'), style: const TextStyle(fontSize: 13, color: AppColors.lightSlate), textAlign: TextAlign.center),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (ctx, i) {
            final thread = threads[i];
            return _FirestoreChatTile(
              thread: thread,
              currentUserId: userId,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FirestoreChatDetailScreen(
                    chatId: thread['id'] as String,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Individual chat tile
class _FirestoreChatTile extends StatelessWidget {
  final Map<String, dynamic> thread;
  final String currentUserId;
  final VoidCallback onTap;

  const _FirestoreChatTile({required this.thread, required this.currentUserId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final participants = List<String>.from(thread['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final participantNames = Map<String, dynamic>.from(thread['participantNames'] ?? {});
    final otherName = participantNames[otherUserId] as String? ?? 'User';
    final taskTitle = thread['taskTitle'] as String?;
    final lastMessage = thread['lastMessage'] as String? ?? '';
    final lastSenderId = thread['lastMessageSenderId'] as String? ?? '';

    final initials = otherName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

    String timeStr = '';
    final lastActivity = thread['lastActivity'];
    if (lastActivity != null && lastActivity is Timestamp) {
      final dt = lastActivity.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours}h';
      } else {
        timeStr = '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(thread['id'] as String)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, unreadSnapshot) {
        int unreadCount = 0;
        if (unreadSnapshot.hasData) {
          for (final doc in unreadSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['senderId'] != currentUserId) {
              unreadCount++;
            }
          }
        }

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(initials, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500, fontSize: 15, color: AppColors.deepSlate),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Text(timeStr, style: TextStyle(fontSize: 12, color: unreadCount > 0 ? AppColors.primary : AppColors.lightSlate)),
                        ],
                      ),
                      if (taskTitle != null && taskTitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(taskTitle, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage.isNotEmpty
                                  ? (lastSenderId == currentUserId ? 'Вы: $lastMessage' : lastMessage)
                                  : 'Начните общение...',
                              style: TextStyle(fontSize: 13, color: unreadCount > 0 ? AppColors.deepSlate : AppColors.slateGray),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chat detail screen with real-time messages + photo/voice/file sending
class FirestoreChatDetailScreen extends StatefulWidget {
  final String chatId;
  const FirestoreChatDetailScreen({super.key, required this.chatId});

  @override
  State<FirestoreChatDetailScreen> createState() => _FirestoreChatDetailScreenState();
}

class _FirestoreChatDetailScreenState extends State<FirestoreChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isInitialized = false;
  bool _isSendingMedia = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    FirebaseService.resetFirestoreAccess();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseService.markChatMessagesRead(widget.chatId, uid);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recordingTimer?.cancel();
    if (_isRecording) {
      MediaService.cancelRecording();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = FirebaseAuth.instance.currentUser;
    final currentUserId = fbUser?.uid ?? '';
    final l10n = context.watch<LocalizationProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(l10n.tr('messages_chat'), style: const TextStyle(color: Colors.white));
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
            final otherName = participantNames[otherUserId] as String? ?? 'User';
            final taskTitle = data['taskTitle'] as String?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName, style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w600, color: Colors.white)),
                if (taskTitle != null && taskTitle.isNotEmpty)
                  Text(taskTitle, style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w400)),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Media upload indicator
          if (_isSendingMedia)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _uploadStatus.isNotEmpty ? _uploadStatus : 'Загрузка...',
                      style: const TextStyle(fontSize: 13, color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: FirebaseService.chatMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        const Text('Ошибка загрузки сообщений', style: TextStyle(color: AppColors.slateGray)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}', style: const TextStyle(color: AppColors.lightSlate, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseService.resetFirestoreAccess();
                            setState(() => _isInitialized = false);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                _isInitialized = true;
                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.primary.withValues(alpha: 0.3), size: 64),
                        const SizedBox(height: 16),
                        Text(l10n.tr('messages_start_chat'), style: const TextStyle(color: AppColors.slateGray, fontSize: 15)),
                        const SizedBox(height: 8),
                        Text(l10n.tr('messages_start_chat_desc'), style: const TextStyle(color: AppColors.lightSlate, fontSize: 13), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  FirebaseService.markChatMessagesRead(widget.chatId, uid);
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          // Recording indicator
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Запись... ${_formatDuration(_recordingDuration)}',
                    style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancelRecording,
                    child: const Text('Отмена', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          // Input area
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      padding: EdgeInsets.fromLTRB(isSmall ? 4 : 8, 8, isSmall ? 4 : 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attach button (photo/file)
            IconButton(
              onPressed: _isSendingMedia || _isRecording ? null : () => _showAttachmentOptions(context),
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.slateGray),
              tooltip: 'Прикрепить',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // Voice button
            IconButton(
              onPressed: _isSendingMedia ? null : (_isRecording ? _stopRecordingAndSend : _startVoiceRecording),
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic_outlined,
                color: _isRecording ? Colors.red : AppColors.slateGray,
              ),
              tooltip: _isRecording ? 'Отправить' : 'Голосовое',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendTextMessage(),
                decoration: InputDecoration(
                  hintText: 'Написать сообщение...',
                  hintStyle: TextStyle(fontSize: isSmall ? 13 : 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: 10),
                  isDense: true,
                ),
                style: TextStyle(fontSize: isSmall ? 14 : 15),
              ),
            ),
            const SizedBox(width: 6),
            // Send button
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                onPressed: _sendTextMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show attachment options
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Прикрепить',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepSlate),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: const Text('Фото из галереи'),
              subtitle: const Text('Выбрать одно или несколько фото'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotosFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.info),
              ),
              title: const Text('Сделать фото'),
              subtitle: const Text('Открыть камеру'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_file, color: AppColors.success),
              ),
              title: const Text('Файл'),
              subtitle: const Text('Документы, архивы, таблицы'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFiles();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Pick photos from gallery
  Future<void> _pickPhotosFromGallery() async {
    try {
      setState(() => _uploadStatus = 'Выбор фото...');
      final images = await MediaService.pickMultipleImages(maxCount: 5);
      if (images.isEmpty) return;
      await _sendImageMessages(images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора фото: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      setState(() => _uploadStatus = 'Открытие камеры...');
      final image = await MediaService.pickImageFromCameraXFile();
      if (image == null) return;
      await _sendImageMessages([image]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка камеры: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Pick files
  Future<void> _pickFiles() async {
    try {
      setState(() => _uploadStatus = 'Выбор файлов...');
      
      final files = await MediaService.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (files.isEmpty) {
        if (kDebugMode) {
          debugPrint('Chat: No files selected from picker');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('Chat: Picked ${files.length} files');
        for (final f in files) {
          debugPrint('  File: ${f.name}, size: ${f.size}, bytes: ${f.bytes != null}, path: ${f.path}');
        }
      }

      const maxSize = 10 * 1024 * 1024; // 10 MB
      final validFiles = files.where((f) => f.size <= maxSize).toList();

      if (validFiles.length < files.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Некоторые файлы больше 10 МБ и не будут отправлены'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }

      if (validFiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Все выбранные файлы слишком большие (макс 10 МБ)'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      await _sendFileMessages(validFiles);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Chat: File picker error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файлов: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Send file messages
  Future<void> _sendFileMessages(List<PlatformFile> files) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: вы не авторизованы'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final state = context.read<AppStateProvider>();
    setState(() {
      _isSendingMedia = true;
      _uploadStatus = 'Загрузка файлов...';
    });

    int uploaded = 0;
    int failed = 0;

    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          if (mounted) {
            setState(() => _uploadStatus = 'Загрузка ${i + 1}/${files.length}: ${file.name}');
          }

          final url = await MediaService.uploadFile(file, folder: 'chat_files');

          if (url != null) {
            String mimeType = 'application/octet-stream';
            final ext = file.extension?.toLowerCase() ?? '';

            if (ext == 'pdf') {
              mimeType = 'application/pdf';
            } else if (ext == 'doc') {
              mimeType = 'application/msword';
            } else if (ext == 'docx') {
              mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            } else if (ext == 'xls') {
              mimeType = 'application/vnd.ms-excel';
            } else if (ext == 'xlsx') {
              mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            } else if (ext == 'txt') {
              mimeType = 'text/plain';
            } else if (ext == 'zip') {
              mimeType = 'application/zip';
            } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
              mimeType = 'image/$ext';
            }

            await FirebaseService.sendChatMessage(
              chatId: widget.chatId,
              senderId: fbUser.uid,
              senderName: state.currentUser.fullName,
              content: '',
              type: 'file',
              fileUrl: url,
              fileName: file.name,
              fileMimeType: mimeType,
            );
            uploaded++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
          if (kDebugMode) {
            debugPrint('Chat: Error uploading/sending file: $e');
          }
        }
      }

      if (mounted) {
        if (failed > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploaded > 0
                  ? 'Отправлено $uploaded файлов, ошибок: $failed'
                  : 'Не удалось отправить файлы. Файл может быть слишком большим.'),
              backgroundColor: uploaded > 0 ? AppColors.warning : AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (uploaded > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Отправлено $uploaded ${_pluralFiles(uploaded)}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
          _uploadStatus = '';
        });
      }
    }
  }

  /// Send image messages
  Future<void> _sendImageMessages(List<XFile> images) async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: вы не авторизованы'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final state = context.read<AppStateProvider>();
    setState(() {
      _isSendingMedia = true;
      _uploadStatus = 'Загрузка фото...';
    });

    int uploaded = 0;
    int failed = 0;

    try {
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        try {
          if (mounted) {
            setState(() => _uploadStatus = 'Загрузка фото ${i + 1}/${images.length}...');
          }

          final url = await MediaService.uploadXFile(img, folder: 'chat_images');
          if (url != null) {
            await FirebaseService.sendChatMessage(
              chatId: widget.chatId,
              senderId: fbUser.uid,
              senderName: state.currentUser.fullName,
              content: '',
              type: 'image',
              imageUrl: url,
            );
            uploaded++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
          if (kDebugMode) {
            debugPrint('Chat: Error uploading/sending image: $e');
          }
        }
      }

      if (mounted) {
        if (failed > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploaded > 0
                  ? 'Отправлено $uploaded фото, ошибок: $failed'
                  : 'Не удалось отправить фото. Попробуйте снова.'),
              backgroundColor: uploaded > 0 ? AppColors.warning : AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (uploaded > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Отправлено $uploaded ${_pluralPhotos(uploaded)}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
          _uploadStatus = '';
        });
      }
    }
  }

  /// Send text message
  Future<void> _sendTextMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: вы не авторизованы'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final state = context.read<AppStateProvider>();
    _msgCtrl.clear();

    try {
      await FirebaseService.sendChatMessage(
        chatId: widget.chatId,
        senderId: fbUser.uid,
        senderName: state.currentUser.fullName,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        _msgCtrl.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ==================== VOICE RECORDING ====================

  /// Start voice recording
  Future<void> _startVoiceRecording() async {
    try {
      final started = await MediaService.startRecording();
      if (started) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted && _isRecording) {
            setState(() => _recordingDuration += const Duration(seconds: 1));
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось начать запись. Проверьте разрешения микрофона.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка записи: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Stop recording and send voice message
  Future<void> _stopRecordingAndSend() async {
    _recordingTimer?.cancel();

    try {
      if (kDebugMode) {
        debugPrint('Chat: Stopping recording (duration: ${_recordingDuration.inSeconds}s)');
      }

      final path = await MediaService.stopRecording();
      setState(() => _isRecording = false);

      if (path == null || path.isEmpty) {
        if (kDebugMode) {
          debugPrint('Chat: Recording path is null/empty');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запись не сохранена'), backgroundColor: AppColors.warning),
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('Chat: Recording stopped, path: $path');
      }

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return;
      if (!mounted) return;
      final state = context.read<AppStateProvider>();

      setState(() {
        _isSendingMedia = true;
        _uploadStatus = 'Загрузка голосового...';
      });

      final voiceUrl = await MediaService.uploadAudio(path);
      if (voiceUrl != null) {
        // Determine correct MIME type based on file extension
        String fileName = 'voice_message.m4a';
        String mimeType = 'audio/mp4';
        if (path.endsWith('.wav')) {
          fileName = 'voice_message.wav';
          mimeType = 'audio/wav';
        } else if (path.endsWith('.ogg') || path.endsWith('.opus')) {
          fileName = 'voice_message.ogg';
          mimeType = 'audio/ogg';
        }

        await FirebaseService.sendChatMessage(
          chatId: widget.chatId,
          senderId: fbUser.uid,
          senderName: state.currentUser.fullName,
          content: '',
          type: 'voice',
          fileUrl: voiceUrl,
          fileName: fileName,
          fileMimeType: mimeType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Голосовое отправлено'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось загрузить голосовое. Попробуйте снова.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Chat: Voice recording send error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
          _isRecording = false;
          _uploadStatus = '';
        });
      }
    }
  }

  /// Cancel recording
  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await MediaService.cancelRecording();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _pluralPhotos(int count) {
    if (count == 1) return 'фото';
    return 'фото';
  }

  String _pluralFiles(int count) {
    if (count == 1) return 'файл';
    if (count >= 2 && count <= 4) return 'файла';
    return 'файлов';
  }
}

// ==================== Helper: Smart image widget ====================

/// Widget that handles both network URLs and Data URLs (base64)
class _SmartImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  const _SmartImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a Data URL (base64 encoded)
    if (imageUrl.startsWith('data:')) {
      return _buildDataUrlImage(context);
    }

    // Regular network URL - use CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null
          ? (ctx, url) => placeholder!(ctx, url)
          : (ctx, url) => Container(
              width: width,
              height: height,
              color: AppColors.divider,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorWidget: errorWidget != null
          ? (ctx, url, err) => errorWidget!(ctx, url, err)
          : (ctx, url, err) => Container(
              width: width,
              height: height,
              color: AppColors.divider,
              child: const Icon(Icons.broken_image, color: AppColors.slateGray, size: 32),
            ),
    );
  }

  Widget _buildDataUrlImage(BuildContext context) {
    try {
      // Parse data URL: "data:image/jpeg;base64,/9j/4AAQ..."
      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex == -1) {
        return _buildErrorWidget(context);
      }
      final base64Data = imageUrl.substring(commaIndex + 1);
      final bytes = base64Decode(base64Data);

      return Image.memory(
        Uint8List.fromList(bytes),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildErrorWidget(ctx),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('_SmartImage: Error decoding data URL: $e');
      }
      return _buildErrorWidget(context);
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.divider,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: AppColors.slateGray, size: 32),
          SizedBox(height: 4),
          Text('Ошибка', style: TextStyle(fontSize: 11, color: AppColors.lightSlate)),
        ],
      ),
    );
  }
}

/// Message bubble (supports text, photo, voice, file)
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Image attachment
            if (message.type == MessageType.image && message.imageUrl != null)
              _buildImageBubble(context, message.imageUrl!),

            // Multiple images
            if (message.imageUrls.isNotEmpty)
              ..._buildMultipleImages(context, message.imageUrls),

            // Voice message
            if (message.type == MessageType.voice && message.fileUrl != null)
              _buildVoiceBubble(context),

            // File attachment (but not voice)
            if (message.type == MessageType.file && message.fileUrl != null)
              _buildFileBubble(context),

            // Text message
            if (message.content.isNotEmpty)
              _buildTextBubble(context),

            // Timestamp + ticks for attachments without text
            if (message.content.isEmpty && message.hasAttachment)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10, color: AppColors.lightSlate),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      _TelegramTicks(isRead: message.isRead),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Voice bubble
  Widget _buildVoiceBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        minWidth: 200,
      ),
      child: VoiceMessagePlayer(voiceUrl: message.fileUrl!),
    );
  }

  /// Image bubble — handles both network URLs and Data URLs
  Widget _buildImageBubble(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _SmartImage(
            imageUrl: imageUrl,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) {
              return Container(
                width: 220, height: 160,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: AppColors.slateGray, size: 32),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Не удалось загрузить фото',
                        style: TextStyle(fontSize: 11, color: AppColors.lightSlate),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Multiple images
  List<Widget> _buildMultipleImages(BuildContext context, List<String> urls) {
    return urls.map((url) => _buildImageBubble(context, url)).toList();
  }

  /// File bubble
  Widget _buildFileBubble(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(context, message.fileUrl!, message.fileName ?? 'Файл'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.9) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isMe ? Colors.white : AppColors.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(message.fileName ?? ''),
                color: isMe ? Colors.white : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Файл',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : AppColors.deepSlate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFileTypeDescription(message.fileName ?? ''),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.lightSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.download,
                        size: 14,
                        color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.lightSlate,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Нажмите для открытия',
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.lightSlate,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;

    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['txt'].contains(ext)) return Icons.text_snippet;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext)) return Icons.image;
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) return Icons.audio_file;
    if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) return Icons.video_file;

    return Icons.insert_drive_file;
  }

  String _getFileTypeDescription(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;

    if (ext == 'pdf') return 'PDF документ';
    if (['doc', 'docx'].contains(ext)) return 'Word документ';
    if (['xls', 'xlsx'].contains(ext)) return 'Excel таблица';
    if (['ppt', 'pptx'].contains(ext)) return 'PowerPoint презентация';
    if (ext == 'txt') return 'Текстовый файл';
    if (['zip', 'rar', '7z'].contains(ext)) return 'Архив';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'Изображение';
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) return 'Аудио файл';
    if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) return 'Видео файл';

    return 'Документ';
  }

  void _openFile(BuildContext context, String fileUrl, String fileName) {
    if (kDebugMode) {
      debugPrint('Opening file: $fileName');
    }

    // Data URL - offer to download
    if (fileUrl.startsWith('data:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл: $fileName'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Network URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Файл: $fileName'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Text bubble
  Widget _buildTextBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.deepSlate, height: 1.4),
          ),
          const SizedBox(height: 3),
          // Время + галочки прочтения (только для исходящих)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.lightSlate,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 3),
                _TelegramTicks(isRead: message.isRead),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Show full screen image — handles Data URLs and network URLs
  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }
}

/// Telegram-style read ticks: ✓ sent, ✓✓ delivered, ✓✓ (blue) read
class _TelegramTicks extends StatelessWidget {
  final bool isRead;
  const _TelegramTicks({required this.isRead});

  @override
  Widget build(BuildContext context) {
    // Double tick (✓✓): blue = read, white-70 = sent/delivered
    final color = isRead
        ? const Color(0xFF64DFDF) // cyan-blue (telegram read color)
        : Colors.white.withValues(alpha: 0.65);
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Second tick (slightly offset left)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(Icons.done, size: 12, color: color),
        ),
        // First tick (on top, offset right)
        Icon(Icons.done, size: 12, color: color),
      ],
    );
  }
}

/// Full screen image viewer — supports Data URLs
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Фото', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('data:')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex == -1) return _buildError();
        final base64Data = imageUrl.substring(commaIndex + 1);
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _buildError(),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, color: Colors.white, size: 64),
        const SizedBox(height: 12),
        Text(
          'Не удалось загрузить фото',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
      ],
    );
  }
}
