import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are automatically displayed as notifications on Android.
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Local notifications plugin for showing foreground notifications
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hunar_notifications',
    'Hunar Notifications',
    description: 'Push notifications for Hunar app',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // Firestore listener for real-time notifications
  static StreamSubscription<QuerySnapshot>? _notificationListener;

  // ─── ИСПРАВЛЕНИЕ BUG #2 ───────────────────────────────────────────────────
  // processedNotifIds теперь привязан к текущему userId.
  // При смене пользователя Set очищается, чтобы не блокировать новые уведомления.
  static final Map<String, Set<String>> _processedNotifIds = {};
  static String? _currentListenerUserId;
  // ─────────────────────────────────────────────────────────────────────────

  // Incrementing notification ID (локальный счётчик для flutter_local_notifications)
  static int _notificationId = 0;

  // Временная метка старта слушателя — используется вместо проверки "30 минут"
  // Показываем ТОЛЬКО уведомления, созданные ПОСЛЕ того, как слушатель запустился.
  static DateTime? _listenerStartedAt;

  /// Initialize FCM + local notifications
  static Future<void> init() async {
    try {
      // 1. Create Android notification channel
      await _createNotificationChannel();

      // 2. Initialize local notifications plugin
      await _initLocalNotifications();

      // 3. Request notification permissions (Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('FCM: User denied notification permissions');
        }
        return;
      }

      // 4. Set foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Get FCM token and save
      await _saveToken();

      // 6. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });

      // 7. Handle foreground FCM messages — show local notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 8. Handle notification tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 9. Check if app was opened from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 10. Subscribe to broadcast topic
      await _messaging.subscribeToTopic('all_users');

      if (kDebugMode) {
        debugPrint('FCM: Push notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM init error: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════
  // FIRESTORE REAL-TIME NOTIFICATION LISTENER
  //
  // ИСПРАВЛЕНИЯ:
  // 1. _listenerStartedAt — показываем ТОЛЬКО уведомления после старта слушателя
  // 2. _processedNotifIds привязан к userId — при logout/login очищается
  // 3. Фильтрация по userId строго: каждый видит ТОЛЬКО СВОИ уведомления
  // ═══════════════════════════════════════════════

  /// Start listening for new notifications for the current user.
  /// Uses a SIMPLE Firestore query — no composite index required.
  static void startNotificationListener(String userId) {
    // Don't restart if already listening for the same user
    if (_currentListenerUserId == userId && _notificationListener != null) {
      if (kDebugMode) {
        debugPrint('PUSH: Already listening for user $userId');
      }
      return;
    }

    // Cancel existing listener and clear state for previous user
    stopNotificationListener();

    _currentListenerUserId = userId;

    // ─── ИСПРАВЛЕНИЕ BUG #1 + BUG #2 ────────────────────────────────────────
    // Запоминаем ТОЧНОЕ время старта слушателя.
    // Все уведомления с createdAt < _listenerStartedAt будут пропущены —
    // это исключает повторный показ старых уведомлений при каждом логине.
    //
    // _processedNotifIds очищается для нового userId, чтобы не блокировать
    // уведомления нового пользователя ID'ами предыдущего.
    _listenerStartedAt = DateTime.now();
    _processedNotifIds[userId] = {};
    // ─────────────────────────────────────────────────────────────────────────

    if (kDebugMode) {
      debugPrint('PUSH: Starting Firestore listener for userId=$userId');
      debugPrint('PUSH: listenerStartedAt=$_listenerStartedAt');
      debugPrint('PUSH: Only NEW notifications (after startedAt) will be shown');
    }

    // SIMPLE query — только по userId, без orderBy (не требует composite index)
    _notificationListener = _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (kDebugMode) {
          debugPrint(
            'PUSH: Snapshot received — ${snapshot.docChanges.length} changes for userId=$userId',
          );
        }

        for (final change in snapshot.docChanges) {
          // ─── ТОЛЬКО новые документы ───────────────────────────────────────
          if (change.type != DocumentChangeType.added) continue;

          final data = change.doc.data();
          if (data == null) continue;

          final docId = change.doc.id;

          // ─── ИСПРАВЛЕНИЕ BUG #2: de-duplication per user ──────────────────
          final userProcessed = _processedNotifIds[userId] ?? {};
          if (userProcessed.contains(docId)) {
            if (kDebugMode) {
              debugPrint('PUSH: Skipped duplicate notification: $docId');
            }
            continue;
          }
          _processedNotifIds[userId] = {...userProcessed, docId};
          // ──────────────────────────────────────────────────────────────────

          // ─── СТРОГАЯ ПРОВЕРКА userId ───────────────────────────────────────
          // Хотя Firestore-запрос уже фильтрует по userId,
          // делаем вторичную проверку для надёжности.
          final notifUserId = data['userId'] as String? ?? '';
          if (notifUserId != userId) {
            if (kDebugMode) {
              debugPrint(
                'PUSH: SECURITY — skipped notification for wrong user: '
                'expected=$userId, got=$notifUserId',
              );
            }
            continue;
          }
          // ──────────────────────────────────────────────────────────────────

          // Skip already-read notifications
          final isRead = data['isRead'] as bool? ?? false;
          if (isRead) {
            if (kDebugMode) {
              debugPrint('PUSH: Skipped already-read notification: $docId');
            }
            continue;
          }

          // ─── ИСПРАВЛЕНИЕ BUG #1: показываем ТОЛЬКО уведомления после старта ──
          // Вместо произвольного "30 минут" — чёткая временна́я граница.
          final createdAtStr = data['createdAt'] as String?;
          if (createdAtStr != null && _listenerStartedAt != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr);
              if (createdAt.isBefore(_listenerStartedAt!)) {
                if (kDebugMode) {
                  debugPrint(
                    'PUSH: Skipped OLD notification (created before listener start): $docId | '
                    'createdAt=$createdAt | listenerStart=$_listenerStartedAt',
                  );
                }
                continue; // Старое уведомление — не показываем
              }
            } catch (_) {
              // Если дата не парсится — показываем на всякий случай
            }
          }
          // ──────────────────────────────────────────────────────────────────

          // Извлекаем данные уведомления
          final title = data['title'] as String? ?? 'Hunar';
          final message = data['message'] as String? ?? '';
          final type = data['type'] as String? ?? '';

          // Показываем локальное уведомление на устройстве
          _showLocalNotification(
            title: title,
            body: message,
            payload: type,
          );

          if (kDebugMode) {
            debugPrint(
              'PUSH: ✅ Showed notification for userId=$userId | "$title" — "$message"',
            );
          }
        }
      },
      onError: (e) {
        if (kDebugMode) {
          debugPrint('PUSH: Notification listener error for userId=$userId: $e');
        }
      },
    );
  }

  /// Stop the Firestore notification listener
  static void stopNotificationListener() {
    _notificationListener?.cancel();
    _notificationListener = null;

    if (kDebugMode && _currentListenerUserId != null) {
      debugPrint('PUSH: Stopped listener for userId=$_currentListenerUserId');
    }

    // ─── ИСПРАВЛЕНИЕ BUG #2: очищаем ID для вышедшего пользователя ───────────
    // Удаляем из Map данные старого пользователя, чтобы при следующем
    // login ID'ы не блокировали новые уведомления.
    if (_currentListenerUserId != null) {
      _processedNotifIds.remove(_currentListenerUserId);
    }
    // ─────────────────────────────────────────────────────────────────────────

    _currentListenerUserId = null;
    _listenerStartedAt = null;
  }

  /// Show a local notification on the device
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      _notificationId++;
      await _localNotifications.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF2E7D32),
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH: Local notification show error: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════
  // NOTIFICATION CHANNEL & LOCAL INIT
  // ═══════════════════════════════════════════════

  /// Create Android Notification Channel
  static Future<void> _createNotificationChannel() async {
    try {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM: Channel creation error: $e');
      }
    }
  }

  /// Initialize flutter_local_notifications
  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('FCM: Local notification tapped: ${response.payload}');
        }
      },
    );
  }

  // ═══════════════════════════════════════════════
  // FCM TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════

  /// Get and save FCM token
  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('FCM Token: ${token.substring(0, 20)}...');
        }
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken error: $e');
      }
    }
  }

  /// Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      await _db.collection('fcm_tokens').doc(user.uid).set({
        'token': token,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });

      if (kDebugMode) {
        debugPrint('FCM: Token saved for userId=${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM saveToken error: $e');
      }
    }
  }

  /// Handle foreground FCM messages — show as local notification
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    if (kDebugMode) {
      debugPrint('FCM foreground: ${notification.title} - ${notification.body}');
    }

    _showLocalNotification(
      title: notification.title ?? 'Hunar',
      body: notification.body ?? '',
      payload: message.data['type'] ?? '',
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('FCM notification tap: ${message.data}');
    }
  }

  /// Update token + start listener when user logs in
  static Future<void> onUserLogin() async {
    await _saveToken();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _messaging.subscribeToTopic('user_${user.uid}');

      // START real-time notification listener for this specific user
      startNotificationListener(user.uid);

      if (kDebugMode) {
        debugPrint(
          'FCM: onUserLogin complete for userId=${user.uid}. '
          'Subscribed to topic + started Firestore listener.',
        );
      }
    }
  }

  /// Clean up when user logs out
  static Future<void> onUserLogout() async {
    try {
      // STOP real-time notification listener + clear processed IDs
      stopNotificationListener();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _db.collection('fcm_tokens').doc(user.uid).delete();
        await _messaging.unsubscribeFromTopic('user_${user.uid}');
      }
      await _messaging.unsubscribeFromTopic('all_users');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM logout cleanup error: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════
  // PUSH NOTIFICATION TRIGGERS
  // Write notification to Firestore → Firestore listener
  // on the target device picks it up → shows local notification
  //
  // ВАЖНО: каждое уведомление записывается СТРОГО с userId получателя.
  // Слушатель на устройстве получателя покажет ТОЛЬКО его уведомления.
  // ═══════════════════════════════════════════════

  /// Send push when a new task is created -> to all masters (workers)
  static Future<void> notifyNewTask({
    required String taskId,
    required String taskTitle,
    required String location,
    required double budget,
    required String clientId,
  }) async {
    try {
      const title = 'Новое задание!';
      final body = '$taskTitle — ${budget.toInt()} TJS, $location';

      // Query ALL workers from Firestore
      final workers = await _db
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();

      int notifiedCount = 0;
      for (final workerDoc in workers.docs) {
        final workerId = workerDoc.id;
        if (workerId == clientId) continue; // Не уведомляем самого себя

        await _writeNotification(
          userId: workerId, // ← строго userId мастера
          title: title,
          message: body,
          type: 'newTask',
          relatedId: taskId,
        );
        notifiedCount++;
      }

      if (kDebugMode) {
        debugPrint(
          'PUSH: notifyNewTask — notified $notifiedCount workers about "$taskTitle"',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH notifyNewTask error: $e');
      }
    }
  }

  /// Send push when a new bid is placed -> to the task owner (client)
  static Future<void> notifyNewBid({
    required String taskId,
    required String taskTitle,
    required String clientId,
    required String workerName,
    required double bidAmount,
  }) async {
    try {
      const title = 'Новый отклик!';
      final body =
          '$workerName откликнулся на "$taskTitle" — ${bidAmount.toInt()} TJS';

      await _writeNotification(
        userId: clientId, // ← строго userId клиента (владельца задания)
        title: title,
        message: body,
        type: 'new_bid',
        relatedId: taskId,
      );

      if (kDebugMode) {
        debugPrint('PUSH: notifyNewBid — notified clientId=$clientId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH notifyNewBid error: $e');
      }
    }
  }

  /// Send push when a bid is accepted -> to the worker
  static Future<void> notifyBidAccepted({
    required String taskId,
    required String taskTitle,
    required String workerId,
  }) async {
    try {
      const title = 'Отклик принят!';
      final body = 'Ваш отклик на "$taskTitle" принят! Начинайте работу.';

      await _writeNotification(
        userId: workerId, // ← строго userId мастера
        title: title,
        message: body,
        type: 'bid_accepted',
        relatedId: taskId,
      );

      if (kDebugMode) {
        debugPrint('PUSH: notifyBidAccepted — notified workerId=$workerId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH notifyBidAccepted error: $e');
      }
    }
  }

  /// Send push for new chat message -> to the recipient
  static Future<void> notifyNewMessage({
    required String chatId,
    required String recipientId,
    required String senderName,
    required String messageText,
  }) async {
    try {
      final truncated = messageText.length > 100
          ? '${messageText.substring(0, 100)}...'
          : messageText;

      await _writeNotification(
        userId: recipientId, // ← строго userId получателя сообщения
        title: senderName,
        message: truncated,
        type: 'new_message',
        relatedId: chatId,
      );

      if (kDebugMode) {
        debugPrint(
          'PUSH: notifyNewMessage — notified recipientId=$recipientId from "$senderName"',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH notifyNewMessage error: $e');
      }
    }
  }

  /// Write a notification document to Firestore.
  /// The recipient's Firestore listener will pick this up and show it.
  ///
  /// ВАЖНО: поле 'userId' — это ВСЕГДА ID пользователя-получателя.
  /// Слушатель фильтрует по .where('userId', isEqualTo: userId),
  /// поэтому уведомление придёт ТОЛЬКО нужному пользователю.
  static Future<void> _writeNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      final now = DateTime.now();
      // Уникальный ID: timestamp + userId hashcode → минимальные коллизии
      final notifId =
          'push_${now.millisecondsSinceEpoch}_${userId.hashCode.abs()}';

      await _db.collection('notifications').doc(notifId).set({
        'id': notifId,
        'userId': userId,       // ← КЛЮЧЕВОЕ поле: ID получателя
        'title': title,
        'message': message,
        'type': type,
        'relatedTaskId': relatedId ?? '',
        'isRead': false,
        'createdAt': now.toIso8601String(), // ISO8601 для надёжного парсинга
      });

      if (kDebugMode) {
        debugPrint(
          'PUSH: _writeNotification — written to Firestore: '
          'userId=$userId | type=$type | "$title"',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PUSH: _writeNotification error: $e');
      }
    }
  }
}
