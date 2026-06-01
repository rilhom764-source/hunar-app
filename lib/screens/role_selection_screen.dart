import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/user_model.dart';
import '../services/push_notification_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // App logo/icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        size: 50,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.tr('app_name'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tr('role_selection_subtitle'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Role selection cards
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tr('role_selection_title'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepSlate,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tr('role_selection_description'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.slateGray,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Client role card
                        _RoleCard(
                          icon: Icons.person_outline,
                          title: l10n.tr('role_client'),
                          description: l10n.tr('role_client_description'),
                          color: AppColors.info,
                          isSelected: _selectedRole == UserRole.client,
                          onTap: () => setState(() => _selectedRole = UserRole.client),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Worker role card
                        _RoleCard(
                          icon: Icons.construction_outlined,
                          title: l10n.tr('role_worker'),
                          description: l10n.tr('role_worker_description'),
                          color: AppColors.primary,
                          isSelected: _selectedRole == UserRole.worker,
                          onTap: () => setState(() => _selectedRole = UserRole.worker),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Notifications permission info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.warning,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.tr('notifications_permission_title'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.tr('notifications_permission_description'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slateGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _selectedRole == null || _isLoading
                                ? null
                                : () => _handleContinue(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.divider,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.tr('continue'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Skip button (for testing)
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    final state = context.read<AppStateProvider>();
                                    state.completeOnboarding();
                                  },
                            child: Text(
                              l10n.tr('skip_for_now'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.slateGray,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    final state = context.read<AppStateProvider>();
    final l10n = context.read<LocalizationProvider>();

    try {
      // 1. Set user role
      await state.setInitialRole(_selectedRole!);

      // 2. Request notification permissions
      await _requestNotificationPermission();

      // 3. Complete onboarding
      state.completeOnboarding();

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('role_selection_success_with_notifications')),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('error_generic')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      // Request notification permissions via PushNotificationService
      await PushNotificationService.init();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting notification permission: $e');
      }
      return false;
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
