import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../providers/app_state_provider.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.handyman_rounded,
      color: AppColors.primary,
      titleKey: 'onboarding_title_1',
      descKey: 'onboarding_desc_1',
    ),
    _OnboardingPage(
      icon: Icons.people_rounded,
      color: AppColors.info,
      titleKey: 'onboarding_title_2',
      descKey: 'onboarding_desc_2',
    ),
    _OnboardingPage(
      icon: Icons.payments_rounded,
      color: AppColors.warning,
      titleKey: 'onboarding_title_3',
      descKey: 'onboarding_desc_3',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Language selector at top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (code) => l10n.switchLanguage(code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.currentLanguageFlag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(l10n.currentLanguageName, style: const TextStyle(fontSize: 13, color: AppColors.slateGray)),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 18, color: AppColors.slateGray),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => LocalizationProvider.supportedLanguages
                        .map((lang) => PopupMenuItem<String>(
                              value: lang['code'],
                              child: Row(
                                children: [
                                  Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(lang['name']!),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _buildPage(ctx, _pages[i], l10n),
              ),
            ),

            // Dots + buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppColors.primary : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.read<AppStateProvider>().completeOnboarding();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? l10n.tr('onboarding_next')
                            : l10n.tr('onboarding_start'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        context.read<AppStateProvider>().completeOnboarding();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      child: Text(l10n.tr('onboarding_skip'), style: const TextStyle(color: AppColors.slateGray)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPage page, LocalizationProvider l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.tr(page.titleKey),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr(page.descKey),
            style: const TextStyle(fontSize: 15, color: AppColors.slateGray, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
  });
}
