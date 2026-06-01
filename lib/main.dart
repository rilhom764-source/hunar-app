import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/firebase_options.dart';
import 'config/app_theme.dart';
import 'l10n/localization_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/push_notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
// master_profile_screen.dart merged into profile_screen.dart
import 'screens/auth_screen.dart';
// subscription_screen.dart доступен через профиль (вкладка скрыта)
import 'screens/analytics_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await Hive.openBox('app_settings');
  } catch (_) {
    // Non-critical — app works without local cache
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize push notifications (only on mobile)
    if (!kIsWeb) {
      await PushNotificationService.init();
    }
  } catch (e) {
    debugPrint('Firebase/FCM init error: $e');
  }

  runApp(const HunarApp());
}

class HunarApp extends StatelessWidget {
  const HunarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()..init()),
      ],
      child: Consumer2<LocalizationProvider, AppStateProvider>(
        builder: (context, l10n, state, _) {
          // Connect localization to state for localized notifications
          state.setLocalizationProvider(l10n);
          return MaterialApp(
            title: 'Hunar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: l10n.isLoaded
                ? _buildHomeForState(state)
                : const _SplashScreen(),
          );
        },
      ),
    );
  }

  Widget _buildHomeForState(AppStateProvider state) {
    if (!state.isAuthenticated) {
      return const AuthScreen();
    }
    return const AppShell();
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final isClient = state.isClient;

    // Client: 4 tabs (Home, [FAB], Messages, Profile)
    // Worker: 5 tabs (Home, Overview, [FAB], Messages, Profile)
    if (isClient) {
      return _ClientShell(l10n: l10n, state: state);
    } else {
      return _WorkerShell(l10n: l10n, state: state);
    }
  }
}

/// Client navigation: Home | + | Messages | Profile (4 items)
class _ClientShell extends StatelessWidget {
  final LocalizationProvider l10n;
  final AppStateProvider state;
  const _ClientShell({required this.l10n, required this.state});

  @override
  Widget build(BuildContext context) {
    // Client indices: 0=Home, 1=FAB(placeholder), 2=Messages, 3=Profile
    final screens = [
      const HomeScreen(),
      const SizedBox(), // Placeholder for FAB
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    // Clamp nav index for client (max 3)
    final navIdx = state.currentNavIndex.clamp(0, 3);
    final displayIdx = navIdx == 1 ? 0 : navIdx; // FAB → show home

    return Scaffold(
      body: IndexedStack(
        index: displayIdx,
        children: screens,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 380;
          final fabSize = isSmallScreen ? 48.0 : 54.0;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 16,
                    vertical: isSmallScreen ? 8 : 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: l10n.tr('nav_home'),
                      isActive: navIdx == 0,
                      onTap: () => state.setNavIndex(0),
                    ),
                    // Central FAB — create task
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CreateTaskScreen())),
                      child: Container(
                        width: fabSize,
                        height: fabSize,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 30 : 34,
                        ),
                      ),
                    ),
                    // Messages with badge
                    _NavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: l10n.tr('nav_messages'),
                      isActive: navIdx == 2,
                      onTap: () => state.setNavIndex(2),
                      badge: state.unreadMessageCount,
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person_rounded,
                      label: l10n.tr('nav_profile'),
                      isActive: navIdx == 3,
                      onTap: () => state.setNavIndex(3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Worker navigation: Home | Analytics | Messages | Profile (4 items)
class _WorkerShell extends StatelessWidget {
  final LocalizationProvider l10n;
  final AppStateProvider state;
  const _WorkerShell({required this.l10n, required this.state});

  @override
  Widget build(BuildContext context) {
    // Worker indices: 0=Home, 1=Analytics, 2=Messages, 3=Profile
    final screens = [
      const HomeScreen(),
      const AnalyticsDashboardScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    final navIdx = state.currentNavIndex.clamp(0, 3);

    return Scaffold(
      body: IndexedStack(
        index: navIdx,
        children: screens,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 380;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 16,
                    vertical: isSmallScreen ? 6 : 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: l10n.tr('nav_home'),
                      isActive: navIdx == 0,
                      onTap: () => state.setNavIndex(0),
                    ),
                    // Analytics tab
                    _NavItem(
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      label: 'Аналитика',
                      isActive: navIdx == 1,
                      onTap: () => state.setNavIndex(1),
                    ),
                    // Messages with badge
                    _NavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: l10n.tr('nav_messages'),
                      isActive: navIdx == 2,
                      onTap: () => state.setNavIndex(2),
                      badge: state.unreadMessageCount,
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person_rounded,
                      label: l10n.tr('nav_profile'),
                      isActive: navIdx == 3,
                      onTap: () => state.setNavIndex(3),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    final iconSize = isSmall ? 26.0 : 28.0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 14, vertical: isSmall ? 6 : 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge != null && badge! > 0
                ? Badge(
                    label: Text('$badge', style: const TextStyle(fontSize: 10)),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.primary : AppColors.lightSlate,
                      size: iconSize,
                    ),
                  )
                : Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppColors.primary : AppColors.lightSlate,
                    size: iconSize,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 11 : 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.lightSlate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Красивый splash-экран при загрузке приложения
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF006644),
              Color(0xFF00875A),
              Color(0xFF00B894),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Animated logo
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text(
                                  'H',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              // App name
              FadeTransition(
                opacity: _fadeAnim,
                child: const Text(
                  'Hunar',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnim,
                child: Text(
                  'Сервис услуг',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
