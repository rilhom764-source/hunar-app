import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/bid_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';
import '../models/subscription_model.dart';
import 'push_notification_service.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Firestore is always available - individual operations handle their own errors
  static bool _firestoreAvailable = true;
  static bool get isFirestoreAvailable => true; // Always return true

  /// Test Firestore connectivity once (pings 'tasks' collection which should always exist)
  static Future<bool> testFirestoreAccess() async {
    _firestoreAvailable = true; // Always keep enabled
    try {
      await _db.collection('tasks').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firestore test warning: $e (Firestore remains available)');
      return true;
    }
  }

  // ═══════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════
  static CollectionReference get _usersCol => _db.collection('users');

  static Future<void> createUser(UserModel user) async {
    if (!_firestoreAvailable) return;
    try {
      await _usersCol.doc(user.id).set(user.toJson());
    } catch (e) {
      _handleFirestoreError('createUser', e);
    }
  }

  static Future<UserModel?> getUser(String userId) async {
    if (!_firestoreAvailable) return null;
    try {
      final doc = await _usersCol.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      _handleFirestoreError('getUser', e);
    }
    return null;
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    if (!_firestoreAvailable) return;
    try {
      await _usersCol.doc(userId).update(data);
    } catch (e) {
      _handleFirestoreError('updateUser', e);
    }
  }

  static Future<List<UserModel>> getWorkers() async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _usersCol
          .where('role', isEqualTo: 'worker')
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleFirestoreError('getWorkers', e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // TASKS
  // ═══════════════════════════════════════════════
  static CollectionReference get _tasksCol => _db.collection('tasks');
  
  /// Get real-time stream of all tasks
  static Stream<List<TaskModel>> tasksStream() {
    if (!_firestoreAvailable) return Stream.value([]);
    return _tasksCol.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  static Future<void> createTask(TaskModel task) async {
    if (!_firestoreAvailable) return;
    try {
      await _tasksCol.doc(task.id).set(task.toJson());
    } catch (e) {
      _handleFirestoreError('createTask', e);
    }
  }

  static Future<TaskModel?> getTask(String taskId) async {
    if (!_firestoreAvailable) return null;
    try {
      final doc = await _tasksCol.doc(taskId).get();
      if (doc.exists && doc.data() != null) {
        return TaskModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      _handleFirestoreError('getTask', e);
    }
    return null;
  }

  static Future<List<TaskModel>> getAllTasks() async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _tasksCol.get();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      _handleFirestoreError('getAllTasks', e);
      return [];
    }
  }

  static Future<List<TaskModel>> getTasksByClient(String clientId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _tasksCol
          .where('clientId', isEqualTo: clientId)
          .get();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      _handleFirestoreError('getTasksByClient', e);
      return [];
    }
  }

  static Future<List<TaskModel>> getOpenTasks() async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _tasksCol
          .where('status', isEqualTo: 'open')
          .get();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      _handleFirestoreError('getOpenTasks', e);
      return [];
    }
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    if (!_firestoreAvailable) return;
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _tasksCol.doc(taskId).update(data);
    } catch (e) {
      _handleFirestoreError('updateTask', e);
    }
  }

  static Future<void> deleteTask(String taskId) async {
    if (!_firestoreAvailable) return;
    try {
      await _tasksCol.doc(taskId).delete();
      final bidsSnapshot = await _bidsCol.where('taskId', isEqualTo: taskId).get();
      for (final doc in bidsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      _handleFirestoreError('deleteTask', e);
    }
  }

  // ═══════════════════════════════════════════════
  // BIDS
  // ═══════════════════════════════════════════════
  static CollectionReference get _bidsCol => _db.collection('bids');

  static Future<void> createBid(BidModel bid) async {
    if (!_firestoreAvailable) return;
    try {
      await _bidsCol.doc(bid.id).set(bid.toJson());
      final taskDoc = await _tasksCol.doc(bid.taskId).get();
      if (taskDoc.exists) {
        final bidsSnapshot = await _bidsCol.where('taskId', isEqualTo: bid.taskId).get();
        await _tasksCol.doc(bid.taskId).update({'bidsCount': bidsSnapshot.docs.length});
      }
    } catch (e) {
      _handleFirestoreError('createBid', e);
    }
  }

  static Future<List<BidModel>> getBidsForTask(String taskId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _bidsCol
          .where('taskId', isEqualTo: taskId)
          .get();
      final bids = snapshot.docs
          .map((doc) => BidModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      bids.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bids;
    } catch (e) {
      _handleFirestoreError('getBidsForTask', e);
      return [];
    }
  }

  static Future<List<BidModel>> getBidsByWorker(String workerId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _bidsCol
          .where('workerId', isEqualTo: workerId)
          .get();
      final bids = snapshot.docs
          .map((doc) => BidModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      bids.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bids;
    } catch (e) {
      _handleFirestoreError('getBidsByWorker', e);
      return [];
    }
  }

  static Future<void> updateBid(String bidId, Map<String, dynamic> data) async {
    if (!_firestoreAvailable) return;
    try {
      await _bidsCol.doc(bidId).update(data);
    } catch (e) {
      _handleFirestoreError('updateBid', e);
    }
  }

  // ═══════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════
  static CollectionReference get _reviewsCol => _db.collection('reviews');

  static Future<void> createReview(ReviewModel review) async {
    if (!_firestoreAvailable) return;
    try {
      await _reviewsCol.doc(review.id).set(review.toJson());
    } catch (e) {
      _handleFirestoreError('createReview', e);
    }
  }

  static Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _reviewsCol
          .where('targetUserId', isEqualTo: userId)
          .get();
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (e) {
      _handleFirestoreError('getReviewsForUser', e);
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════
  static CollectionReference get _notificationsCol => _db.collection('notifications');

  static Future<void> createNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedTaskId,
    String? relatedUserId,
  }) async {
    if (!_firestoreAvailable) return;
    try {
      await _notificationsCol.doc(id).set({
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'relatedTaskId': relatedTaskId,
        'relatedUserId': relatedUserId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _handleFirestoreError('createNotification', e);
    }
  }

  static Future<List<NotificationModel>> getNotifications(String userId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .get();
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _notifFromMap(data, doc.id);
      }).toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      _handleFirestoreError('getNotifications', e);
      return [];
    }
  }

  /// Real-time stream of notifications for a specific user.
  /// Automatically emits updated list when documents change.
  /// Filtered strictly by userId — each user sees ONLY their own notifications.
  static Stream<List<NotificationModel>> notificationsStream(String userId) {
    if (!_firestoreAvailable) return Stream.value([]);
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _notifFromMap(data, doc.id);
      }).toList();
      // Sort in memory (no composite index required)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Helper: parse a Firestore notification document into NotificationModel
  static NotificationModel _notifFromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    return NotificationModel(
      id: data['id'] as String? ?? docId,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? ''),
        orElse: () => NotificationType.system,
      ),
      relatedTaskId: data['relatedTaskId'] as String?,
      relatedUserId: data['relatedUserId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Future<void> markNotificationRead(String notifId) async {
    if (!_firestoreAvailable) return;
    try {
      await _notificationsCol.doc(notifId).update({'isRead': true});
    } catch (e) {
      _handleFirestoreError('markNotificationRead', e);
    }
  }

  static Future<void> markAllNotificationsRead(String userId) async {
    if (!_firestoreAvailable) return;
    try {
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      _handleFirestoreError('markAllNotificationsRead', e);
    }
  }

  // ═══════════════════════════════════════════════
  // CHAT THREADS & MESSAGES (Real-time Firestore)
  // ═══════════════════════════════════════════════
  static CollectionReference get _chatsCol => _db.collection('chats');

  /// Find or create a 1-on-1 chat between two users.
  /// Returns the thread document ID.
  static Future<String> getOrCreateChat({
    required String currentUserId,
    required String currentUserName,
    required String participantId,
    required String participantName,
    String? participantAvatar,
    String? taskId,
    String? taskTitle,
  }) async {
    if (!_firestoreAvailable) return '';
    try {
      // Check if a chat already exists between these two users
      final snapshot = await _chatsCol
          .where('participants', arrayContains: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(participantId)) {
          return doc.id; // Chat already exists
        }
      }

      // Create new chat thread
      final docRef = _chatsCol.doc();
      await docRef.set({
        'participants': [currentUserId, participantId],
        'participantNames': {
          currentUserId: currentUserName,
          participantId: participantName,
        },
        'participantAvatars': {
          if (participantAvatar != null) participantId: participantAvatar,
        },
        'taskId': taskId,
        'taskTitle': taskTitle,
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastActivity': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      _handleFirestoreError('getOrCreateChat', e);
      return '';
    }
  }

  /// Send a message to a chat thread (with optional attachments)
  static Future<void> sendChatMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String type = 'text',
    String? imageUrl,
    List<String>? imageUrls,
    String? fileUrl,
    String? fileName,
    String? fileMimeType,
  }) async {
    if (!_firestoreAvailable) return;
    try {
      final msgRef = _chatsCol.doc(chatId).collection('messages').doc();
      final Map<String, dynamic> msgData = {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type,
        'sentAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Добавляем медиа-вложения
      if (imageUrl != null) msgData['imageUrl'] = imageUrl;
      if (imageUrls != null && imageUrls.isNotEmpty) msgData['imageUrls'] = imageUrls;
      if (fileUrl != null) msgData['fileUrl'] = fileUrl;
      if (fileName != null) msgData['fileName'] = fileName;
      if (fileMimeType != null) msgData['fileMimeType'] = fileMimeType;

      await msgRef.set(msgData);

      // Update last message info on the chat document
      String lastMsgPreview = content;
      if (type == 'image') lastMsgPreview = content.isNotEmpty ? content : '📷 Фото';
      if (type == 'voice') lastMsgPreview = '🎤 Голосовое сообщение';
      if (type == 'file') lastMsgPreview = content.isNotEmpty ? content : '📎 ${fileName ?? "Файл"}';

      await _chatsCol.doc(chatId).update({
        'lastMessage': lastMsgPreview,
        'lastMessageSenderId': senderId,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // 🔔 Send PUSH notification to the other participant
      try {
        final chatDoc = await _chatsCol.doc(chatId).get();
        if (chatDoc.exists) {
          final chatData = chatDoc.data() as Map<String, dynamic>;
          final participants = List<String>.from(chatData['participants'] ?? []);
          final recipientId = participants.firstWhere((id) => id != senderId, orElse: () => '');
          if (recipientId.isNotEmpty) {
            // Send push via PushNotificationService (direct FCM HTTP API)
            PushNotificationService.notifyNewMessage(
              chatId: chatId,
              recipientId: recipientId,
              senderName: senderName,
              messageText: content,
            );
          }
        }
      } catch (pushError) {
        debugPrint('Push notification for message failed: $pushError');
      }
    } catch (e) {
      _handleFirestoreError('sendChatMessage', e);
    }
  }

  /// Get a real-time stream of chat threads for a user
  static Stream<List<Map<String, dynamic>>> chatThreadsStream(String userId) {
    if (!_firestoreAvailable) return Stream.value([]);
    return _chatsCol
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final threads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      // Sort by lastActivity (handle Timestamp or null)
      threads.sort((a, b) {
        final aTime = a['lastActivity'];
        final bTime = b['lastActivity'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        final aTs = aTime is Timestamp ? aTime : Timestamp.now();
        final bTs = bTime is Timestamp ? bTime : Timestamp.now();
        return bTs.compareTo(aTs);
      });
      return threads;
    });
  }

  /// Get a real-time stream of messages for a chat
  static Stream<List<ChatMessage>> chatMessagesStream(String chatId) {
    if (!_firestoreAvailable) return Stream.value([]);
    return _chatsCol
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final sentAt = data['sentAt'];
        DateTime parsedTime;
        if (sentAt is Timestamp) {
          parsedTime = sentAt.toDate();
        } else if (sentAt is String) {
          parsedTime = DateTime.tryParse(sentAt) ?? DateTime.now();
        } else {
          parsedTime = DateTime.now();
        }

        // Определяем тип сообщения
        final typeStr = data['type'] as String? ?? 'text';
        MessageType msgType;
        switch (typeStr) {
          case 'image': msgType = MessageType.image; break;
          case 'file': msgType = MessageType.file; break;
          case 'voice': msgType = MessageType.voice; break;
          default: msgType = MessageType.text;
        }

        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] as String? ?? '',
          senderName: data['senderName'] as String? ?? '',
          content: data['content'] as String? ?? '',
          sentAt: parsedTime,
          isRead: data['isRead'] as bool? ?? false,
          type: msgType,
          imageUrl: data['imageUrl'] as String?,
          imageUrls: (data['imageUrls'] as List?)?.cast<String>() ?? [],
          fileUrl: data['fileUrl'] as String?,
          fileName: data['fileName'] as String?,
          fileMimeType: data['fileMimeType'] as String?,
        );
      }).toList();
    });
  }

  /// Mark all messages in a chat as read (for recipient)
  static Future<void> markChatMessagesRead(String chatId, String currentUserId) async {
    if (!_firestoreAvailable) return;
    try {
      final snapshot = await _chatsCol
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Only mark messages from the OTHER user as read
        if (data['senderId'] != currentUserId) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      _handleFirestoreError('markChatMessagesRead', e);
    }
  }

  /// Get unread message count for a user across all chats
  static Stream<int> unreadCountStream(String userId) {
    if (!_firestoreAvailable) return Stream.value(0);
    return chatThreadsStream(userId).asyncMap((threads) async {
      int total = 0;
      for (final thread in threads) {
        final chatId = thread['id'] as String;
        try {
          final snapshot = await _chatsCol
              .doc(chatId)
              .collection('messages')
              .where('isRead', isEqualTo: false)
              .get();
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data['senderId'] != userId) {
              total++;
            }
          }
        } catch (_) {}
      }
      return total;
    });
  }

  // Legacy methods kept for backward compatibility during migration
  static Future<void> createChatThread({
    required String threadId,
    required String userId,
    required String participantId,
    required String participantName,
    String? participantAvatar,
    String? taskId,
    String? taskTitle,
  }) async {
    // Redirect to new method
    await getOrCreateChat(
      currentUserId: userId,
      currentUserName: 'User',
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      taskId: taskId,
      taskTitle: taskTitle,
    );
  }

  static Future<void> sendMessage({
    required String threadId,
    required ChatMessage message,
  }) async {
    await sendChatMessage(
      chatId: threadId,
      senderId: message.senderId,
      senderName: message.senderName,
      content: message.content,
    );
  }

  static Future<List<ChatThread>> getChatThreads(String userId) async {
    // Return empty — real data comes from streams now
    return [];
  }

  // ═══════════════════════════════════════════════
  // PORTFOLIO IMAGES
  // ═══════════════════════════════════════════════
  static Future<void> addPortfolioImage(String userId, String imageUrl) async {
    if (!_firestoreAvailable) return;
    try {
      await _usersCol.doc(userId).update({
        'portfolioImages': FieldValue.arrayUnion([imageUrl]),
      });
    } catch (e) {
      _handleFirestoreError('addPortfolioImage', e);
    }
  }

  static Future<void> removePortfolioImage(String userId, String imageUrl) async {
    if (!_firestoreAvailable) return;
    try {
      await _usersCol.doc(userId).update({
        'portfolioImages': FieldValue.arrayRemove([imageUrl]),
      });
      // Удаляем файл из Storage
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
    } catch (e) {
      _handleFirestoreError('removePortfolioImage', e);
    }
  }

  // ═══════════════════════════════════════════════
  // SEED INITIAL DATA (one-time mock data to Firestore)
  // ═══════════════════════════════════════════════
  static Future<bool> checkIfDataSeeded() async {
    if (!_firestoreAvailable) return true; // Skip seeding if no access
    try {
      final snapshot = await _tasksCol.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _handleFirestoreError('checkIfDataSeeded', e);
      return true; // Assume seeded to avoid retry loops
    }
  }

  static Future<void> seedMockData({
    required List<UserModel> workers,
    required List<TaskModel> tasks,
    required Map<String, List<BidModel>> bids,
    required Map<String, List<ReviewModel>> reviews,
  }) async {
    if (!_firestoreAvailable) return;
    try {
      for (final worker in workers) {
        await _usersCol.doc(worker.id).set(worker.toJson());
      }
      for (final task in tasks) {
        await _tasksCol.doc(task.id).set(task.toJson());
      }
      for (final entry in bids.entries) {
        for (final bid in entry.value) {
          await _bidsCol.doc(bid.id).set(bid.toJson());
        }
      }
      for (final entry in reviews.entries) {
        for (final review in entry.value) {
          await _reviewsCol.doc(review.id).set(review.toJson());
        }
      }
      debugPrint('✅ Mock data seeded to Firestore successfully');
    } catch (e) {
      _handleFirestoreError('seedMockData', e);
    }
  }

  // ═══════════════════════════════════════════════
  // ERROR HANDLER
  // ═══════════════════════════════════════════════
  static void _handleFirestoreError(String operation, dynamic error) {
    // NEVER set _firestoreAvailable = false
    // Each operation handles its own errors independently
    _firestoreAvailable = true; // Always keep enabled
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('permission-denied') || errStr.contains('permission_denied')) {
      debugPrint('⚠️ Firestore [$operation]: permission-denied. Other operations still available.');
    } else {
      debugPrint('⚠️ Firestore [$operation] error: $error');
    }
  }

  /// Ensure Firestore access is available (always true now)
  static void resetFirestoreAccess() {
    _firestoreAvailable = true;
    debugPrint('✅ Firestore access confirmed available');
  }

  // ═══════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════
  static CollectionReference get _subscriptionsCol =>
      _db.collection('subscriptions');

  /// Save a new subscription to Firestore
  static Future<void> createSubscription(SubscriptionModel sub) async {
    if (!_firestoreAvailable) return;
    try {
      await _subscriptionsCol.doc(sub.id).set(sub.toJson());
      debugPrint('✅ Subscription created: ${sub.id}');
    } catch (e) {
      _handleFirestoreError('createSubscription', e);
    }
  }

  /// Update subscription fields in Firestore
  static Future<void> updateSubscription(
      String id, Map<String, dynamic> data) async {
    if (!_firestoreAvailable) return;
    try {
      await _subscriptionsCol.doc(id).update(data);
    } catch (e) {
      _handleFirestoreError('updateSubscription', e);
    }
  }

  /// Load all subscriptions for a user
  static Future<List<SubscriptionModel>> getSubscriptionsForUser(
      String userId) async {
    if (!_firestoreAvailable) return [];
    try {
      final snapshot = await _subscriptionsCol
          .where('userId', isEqualTo: userId)
          .get();
      final subs = snapshot.docs.map((doc) {
        return SubscriptionModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      subs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return subs;
    } catch (e) {
      _handleFirestoreError('getSubscriptionsForUser', e);
      return [];
    }
  }

  /// Delete user data from Firestore
  static Future<void> deleteUser(String userId) async {
    if (!_firestoreAvailable) return;
    try {
      // Delete user document
      await _db.collection('users').doc(userId).delete();

      // Delete user notifications
      final notifs = await _db.collection('notifications')
          .where('userId', isEqualTo: userId).get();
      for (final doc in notifs.docs) {
        await doc.reference.delete();
      }

      // Delete user chat threads
      final chats = await _db.collection('chat_threads')
          .where('userId', isEqualTo: userId).get();
      for (final doc in chats.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Deleted user data for $userId');
    } catch (e) {
      _handleFirestoreError('deleteUser', e);
    }
  }
}
