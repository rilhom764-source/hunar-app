import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/bid_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';
import '../models/subscription_model.dart';
import '../services/mock_data_service.dart';
import '../services/firebase_service.dart';
import '../services/payment_service.dart';
import '../services/push_notification_service.dart';
import '../utils/geo_utils.dart';
import '../l10n/localization_provider.dart';

class AppStateProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Localization reference for localized notifications
  LocalizationProvider? _l10n;
  void setLocalizationProvider(LocalizationProvider l10n) {
    _l10n = l10n;
  }

  // ═══════════════════════════════════════════════
  // AUTH STATE
  // ═══════════════════════════════════════════════
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  User? get firebaseUser => _auth.currentUser;
  String? _verificationId;
  String? get verificationId => _verificationId;
  bool _isAuthLoading = false;
  bool get isAuthLoading => _isAuthLoading;
  String? _authError;
  String? get authError => _authError;

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }

  /// Send SMS verification code via Firebase Auth
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in on Android
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isAuthLoading = false;
          _authError = _translatePhoneAuthError(e.code, e.message);
          notifyListeners();
          onError(_authError!);
        },
        codeSent: (String vId, int? resendToken) {
          _verificationId = vId;
          _isAuthLoading = false;
          notifyListeners();
          onCodeSent(vId);
        },
        codeAutoRetrievalTimeout: (String vId) {
          _verificationId = vId;
        },
      );
    } catch (e) {
      _isAuthLoading = false;
      final errMsg = e.toString();
      if (errMsg.contains('BILLING_NOT_ENABLED') ||
          errMsg.contains('billing')) {
        _authError = 'BILLING_NOT_ENABLED';
      } else {
        _authError = errMsg;
      }
      notifyListeners();
      onError(_authError!);
    }
  }

  /// Verify SMS code and sign in
  Future<bool> verifyCodeAndSignIn({
    required String smsCode,
    required Function(String error) onError,
  }) async {
    if (_verificationId == null) {
      onError('No verification ID. Please request a new code.');
      return false;
    }

    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _signInWithCredential(credential);
      return true;
    } catch (e) {
      _isAuthLoading = false;
      _authError = 'Invalid code. Please try again.';
      notifyListeners();
      onError(_authError!);
      return false;
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCred = await _auth.signInWithCredential(credential);
      final fbUser = userCred.user;

      if (fbUser != null) {
        // Check if user exists in Firestore (may fail if no access)
        UserModel? existingUser;
        try {
          existingUser = await FirebaseService.getUser(fbUser.uid);
        } catch (_) {
          // Firestore unavailable, continue with local user
        }
        if (existingUser == null) {
          existingUser = UserModel(
            id: fbUser.uid,
            fullName: fbUser.displayName ?? 'User',
            phone: fbUser.phoneNumber ?? '',
            role: UserRole.client,
            latitude: 38.5598,
            longitude: 68.7740,
            city: 'Dushanbe',
            createdAt: DateTime.now(),
          );
          // Try to save to Firestore (non-blocking)
          FirebaseService.createUser(existingUser);
        }
        _currentUser = existingUser;
        _isAuthenticated = true;
        _isAuthLoading = false;
        // Cache role for instant restore on next launch
        _cacheUserRole(_currentUser.role);
        _cacheMasterVerified(_currentUser.isMasterVerified);
        _loadDataFromFirestore(); // Non-blocking background load
        // 🔔 Register FCM token for push notifications
        PushNotificationService.onUserLogin();
        notifyListeners();
      }
    } catch (e) {
      _isAuthLoading = false;
      _authError = e.toString();
      notifyListeners();
    }
  }

  /// Translate Firebase Phone Auth error codes
  String _translatePhoneAuthError(String code, String? message) {
    final msg = message ?? '';
    if (msg.contains('BILLING_NOT_ENABLED') || code.contains('billing')) {
      return 'BILLING_NOT_ENABLED';
    }
    switch (code) {
      case 'invalid-phone-number':
        return 'INVALID_PHONE';
      case 'too-many-requests':
        return 'TOO_MANY_REQUESTS';
      case 'quota-exceeded':
        return 'QUOTA_EXCEEDED';
      case 'network-request-failed':
        return 'NETWORK_ERROR';
      case 'app-not-authorized':
        return 'APP_NOT_AUTHORIZED';
      default:
        return message ?? 'UNKNOWN_ERROR';
    }
  }

  /// Legacy mock login (kept for offline/dev mode)
  void login({required String phone, required String code}) {
    _isAuthenticated = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // EMAIL AUTH
  // ═══════════════════════════════════════════════

  /// Register new user with email and password
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required Function(String error) onError,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = userCred.user;

      if (fbUser != null) {
        await fbUser.updateDisplayName(fullName);

        final newUser = UserModel(
          id: fbUser.uid,
          fullName: fullName,
          phone: '',
          email: email,
          role: UserRole.client,
          latitude: 38.5598,
          longitude: 68.7740,
          city: 'Dushanbe',
          createdAt: DateTime.now(),
        );
        // Try to save to Firestore (non-blocking)
        FirebaseService.createUser(newUser);

        _currentUser = newUser;
        _isAuthenticated = true;
        _isAuthLoading = false;
        _cacheUserRole(_currentUser.role);
        _cacheMasterVerified(_currentUser.isMasterVerified);
        _loadDataFromFirestore();
        PushNotificationService.onUserLogin();
        notifyListeners();
        return true;
      }
      _isAuthLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isAuthLoading = false;
      _authError = _translateEmailAuthError(e.code);
      notifyListeners();
      onError(_authError!);
      return false;
    } catch (e) {
      _isAuthLoading = false;
      final errStr = e.toString();
      if (errStr.contains('network') || errStr.contains('SocketException')) {
        _authError = 'Нет интернет-соединения. Проверьте сеть';
      } else if (errStr.contains('channel-error') || errStr.contains('Unable to establish')) {
        _authError = 'Ошибка соединения. Проверьте интернет и попробуйте снова';
      } else {
        _authError = 'Ошибка регистрации. Проверьте интернет и повторите';
      }
      notifyListeners();
      onError(_authError!);
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required Function(String error) onError,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = userCred.user;

      if (fbUser != null) {
        UserModel? existingUser;
        try {
          existingUser = await FirebaseService.getUser(fbUser.uid);
        } catch (_) {}

        if (existingUser == null) {
          existingUser = UserModel(
            id: fbUser.uid,
            fullName: fbUser.displayName ?? 'User',
            phone: fbUser.phoneNumber ?? '',
            email: email,
            role: UserRole.client,
            latitude: 38.5598,
            longitude: 68.7740,
            city: 'Dushanbe',
            createdAt: DateTime.now(),
          );
          FirebaseService.createUser(existingUser);
        }
        _currentUser = existingUser;
        _isAuthenticated = true;
        _isAuthLoading = false;
        _cacheUserRole(_currentUser.role);
        _cacheMasterVerified(_currentUser.isMasterVerified);
        _loadDataFromFirestore();
        PushNotificationService.onUserLogin();
        notifyListeners();
        return true;
      }
      _isAuthLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isAuthLoading = false;
      _authError = _translateEmailAuthError(e.code);
      notifyListeners();
      onError(_authError!);
      return false;
    } catch (e) {
      _isAuthLoading = false;
      final errStr = e.toString();
      if (errStr.contains('network') || errStr.contains('SocketException')) {
        _authError = 'Нет интернет-соединения. Проверьте сеть';
      } else if (errStr.contains('channel-error') || errStr.contains('Unable to establish')) {
        _authError = 'Ошибка соединения. Проверьте интернет и попробуйте снова';
      } else {
        _authError = 'Ошибка входа. Проверьте интернет и повторите';
      }
      notifyListeners();
      onError(_authError!);
      return false;
    }
  }

  /// Translate Firebase Email Auth error codes
  String _translateEmailAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Пароль слишком слабый (мин. 6 символов)';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'network-request-failed':
        return 'Нет интернет-соединения. Проверьте сеть';
      case 'operation-not-allowed':
        return 'Вход через email не включён. Обратитесь к поддержке';
      case 'unknown':
        return 'Ошибка соединения с сервером. Проверьте интернет и попробуйте снова';
      case 'channel-error':
        return 'Ошибка соединения. Проверьте интернет';
      default:
        return 'Ошибка: $code. Проверьте интернет и попробуйте снова';
    }
  }

  void logout() {
    // 🔔 Clean up FCM token before sign out
    PushNotificationService.onUserLogout();
    // 🔥 Stop real-time listeners
    _stopTasksListener();
    _stopNotificationsListener();
    _auth.signOut();
    _isAuthenticated = false;
    _currentNavIndex = 0;
    _verificationId = null;
    _authError = null;
    _currentUser = MockDataService.currentUser;
    // Clear local cache
    try {
      if (Hive.isBoxOpen('app_settings')) {
        Hive.box('app_settings').clear();
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Delete user account from Firebase Auth and Firestore
  Future<bool> deleteAccount({required Function(String error) onError}) async {
    _isAuthLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        try {
          await FirebaseService.deleteUser(_currentUser.id);
        } catch (_) {
          // Firestore may not be accessible — continue with auth deletion
        }

        // Delete the Firebase Auth account
        await user.delete();
      }

      // Clear local state
      _isAuthenticated = false;
      _currentNavIndex = 0;
      _verificationId = null;
      _authError = null;
      _isAuthLoading = false;
      _currentUser = MockDataService.currentUser;

      // Clear local cache
      try {
        if (Hive.isBoxOpen('app_settings')) {
          Hive.box('app_settings').clear();
        }
      } catch (_) {}

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      if (e.code == 'requires-recent-login') {
        onError('requires-recent-login');
      } else {
        onError(e.message ?? 'Failed to delete account');
      }
      return false;
    } catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      onError(e.toString());
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // CURRENT USER
  // ═══════════════════════════════════════════════
  UserModel _currentUser = MockDataService.currentUser;
  UserModel get currentUser => _currentUser;

  bool get isClient => _currentUser.role == UserRole.client;
  bool get isWorker => _currentUser.role == UserRole.worker;

  // Toggle between client and worker roles
  void toggleRole() {
    // Block switching to worker if not master verified
    if (isClient && !_currentUser.isMasterVerified) {
      return; // Must pass the test first
    }
    _currentUser = _currentUser.copyWith(
      role: isClient ? UserRole.worker : UserRole.client,
    );
    _cacheUserRole(_currentUser.role);
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? bio,
    String? city,
    List<String>? skills,
  }) {
    _currentUser = _currentUser.copyWith(
      fullName: fullName,
      phone: phone,
      email: email,
      bio: bio,
      city: city,
      skills: skills,
    );
    // Save to Firestore
    FirebaseService.updateUser(_currentUser.id, _currentUser.toJson());
    notifyListeners();
  }

  /// Обновление аватара пользователя
  Future<void> updateUserAvatar(String? avatarUrl) async {
    _currentUser = _currentUser.copyWith(avatarUrl: avatarUrl);
    await FirebaseService.updateUser(_currentUser.id, {'avatarUrl': avatarUrl});
    notifyListeners();
  }

  /// Добавить фото в портфолио
  Future<void> addPortfolioImage(String imageUrl) async {
    final updated = List<String>.from(_currentUser.portfolioImages)
      ..add(imageUrl);
    _currentUser = _currentUser.copyWith(portfolioImages: updated);
    await FirebaseService.addPortfolioImage(_currentUser.id, imageUrl);
    notifyListeners();
  }

  /// Удалить фото из портфолио
  Future<void> removePortfolioImage(String imageUrl) async {
    final updated = List<String>.from(_currentUser.portfolioImages)
      ..remove(imageUrl);
    _currentUser = _currentUser.copyWith(portfolioImages: updated);
    await FirebaseService.removePortfolioImage(_currentUser.id, imageUrl);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // TASKS
  // ═══════════════════════════════════════════════
  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  /// Real-time Firestore listener for tasks (auto-updates when new tasks created)
  StreamSubscription? _tasksListener;

  /// Real-time Firestore listener for notifications (auto-updates per user)
  StreamSubscription? _notificationsListener;

  /// Открытые заказы (для мастеров) - только ЧУЖИЕ заказы, не свои
  List<TaskModel> get openTasks {
    final currentUserId = _currentUser.id;
    final result = _tasks
        .where(
          (t) =>
              t.status == TaskStatus.open &&
              t.clientId != currentUserId, // Исключаем свои заказы
        )
        .toList();

    if (kDebugMode) {
      debugPrint(
        '🔍 openTasks: Всего заданий: ${_tasks.length}, Открытых (чужих): ${result.length}',
      );
      debugPrint('🔍 Current user ID: $currentUserId');
      for (final t in _tasks.take(5)) {
        debugPrint(
          '   - Task: ${t.title}, status: ${t.status}, clientId: ${t.clientId}',
        );
      }
    }

    return result;
  }

  // CLIENT-specific (для Заказчиков)
  List<TaskModel> get myCreatedTasks =>
      _tasks.where((t) => t.clientId == _currentUser.id).toList();
  List<TaskModel> get myActiveClientTasks => myCreatedTasks
      .where(
        (t) => t.status == TaskStatus.open || t.status == TaskStatus.inProgress,
      )
      .toList();
  List<TaskModel> get myCompletedClientTasks =>
      myCreatedTasks.where((t) => t.status == TaskStatus.completed).toList();

  // WORKER-specific (для Мастеров)
  List<TaskModel> get myAssignedTasks =>
      _tasks.where((t) => t.assignedWorkerId == _currentUser.id).toList();
  List<TaskModel> get myActiveWorkerJobs =>
      myAssignedTasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get myCompletedWorkerJobs =>
      myAssignedTasks.where((t) => t.status == TaskStatus.completed).toList();

  // Universal "my tasks" depending on role
  List<TaskModel> get myTasks => isClient ? myCreatedTasks : myAssignedTasks;

  /// Public getter for analytics — exposes the full bids map
  Map<String, List<BidModel>> get bidsMap => _bids;

  /// Tasks where current user is the assigned worker (for analytics)
  List<TaskModel> get myWorkerTasks =>
      _tasks.where((t) => t.assignedWorkerId == _currentUser.id).toList();

  // WORKER bids
  List<BidModel> get myBids {
    final List<BidModel> result = [];
    for (final entry in _bids.entries) {
      for (final bid in entry.value) {
        if (bid.workerId == _currentUser.id) {
          result.add(bid);
        }
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<BidModel> get myPendingBids =>
      myBids.where((b) => b.status == BidStatus.pending).toList();
  List<BidModel> get myAcceptedBids =>
      myBids.where((b) => b.status == BidStatus.accepted).toList();

  // Worker earnings
  double get totalEarnings {
    double sum = 0;
    for (final task in myCompletedWorkerJobs) {
      final bids = _bids[task.id] ?? [];
      for (final bid in bids) {
        if (bid.workerId == _currentUser.id &&
            bid.status == BidStatus.accepted) {
          sum += bid.amount;
          break;
        }
      }
    }
    return sum;
  }

  // ═══════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════
  final List<SubscriptionModel> _subscriptions = [];
  List<SubscriptionModel> get mySubscriptions =>
      _subscriptions
          .where((s) => s.userId == _currentUser.id)
          .toList()
          .reversed
          .toList();

  /// Create a new subscription for current user
  Future<void> createSubscription({
    required String planId,
    required String planName,
    required SubscriptionFrequency frequency,
    required String serviceCategory,
    required String serviceDescription,
    required String preferredTime,
    required double pricePerVisit,
    required int tasksTotal,
  }) async {
    final now = DateTime.now();
    final nextVisit = now.add(const Duration(days: 7));
    final sub = SubscriptionModel(
      id: 'sub_${_uuid.v4().substring(0, 8)}',
      userId: _currentUser.id,
      planId: planId,
      planName: planName,
      serviceCategory: serviceCategory,
      serviceDescription: serviceDescription,
      preferredTime: preferredTime,
      frequency: frequency,
      status: SubscriptionStatus.active,
      pricePerVisit: pricePerVisit,
      tasksUsed: 0,
      tasksTotal: tasksTotal,
      startDate: now,
      nextVisit: nextVisit,
      createdAt: now,
    );
    _subscriptions.insert(0, sub);
    notifyListeners();
    // Save to Firestore (fire & forget)
    try {
      await FirebaseService.createSubscription(sub);
    } catch (e) {
      if (kDebugMode) debugPrint('createSubscription Firestore error: $e');
    }
  }

  /// Pause an active subscription
  void pauseSubscription(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subscriptions[index] = _subscriptions[index].copyWith(
        status: SubscriptionStatus.paused,
      );
      FirebaseService.updateSubscription(id, {'status': 'paused'});
      notifyListeners();
    }
  }

  /// Resume a paused subscription
  void resumeSubscription(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subscriptions[index] = _subscriptions[index].copyWith(
        status: SubscriptionStatus.active,
      );
      FirebaseService.updateSubscription(id, {'status': 'active'});
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════
  // WORKERS
  // ═══════════════════════════════════════════════
  List<UserModel> _workers = [];
  List<UserModel> get workers => _workers;

  /// Get any user by ID (from workers list, current user, or tasks)
  UserModel? getUserById(String userId) {
    if (_currentUser.id == userId) return _currentUser;
    final found = _workers.where((w) => w.id == userId);
    if (found.isNotEmpty) return found.first;
    return null;
  }

  // ═══════════════════════════════════════════════
  // BIDS
  // ═══════════════════════════════════════════════
  final Map<String, List<BidModel>> _bids = {};
  List<BidModel> getBidsForTask(String taskId) {
    final bids = _bids[taskId] ?? [];
    // Sort by reviews count (descending), then by rating (descending)
    final sortedBids = List<BidModel>.from(bids)
      ..sort((a, b) {
        // First, sort by reviews count (more reviews = higher priority)
        final reviewsCompare = b.workerReviewsCount.compareTo(
          a.workerReviewsCount,
        );
        if (reviewsCompare != 0) return reviewsCompare;
        // If same reviews count, sort by rating
        return b.workerRating.compareTo(a.workerRating);
      });
    return sortedBids;
  }

  // ═══════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════
  final Map<String, List<ReviewModel>> _reviews = {};
  List<ReviewModel> getReviewsForUser(String userId) => _reviews[userId] ?? [];

  ReviewModel addReview({
    required String taskId,
    required String targetUserId,
    required double rating,
    required String comment,
  }) {
    final review = ReviewModel(
      id: 'rev_${_uuid.v4().substring(0, 8)}',
      taskId: taskId,
      reviewerId: _currentUser.id,
      reviewerName: _currentUser.fullName,
      reviewerAvatar: _currentUser.avatarUrl,
      targetUserId: targetUserId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.putIfAbsent(targetUserId, () => []);
    _reviews[targetUserId]!.insert(0, review);

    // 🔑 Единый аккаунт: пересчитываем рейтинг из всех отзывов,
    // независимо от текущей роли пользователя
    if (targetUserId == _currentUser.id) {
      final allReviews = _reviews[targetUserId]!;
      final newRating = allReviews.isNotEmpty
          ? allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
              allReviews.length
          : 0.0;
      _currentUser = _currentUser.copyWith(
        rating: double.parse(newRating.toStringAsFixed(1)),
        reviewsCount: allReviews.length,
      );
      FirebaseService.updateUser(targetUserId, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'reviewsCount': allReviews.length,
      });
    } else {
      // Пересчитываем рейтинг для другого пользователя в workers list
      final idx = _workers.indexWhere((w) => w.id == targetUserId);
      if (idx != -1) {
        final allReviews = _reviews[targetUserId]!;
        final newRating = allReviews.isNotEmpty
            ? allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
                allReviews.length
            : 0.0;
        _workers[idx] = _workers[idx].copyWith(
          rating: double.parse(newRating.toStringAsFixed(1)),
          reviewsCount: allReviews.length,
        );
        FirebaseService.updateUser(targetUserId, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'reviewsCount': allReviews.length,
        });
      }
    }

    // Save to Firestore
    FirebaseService.createReview(review);

    final reviewTitle = _l10n?.tr('notif_new_review_title') ?? 'New Review!';
    final reviewMsg =
        _l10n?.tr(
          'notif_new_review_msg',
          params: {
            'name': _currentUser.fullName,
            'rating': rating.toStringAsFixed(1),
          },
        ) ??
        '${_currentUser.fullName} left a review: ${rating.toStringAsFixed(1)}';

    _sendNotificationToUser(
      targetUserId: targetUserId,
      title: reviewTitle,
      message: reviewMsg,
      type: NotificationType.newReview,
      relatedTaskId: taskId,
      relatedUserId: _currentUser.id,
    );

    notifyListeners();
    return review;
  }

  bool hasReviewedTask(String taskId) {
    for (final reviews in _reviews.values) {
      for (final review in reviews) {
        if (review.taskId == taskId && review.reviewerId == _currentUser.id) {
          return true;
        }
      }
    }
    return false;
  }

  // ═══════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  void _addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedTaskId,
    String? relatedUserId,
  }) {
    final notifId = 'notif_${_uuid.v4().substring(0, 8)}';
    _notifications.insert(
      0,
      NotificationModel(
        id: notifId,
        title: title,
        message: message,
        type: type,
        relatedTaskId: relatedTaskId,
        relatedUserId: relatedUserId,
        createdAt: DateTime.now(),
      ),
    );

    // Save to Firestore for CURRENT user only
    FirebaseService.createNotification(
      id: notifId,
      userId: _currentUser.id,
      title: title,
      message: message,
      type: type,
      relatedTaskId: relatedTaskId,
      relatedUserId: relatedUserId,
    );
  }

  /// Send notification to a SPECIFIC user (not the current user).
  /// Only writes to Firestore — does NOT add to local _notifications list
  /// (because it belongs to another user).
  void _sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedTaskId,
    String? relatedUserId,
  }) {
    final notifId = 'notif_${_uuid.v4().substring(0, 8)}';
    FirebaseService.createNotification(
      id: notifId,
      userId: targetUserId,
      title: title,
      message: message,
      type: type,
      relatedTaskId: relatedTaskId,
      relatedUserId: relatedUserId,
    );
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      FirebaseService.markNotificationRead(id);
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    FirebaseService.markAllNotificationsRead(_currentUser.id);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // CHAT / MESSAGES (Firestore real-time)
  // ═══════════════════════════════════════════════
  final List<ChatThread> _chatThreads = [];
  List<ChatThread> get chatThreads => _chatThreads;
  int get unreadMessageCount =>
      _chatThreads.fold(0, (sum, t) => sum + t.unreadCount);

  /// Send a message via Firestore (real-time)
  void sendMessage({required String threadId, required String content}) {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;

    FirebaseService.sendChatMessage(
      chatId: threadId,
      senderId: fbUser.uid,
      senderName: _currentUser.fullName,
      content: content,
    );
    // No need to update local state — Firestore stream handles it
  }

  /// Open or create a 1-on-1 chat with a participant via Firestore.
  /// Returns the Firestore chat document ID.
  Future<String> getOrCreateFirestoreChat({
    required String participantId,
    required String participantName,
    String? participantAvatar,
    String? taskId,
    String? taskTitle,
  }) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return '';

    final chatId = await FirebaseService.getOrCreateChat(
      currentUserId: fbUser.uid,
      currentUserName: _currentUser.fullName,
      participantId: participantId,
      participantName: participantName,
      participantAvatar: participantAvatar,
      taskId: taskId,
      taskTitle: taskTitle,
    );
    return chatId;
  }

  /// Legacy method kept for compatibility — now redirects to Firestore
  ChatThread getOrCreateThread({
    required String participantId,
    required String participantName,
    String? taskId,
    String? taskTitle,
  }) {
    // Return a placeholder — real chat creation happens async
    final existing = _chatThreads
        .where((t) => t.participantId == participantId)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final thread = ChatThread(
      id: 'pending_${_uuid.v4().substring(0, 8)}',
      participantId: participantId,
      participantName: participantName,
      taskId: taskId,
      taskTitle: taskTitle,
      messages: [],
      lastActivity: DateTime.now(),
    );

    // Also create in Firestore (fire & forget)
    getOrCreateFirestoreChat(
      participantId: participantId,
      participantName: participantName,
      taskId: taskId,
      taskTitle: taskTitle,
    );

    return thread;
  }

  // ═══════════════════════════════════════════════
  // FAVORITES
  // ═══════════════════════════════════════════════
  final Set<String> _favoriteWorkers = {};
  final Set<String> _favoriteTasks = {};

  bool isWorkerFavorite(String workerId) => _favoriteWorkers.contains(workerId);
  bool isTaskFavorite(String taskId) => _favoriteTasks.contains(taskId);

  void toggleFavoriteWorker(String workerId) {
    if (_favoriteWorkers.contains(workerId)) {
      _favoriteWorkers.remove(workerId);
    } else {
      _favoriteWorkers.add(workerId);
    }
    notifyListeners();
  }

  void toggleFavoriteTask(String taskId) {
    if (_favoriteTasks.contains(taskId)) {
      _favoriteTasks.remove(taskId);
    } else {
      _favoriteTasks.add(taskId);
    }
    notifyListeners();
  }

  List<UserModel> get favoriteWorkersList =>
      _workers.where((w) => _favoriteWorkers.contains(w.id)).toList();
  List<TaskModel> get favoriteTasksList =>
      _tasks.where((t) => _favoriteTasks.contains(t.id)).toList();

  // ═══════════════════════════════════════════════
  // PAYMENT
  // ═══════════════════════════════════════════════
  final PaymentService _paymentService = PaymentService();

  // ═══════════════════════════════════════════════
  // SEARCH & FILTERS
  // ═══════════════════════════════════════════════
  double _searchRadius = 10.0;
  double get searchRadius => _searchRadius;

  // Advanced filters
  TaskCategory? _selectedCategory;
  TaskCategory? get selectedCategory => _selectedCategory;

  String _sortBy = 'newest';
  String get sortBy => _sortBy;
  static const List<String> sortOptions = [
    'newest',
    'price_low',
    'price_high',
    'closest',
    'deadline',
  ];

  double _minBudget = 0;
  double _maxBudget = 10000;
  double get minBudget => _minBudget;
  double get maxBudget => _maxBudget;

  double _minRating = 0;
  double get minRating => _minRating;

  void setCategory(TaskCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setBudgetRange(double min, double max) {
    _minBudget = min;
    _maxBudget = max;
    notifyListeners();
  }

  void setMinRating(double rating) {
    _minRating = rating;
    notifyListeners();
  }

  void setSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = null;
    _sortBy = 'newest';
    _minBudget = 0;
    _maxBudget = 10000;
    _minRating = 0;
    notifyListeners();
  }

  List<TaskModel> get filteredTasks {
    // Используем nearbyTasks — задания в радиусе пользователя
    var filtered = nearbyTasks.toList();

    // Фильтр по категории
    if (_selectedCategory != null) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Фильтр по бюджету
    filtered = filtered
        .where((t) => t.budget >= _minBudget && t.budget <= _maxBudget)
        .toList();

    // Фильтр по рейтингу клиента (если задан)
    if (_minRating > 0) {
      filtered = filtered.where((t) {
        // Фильтруем задания по рейтингу клиента
        final client = _workers.where((w) => w.id == t.clientId).toList();
        if (client.isEmpty) return true; // если клиент неизвестен - показываем
        return client.first.rating >= _minRating;
      }).toList();
    }

    // Сортировка
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.budget.compareTo(b.budget));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.budget.compareTo(a.budget));
        break;
      case 'closest':
        filtered.sort((a, b) => distanceToTask(a).compareTo(distanceToTask(b)));
        break;
      case 'deadline':
        filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      default: // newest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  List<UserModel> get filteredWorkers {
    var filtered = nearbyWorkers.toList();
    if (_minRating > 0) {
      filtered = filtered.where((w) => w.rating >= _minRating).toList();
    }
    return filtered;
  }

  // ═══════════════════════════════════════════════
  // GEO
  // ═══════════════════════════════════════════════
  List<UserModel> get nearbyWorkers {
    return GeoUtils.sortByDistance(
      items: GeoUtils.filterByRadius(
        items: _workers,
        centerLat: _currentUser.latitude,
        centerLon: _currentUser.longitude,
        radiusKm: _searchRadius,
        getLatitude: (w) => w.latitude,
        getLongitude: (w) => w.longitude,
      ),
      centerLat: _currentUser.latitude,
      centerLon: _currentUser.longitude,
      getLatitude: (w) => w.latitude,
      getLongitude: (w) => w.longitude,
    );
  }

  List<TaskModel> get nearbyTasks {
    return GeoUtils.sortByDistance(
      items: GeoUtils.filterByRadius(
        items: openTasks,
        centerLat: _currentUser.latitude,
        centerLon: _currentUser.longitude,
        radiusKm: _searchRadius,
        getLatitude: (t) => t.latitude,
        getLongitude: (t) => t.longitude,
      ),
      centerLat: _currentUser.latitude,
      centerLon: _currentUser.longitude,
      getLatitude: (t) => t.latitude,
      getLongitude: (t) => t.longitude,
    );
  }

  double distanceToWorker(UserModel worker) {
    return GeoUtils.distanceTo(
      userLat: _currentUser.latitude,
      userLon: _currentUser.longitude,
      targetLat: worker.latitude,
      targetLon: worker.longitude,
    );
  }

  double distanceToTask(TaskModel task) {
    return GeoUtils.distanceTo(
      userLat: _currentUser.latitude,
      userLon: _currentUser.longitude,
      targetLat: task.latitude,
      targetLon: task.longitude,
    );
  }

  // ═══════════════════════════════════════════════
  // LOADING & NAVIGATION
  // ═══════════════════════════════════════════════
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // BECOME MASTER (after passing quiz)
  // ═══════════════════════════════════════════════
  bool get isMasterVerified => _currentUser.isMasterVerified;

  void becomeMaster() {
    _currentUser = _currentUser.copyWith(
      isMasterVerified: true,
      masterVerifiedAt: DateTime.now(),
      role: UserRole.worker,
    );
    _currentNavIndex = 0;
    _selectedCategory = null;

    // Save to local cache for instant restore on next launch
    _cacheMasterVerified(true);
    _cacheUserRole(UserRole.worker);

    // Save to Firestore
    FirebaseService.updateUser(_currentUser.id, {
      'isMasterVerified': true,
      'masterVerifiedAt': DateTime.now().toIso8601String(),
      'role': 'worker',
    });

    _addNotification(
      title: 'Master status activated!',
      message:
          'You have passed the verification test and can now accept tasks as a master.',
      type: NotificationType.system,
    );

    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ROLE SELECTION & TOGGLE
  // ═══════════════════════════════════════════════

  /// Set initial user role during onboarding
  Future<void> setInitialRole(UserRole role) async {
    _currentUser = _currentUser.copyWith(role: role);

    // Save role to local cache AND Firestore
    _cacheUserRole(role);
    await FirebaseService.updateUser(_currentUser.id, {'role': role.name});

    // If worker role, also start notification listener
    if (role == UserRole.worker) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        PushNotificationService.startNotificationListener(uid);
      }
    }

    notifyListeners();
  }

  String toggleUserRole() {
    final newRole = _currentUser.role == UserRole.client
        ? UserRole.worker
        : UserRole.client;
    _currentUser = _currentUser.copyWith(role: newRole);
    _currentNavIndex = 0;
    _selectedCategory = null;

    // Save role to local cache AND Firestore
    _cacheUserRole(newRole);
    FirebaseService.updateUser(_currentUser.id, {'role': newRole.name});

    notifyListeners();
    return newRole == UserRole.client
        ? 'role_switched_to_client'
        : 'role_switched_to_worker';
  }

  // ═══════════════════════════════════════════════
  // INIT — check if user is already logged in via Firebase, load data
  // ═══════════════════════════════════════════════
  void init() {
    // Check if user is already signed in via Firebase
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      // Restore cached role from Hive (so UI shows correct view instantly)
      final cachedRole = _restoreCachedRole();

      // User has an existing Firebase session — restore auth
      _currentUser = UserModel(
        id: fbUser.uid,
        fullName: fbUser.displayName ?? fbUser.phoneNumber ?? 'User',
        phone: fbUser.phoneNumber ?? '',
        role: cachedRole,
        latitude: 38.5598,
        longitude: 68.7740,
        city: 'Dushanbe',
        createdAt: DateTime.now(),
      );
      _isAuthenticated = true;

      // Restore isMasterVerified from local cache
      _restoreMasterVerifiedFromCache();

      // Load data from Firestore (real data, no mock)
      _syncWithFirestore();
    } else {
      // No Firebase session — load mock data for demo / auth screen
      _tasks = MockDataService.tasks;
      _workers = MockDataService.workers;
      for (final task in _tasks) {
        _bids[task.id] = MockDataService.getBidsForTask(task.id);
      }
      for (final worker in _workers) {
        _reviews[worker.id] = MockDataService.getReviewsForUser(worker.id);
      }
      _notifications.addAll(MockDataService.getNotifications());
      // Mock mode: only keep system notifications and those for the demo user
      // In real Firebase mode, notifications are already filtered by userId query
      _notifications.removeWhere((n) =>
          n.type != NotificationType.system &&
          n.relatedUserId != null &&
          n.relatedUserId != _currentUser.id);

      _isAuthenticated = false;
      _currentUser = MockDataService.currentUser;

      // Restore cached role even for demo/mock user
      final cachedRole = _restoreCachedRole();
      if (cachedRole != _currentUser.role) {
        _currentUser = _currentUser.copyWith(role: cachedRole);
      }
      _restoreMasterVerifiedFromCache();
    }

    notifyListeners();
  }

  /// Restore cached user role from Hive for instant UI on app restart
  UserRole _restoreCachedRole() {
    try {
      if (Hive.isBoxOpen('app_settings')) {
        final box = Hive.box('app_settings');
        final cachedRole =
            box.get('userRole', defaultValue: 'client') as String;
        if (cachedRole == 'worker') return UserRole.worker;
      }
    } catch (_) {
      // Hive not ready — default to client
    }
    return UserRole.client;
  }

  /// Cache user role to Hive for instant restore on next launch
  void _cacheUserRole(UserRole role) {
    try {
      if (Hive.isBoxOpen('app_settings')) {
        final box = Hive.box('app_settings');
        box.put('userRole', role.name);
      }
    } catch (_) {
      // Non-critical
    }
  }

  /// Restore isMasterVerified from Hive cache for instant UI
  void _restoreMasterVerifiedFromCache() {
    try {
      if (Hive.isBoxOpen('app_settings')) {
        final box = Hive.box('app_settings');
        final cached = box.get('isMasterVerified', defaultValue: false) as bool;
        if (cached) {
          _currentUser = _currentUser.copyWith(isMasterVerified: true);
        }
      }
    } catch (_) {
      // Hive box may not be open yet — ignore
    }
  }

  /// Save isMasterVerified to Hive cache
  void _cacheMasterVerified(bool value) {
    try {
      if (Hive.isBoxOpen('app_settings')) {
        final box = Hive.box('app_settings');
        box.put('isMasterVerified', value);
      }
    } catch (_) {
      // Non-critical
    }
  }

  /// Sync all data with Firestore: load real data from cloud
  Future<void> _syncWithFirestore() async {
    try {
      // Test Firestore access first
      final hasAccess = await FirebaseService.testFirestoreAccess();
      if (!hasAccess) {
        debugPrint('Firestore not accessible, loading mock data as fallback');
        // Fallback to mock data if Firestore is unavailable
        _tasks = MockDataService.tasks;
        _workers = MockDataService.workers;
        for (final task in _tasks) {
          _bids[task.id] = MockDataService.getBidsForTask(task.id);
        }
        notifyListeners();
        return;
      }

      // Load everything from Firestore (real data)
      await _loadDataFromFirestore();

      // Update local cache with Firestore values (role is NOT overwritten here)
      _cacheMasterVerified(_currentUser.isMasterVerified);

      // Start real-time notification listener for push notifications
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        PushNotificationService.startNotificationListener(uid);
      }

      // Note: _startTasksListener() is called inside _loadDataFromFirestore()
    } catch (e) {
      debugPrint('Error syncing with Firestore: $e');
    }
  }

  /// Start real-time Firestore listener for tasks collection
  /// This automatically updates the tasks list when new tasks are created
  void _startTasksListener() {
    try {
      _tasksListener?.cancel(); // Cancel existing listener
      _tasksListener = FirebaseService.tasksStream().listen(
        (tasks) {
          _tasks = tasks;
          if (kDebugMode) {
            debugPrint(
              'REAL-TIME: Updated tasks list (${tasks.length} tasks, ${tasks.where((t) => t.status == TaskStatus.open).length} open)',
            );
          }
          notifyListeners();
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('Tasks listener error: $e');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to start tasks listener: $e');
      }
    }
  }

  /// Stop the real-time tasks listener
  void _stopTasksListener() {
    _tasksListener?.cancel();
    _tasksListener = null;
  }

  /// Start real-time Firestore listener for notifications collection.
  /// Automatically updates _notifications list when new notifications arrive.
  /// Each user sees ONLY their own notifications (filtered by userId).
  void _startNotificationsListener(String userId) {
    _notificationsListener?.cancel(); // Cancel existing listener
    _notificationsListener = FirebaseService.notificationsStream(userId).listen(
      (notifs) {
        _notifications.clear();
        _notifications.addAll(notifs);
        if (kDebugMode) {
          debugPrint(
            'NOTIFS REAL-TIME: Updated notifications list '
            '(${notifs.length} total, '
            '${notifs.where((n) => !n.isRead).length} unread) '
            'for userId=$userId',
          );
        }
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) {
          debugPrint('Notifications listener error for userId=$userId: $e');
        }
      },
    );
  }

  /// Stop the real-time notifications listener
  void _stopNotificationsListener() {
    _notificationsListener?.cancel();
    _notificationsListener = null;
  }

  /// Load all data from Firestore into app state
  Future<void> _loadDataFromFirestore() async {
    try {
      final currentUid = _auth.currentUser?.uid ?? _currentUser.id;

      // Load user profile from Firestore (using REAL Firebase uid)
      // IMPORTANT: preserve locally cached role — Firestore may store stale role
      final savedRole = _currentUser.role;
      final user = await FirebaseService.getUser(currentUid);
      if (user != null) {
        _currentUser = user.copyWith(role: savedRole);
      }

      // Load ALL tasks from Firestore (not just mock)
      final firestoreTasks = await FirebaseService.getAllTasks();
      _tasks = firestoreTasks; // Always replace — Firestore is source of truth
      if (kDebugMode) {
        debugPrint(
          'SYNC: Loaded ${firestoreTasks.length} tasks from Firestore',
        );
        debugPrint(
          'SYNC: Open tasks: ${firestoreTasks.where((t) => t.status == TaskStatus.open).length}',
        );
      }

      // 🔥 Start real-time tasks listener after initial load
      _startTasksListener();

      // 🔔 Start real-time notifications listener for current user
      _startNotificationsListener(currentUid);

      // Load workers (both from Firestore)
      final firestoreWorkers = await FirebaseService.getWorkers();
      _workers = firestoreWorkers; // Always replace — even if empty
      if (kDebugMode) {
        debugPrint(
          'SYNC: Loaded ${firestoreWorkers.length} workers from Firestore',
        );
      }

      // Load bids for all tasks
      _bids.clear();
      for (final task in _tasks) {
        _bids[task.id] = await FirebaseService.getBidsForTask(task.id);
      }

      // Load reviews for workers
      _reviews.clear();
      for (final worker in _workers) {
        _reviews[worker.id] = await FirebaseService.getReviewsForUser(
          worker.id,
        );
      }

      // Notifications are loaded via real-time stream (_startNotificationsListener)
      // No need to load them manually here — the stream handles it automatically.

      // Chat threads are loaded via Firestore streams in MessagesScreen

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Firestore data: $e');
    }
  }

  /// Manual refresh from Firestore
  Future<void> refreshFromFirestore() async {
    _isLoading = true;
    notifyListeners();
    await _loadDataFromFirestore();
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // TASK CRUD
  // ═══════════════════════════════════════════════
  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  bool hasWorkerBidOnTask(String taskId) {
    final bids = _bids[taskId] ?? [];
    return bids.any((b) => b.workerId == _currentUser.id);
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required TaskCategory category,
    required double budget,
    required String location,
    required double latitude,
    required double longitude,
    required DateTime deadline,
    List<String> imageUrls = const [], // 📸 Фото
    String? voiceMessageUrl, // 🎤 Голос
  }) async {
    final task = TaskModel(
      id: 'task_${_uuid.v4().substring(0, 8)}',
      clientId: _currentUser.id,
      clientName: _currentUser.fullName,
      clientAvatar: _currentUser.avatarUrl,
      title: title,
      description: description,
      category: category,
      budget: budget,
      location: location,
      latitude: latitude,
      longitude: longitude,
      deadline: deadline,
      status: TaskStatus.open,
      imageUrls: imageUrls, // 📸 Добавлено
      voiceMessageUrl: voiceMessageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _tasks.insert(0, task);
    _bids[task.id] = [];
    notifyListeners();

    // Save to Firestore FIRST (await ensures it's saved before notifying)
    await FirebaseService.createTask(task);

    // THEN notify all workers (writes to notifications collection)
    // Each worker's Firestore listener will pick it up and show local notification
    _notifyWorkersAboutNewTask(task);

    return task;
  }

  void _notifyWorkersAboutNewTask(TaskModel task) {
    // 🔔 Send push notification to ALL workers via Firestore listener.
    // PushNotificationService.notifyNewTask() writes to 'notifications' collection
    // → Each worker's Firestore real-time listener picks it up
    // → Shows local notification via flutter_local_notifications
    // This queries workers DIRECTLY from Firestore (not local _workers list)
    PushNotificationService.notifyNewTask(
      taskId: task.id,
      taskTitle: task.title,
      location: task.location,
      budget: task.budget,
      clientId: _currentUser.id,
    );
  }

  void updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskCategory? category,
    double? budget,
    String? location,
    DateTime? deadline,
    TaskStatus? status,
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        title: title,
        description: description,
        category: category,
        budget: budget,
        location: location,
        deadline: deadline,
        status: status,
      );

      // Save to Firestore
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category.name;
      if (budget != null) updateData['budget'] = budget;
      if (location != null) updateData['location'] = location;
      if (deadline != null) updateData['deadline'] = deadline.toIso8601String();
      if (status != null) updateData['status'] = status.name;
      FirebaseService.updateTask(taskId, updateData);

      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _bids.remove(taskId);
    FirebaseService.deleteTask(taskId);
    notifyListeners();
  }

  void advanceTaskStatus(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      TaskStatus? newStatus;
      switch (task.status) {
        case TaskStatus.open:
          newStatus = TaskStatus.inProgress;
          break;
        case TaskStatus.inProgress:
          newStatus = TaskStatus.completed;
          break;
        default:
          break;
      }
      if (newStatus != null) {
        _tasks[index] = task.copyWith(status: newStatus);
        FirebaseService.updateTask(taskId, {'status': newStatus.name});

        if (newStatus == TaskStatus.completed && task.assignedWorkerId != null) {
          _sendNotificationToUser(
            targetUserId: task.assignedWorkerId!,
            title: 'Task completed',
            message: '"${task.title}" - confirmed and paid!',
            type: NotificationType.taskCompleted,
            relatedTaskId: taskId,
            relatedUserId: _currentUser.id,
          );
        }

        notifyListeners();
      }
    }
  }

  /// Worker marks work as started
  void markWorkStarted(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        workStarted: true,
        workStartedAt: DateTime.now(),
      );
      FirebaseService.updateTask(taskId, {
        'workStarted': true,
        'workStartedAt': DateTime.now().toIso8601String(),
      });

      // Notify the CLIENT (not ourselves)
      final notifTitle = _l10n?.tr('notif_work_started_title') ?? 'Work started!';
      final notifMsg = _l10n?.tr('notif_work_started_msg', params: {'title': task.title}) ??
          'Master started working on "${task.title}"';
      _sendNotificationToUser(
        targetUserId: task.clientId,
        title: notifTitle,
        message: notifMsg,
        type: NotificationType.taskUpdate,
        relatedTaskId: taskId,
        relatedUserId: _currentUser.id,
      );
      notifyListeners();
    }
  }

  /// Worker marks work as completed (sends to client for confirmation)
  void markWorkCompleted(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(status: TaskStatus.completed);
      FirebaseService.updateTask(taskId, {'status': 'completed'});

      // Notify the CLIENT (not ourselves)
      final notifTitle = _l10n?.tr('notif_work_completed_title') ?? 'Work completed!';
      final notifMsg = _l10n?.tr('notif_work_completed_msg', params: {'title': task.title}) ??
          'Master completed "${task.title}". Please confirm and pay.';
      _sendNotificationToUser(
        targetUserId: task.clientId,
        title: notifTitle,
        message: notifMsg,
        type: NotificationType.taskCompleted,
        relatedTaskId: taskId,
        relatedUserId: _currentUser.id,
      );
      notifyListeners();
    }
  }

  void cancelTask(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(status: TaskStatus.cancelled);
      FirebaseService.updateTask(taskId, {'status': 'cancelled'});

      // Notify the assigned worker (if any)
      if (task.assignedWorkerId != null) {
        _sendNotificationToUser(
          targetUserId: task.assignedWorkerId!,
          title: 'Task cancelled',
          message: '"${task.title}" was cancelled by the client',
          type: NotificationType.taskCancelled,
          relatedTaskId: taskId,
          relatedUserId: _currentUser.id,
        );
      }
      notifyListeners();
    }
  }

  /// ❌ Заказчик отклоняет завершение → возврат в "в работе"
  void rejectTaskCompletion(String taskId, String reason) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(status: TaskStatus.inProgress);
      FirebaseService.updateTask(taskId, {'status': 'inProgress'});

      // Уведомление мастеру
      if (task.assignedWorkerId != null) {
        _sendNotificationToUser(
          targetUserId: task.assignedWorkerId!,
          title: 'Требуется доработка',
          message: 'Заказчик не подтвердил завершение: $reason',
          type: NotificationType.bidRejected,
          relatedTaskId: taskId,
          relatedUserId: _currentUser.id,
        );
      }

      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════
  // BIDDING
  // ═══════════════════════════════════════════════
  BidModel placeBid({
    required String taskId,
    required double amount,
    required String message,
    required String estimatedTime,
  }) {
    final bid = BidModel(
      id: 'bid_${_uuid.v4().substring(0, 8)}',
      taskId: taskId,
      workerId: _currentUser.id,
      workerName: _currentUser.fullName,
      workerAvatar: _currentUser.avatarUrl,
      workerRating: _currentUser.rating,
      workerReviewsCount: _currentUser.reviewsCount,
      amount: amount,
      message: message,
      estimatedTime: estimatedTime,
      createdAt: DateTime.now(),
    );

    _bids.putIfAbsent(taskId, () => []);
    _bids[taskId]!.insert(0, bid);

    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        bidsCount: (_bids[taskId]?.length ?? 0),
      );
    }

    // Save to Firestore
    FirebaseService.createBid(bid);

    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => _tasks.first,
    );

    _sendNotificationToUser(
      targetUserId: task.clientId,
      title: 'New bid',
      message: '${_currentUser.fullName} bid on "${task.title}"',
      type: NotificationType.newBid,
      relatedTaskId: taskId,
      relatedUserId: _currentUser.id,
    );

    // 🔔 Send PUSH notification to the task owner (client)
    PushNotificationService.notifyNewBid(
      taskId: taskId,
      taskTitle: task.title,
      clientId: task.clientId,
      workerName: _currentUser.fullName,
      bidAmount: amount,
    );

    notifyListeners();
    return bid;
  }

  void acceptBid(String taskId, String bidId) {
    final bids = _bids[taskId];
    if (bids == null) return;

    for (int i = 0; i < bids.length; i++) {
      if (bids[i].id == bidId) {
        bids[i] = bids[i].copyWith(status: BidStatus.accepted);
        FirebaseService.updateBid(bidId, {'status': 'accepted'});

        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(
            status: TaskStatus.inProgress,
            assignedWorkerId: bids[i].workerId,
          );
          FirebaseService.updateTask(taskId, {
            'status': 'inProgress',
            'assignedWorkerId': bids[i].workerId,
          });
        }
        _sendNotificationToUser(
          targetUserId: bids[i].workerId,
          title: 'Bid accepted!',
          message: 'Your bid has been accepted. Start working!',
          type: NotificationType.bidAccepted,
          relatedTaskId: taskId,
          relatedUserId: _currentUser.id,
        );

        // 🔔 Send PUSH notification to the worker
        final acceptedTask = _tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => _tasks.first,
        );
        PushNotificationService.notifyBidAccepted(
          taskId: taskId,
          taskTitle: acceptedTask.title,
          workerId: bids[i].workerId,
        );
      } else {
        // Заказ закрыт для остальных мастеров — их отклики отклоняются
        if (bids[i].status == BidStatus.pending) {
          final otherWorkerId = bids[i].workerId;
          bids[i] = bids[i].copyWith(status: BidStatus.rejected);
          FirebaseService.updateBid(bids[i].id, {'status': 'rejected'});

          // Уведомляем остальных мастеров, что заказ уже закрыт
          final closedTask = _tasks.firstWhere(
            (t) => t.id == taskId,
            orElse: () => _tasks.first,
          );
          _sendNotificationToUser(
            targetUserId: otherWorkerId,
            title: 'Заказ закрыт',
            message: 'По заказу "${closedTask.title}" заказчик выбрал другого мастера.',
            type: NotificationType.bidRejected,
            relatedTaskId: taskId,
            relatedUserId: _currentUser.id,
          );
        } else {
          bids[i] = bids[i].copyWith(status: BidStatus.rejected);
          FirebaseService.updateBid(bids[i].id, {'status': 'rejected'});
        }
      }
    }
    notifyListeners();
  }

  void rejectBid(String taskId, String bidId) {
    final bids = _bids[taskId];
    if (bids == null) return;

    final index = bids.indexWhere((b) => b.id == bidId);
    if (index != -1) {
      final rejectedWorkerId = bids[index].workerId;
      bids[index] = bids[index].copyWith(status: BidStatus.rejected);
      FirebaseService.updateBid(bidId, {'status': 'rejected'});

      _sendNotificationToUser(
        targetUserId: rejectedWorkerId,
        title: 'Bid rejected',
        message: 'Your bid was rejected by the client.',
        type: NotificationType.bidRejected,
        relatedTaskId: taskId,
        relatedUserId: _currentUser.id,
      );
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════
  // PAYMENT
  // ═══════════════════════════════════════════════
  Future<PaymentResult> processPayment({
    required PaymentMethod method,
    required double amount,
    required String taskId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _paymentService.processPayment(
      method: method,
      amount: amount,
      senderInfo: _currentUser.phone,
      receiverInfo: '+992 00 000 0000',
      description: 'Payment for task $taskId',
    );

    if (result.success) {
      _addNotification(
        title: 'Payment successful',
        message: 'Payment ${amount.toInt()} TJS processed',
        type: NotificationType.paymentReceived,
        relatedTaskId: taskId,
      );
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ═══════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════
  List<TaskModel> searchTasks(String query) {
    if (query.isEmpty) return filteredTasks;
    final lower = query.toLowerCase();
    return filteredTasks
        .where(
          (t) =>
              t.title.toLowerCase().contains(lower) ||
              t.description.toLowerCase().contains(lower) ||
              t.location.toLowerCase().contains(lower),
        )
        .toList();
  }

  List<UserModel> searchWorkers(String query) {
    if (query.isEmpty) return filteredWorkers;
    final lower = query.toLowerCase();
    return filteredWorkers
        .where(
          (w) =>
              w.fullName.toLowerCase().contains(lower) ||
              w.skills.any((s) => s.toLowerCase().contains(lower)) ||
              (w.bio?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════
  double get clientTotalSpent {
    double sum = 0;
    for (final task in myCompletedClientTasks) {
      sum += task.budget;
    }
    return sum;
  }

  int get totalBidsOnMyTasks {
    int count = 0;
    for (final task in myCreatedTasks) {
      count += getBidsForTask(task.id).length;
    }
    return count;
  }
}
