import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final l10n = context.watch<LocalizationProvider>();
    final user = state.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          l10n.tr('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ═══════════════════════════════════════════
          // ПРОФИЛЬ
          // ═══════════════════════════════════════════
          _SectionTitle(title: l10n.tr('settings_section_profile')),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: l10n.tr('settings_edit_name'),
                subtitle: user.fullName,
                onTap: () => _showEditNameDialog(context, state, l10n, user.fullName),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.phone_outlined,
                iconColor: AppColors.info,
                title: l10n.tr('settings_phone'),
                subtitle: user.phone.isNotEmpty ? user.phone : l10n.tr('settings_not_set'),
                onTap: () => _showEditPhoneDialog(context, state, l10n, user.phone),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.location_city_outlined,
                iconColor: AppColors.warning,
                title: l10n.tr('settings_city'),
                subtitle: user.city.isNotEmpty ? user.city : l10n.tr('settings_not_set'),
                onTap: () => _showEditCityDialog(context, state, l10n, user.city),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.accent,
                title: l10n.tr('settings_bio'),
                subtitle: user.bio ?? l10n.tr('settings_add_bio'),
                maxSubtitleLines: 1,
                onTap: () => _showEditBioDialog(context, state, l10n, user.bio ?? ''),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ═══════════════════════════════════════════
          // ПРИЛОЖЕНИЕ
          // ═══════════════════════════════════════════
          _SectionTitle(title: l10n.tr('settings_section_app')),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: l10n.tr('settings_language'),
                subtitle: '${l10n.currentLanguageFlag} ${l10n.currentLanguageName}',
                onTap: () => _showLanguageDialog(context, l10n),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.warning,
                title: l10n.tr('settings_notifications'),
                subtitle: l10n.tr('settings_notifications_desc'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.tr('settings_notifications_system')),
                      backgroundColor: AppColors.info,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ═══════════════════════════════════════════
          // АККАУНТ
          // ═══════════════════════════════════════════
          _SectionTitle(title: l10n.tr('settings_section_account')),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.warning,
                title: l10n.tr('settings_logout'),
                subtitle: l10n.tr('settings_logout_desc'),
                onTap: () => _showLogoutDialog(context, state, l10n),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.error,
                title: l10n.tr('settings_delete_account_title'),
                subtitle: l10n.tr('settings_delete_account_desc'),
                maxSubtitleLines: 2,
                isDestructive: true,
                onTap: () => _showDeleteAccountDialog(context, state, l10n),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Версия приложения
          Center(
            child: Text(
              '${l10n.tr('settings_version')} 1.0.0',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.lightSlate,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EDIT NAME DIALOG
  // ═══════════════════════════════════════════
  void _showEditNameDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('settings_edit_name'), style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.tr('profile_edit_name_hint'),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'), style: const TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                state.updateProfile(fullName: newName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tr('profile_name_updated')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.tr('save')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EDIT PHONE DIALOG
  // ═══════════════════════════════════════════
  void _showEditPhoneDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n, String currentPhone) {
    final controller = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('settings_phone'), style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+992 XX XXX XX XX',
            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.info),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.info, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'), style: const TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty && newPhone != currentPhone) {
                state.updateProfile(phone: newPhone);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tr('settings_phone_updated')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.tr('save')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EDIT CITY DIALOG
  // ═══════════════════════════════════════════
  void _showEditCityDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n, String currentCity) {
    final cities = [
      'Душанбе', 'Худжанд', 'Бохтар', 'Куляб', 'Истаравшан',
      'Турсунзода', 'Исфара', 'Канибадам', 'Пенджикент', 'Вахдат',
      'Гиссар', 'Рогун', 'Нурек', 'Хорог',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('settings_city'), style: const TextStyle(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              final isSelected = city == currentCity;
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.lightSlate,
                  size: 22,
                ),
                title: Text(
                  city,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.deepSlate,
                  ),
                ),
                onTap: () {
                  state.updateProfile(city: city);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.tr('settings_city_updated')} $city'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'), style: const TextStyle(color: AppColors.slateGray)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // EDIT BIO DIALOG
  // ═══════════════════════════════════════════
  void _showEditBioDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n, String currentBio) {
    final controller = TextEditingController(text: currentBio);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('settings_bio'), style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.tr('settings_bio_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'), style: const TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () {
              final newBio = controller.text.trim();
              if (newBio != currentBio) {
                state.updateProfile(bio: newBio.isEmpty ? null : newBio);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tr('settings_bio_updated')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.tr('save')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LANGUAGE DIALOG
  // ═══════════════════════════════════════════
  void _showLanguageDialog(BuildContext context, LocalizationProvider l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('settings_language'), style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationProvider.supportedLanguages.map((lang) {
            final isSelected = lang['code'] == l10n.currentLocale;
            return ListTile(
              dense: true,
              leading: Text(lang['flag'] ?? '', style: const TextStyle(fontSize: 24)),
              title: Text(
                lang['name'] ?? '',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.deepSlate,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                  : null,
              onTap: () {
                l10n.switchLanguage(lang['code']!);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Text('${lang['flag']} ', style: const TextStyle(fontSize: 18)),
                        Text('${lang['name']}'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LOGOUT DIALOG
  // ═══════════════════════════════════════════
  void _showLogoutDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.tr('settings_logout'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ],
        ),
        content: Text(l10n.tr('settings_logout_confirm'),
            style: const TextStyle(fontSize: 15, color: AppColors.slateGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'),
                style: const TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              state.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.tr('settings_logout_success')),
                  ]),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.tr('settings_logout'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DELETE ACCOUNT DIALOG
  // ═══════════════════════════════════════════
  void _showDeleteAccountDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.tr('settings_delete_account_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          ],
        ),
        content: Text(l10n.tr('settings_delete_account_desc'),
            style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel'),
                style: const TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await state.deleteAccount(
                onError: (err) {
                  if (context.mounted) {
                    if (err == 'requires-recent-login') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.tr('settings_delete_relogin')),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
              );
              if (success && context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.tr('settings_delete_account_success')),
                    ]),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.tr('settings_delete_account_confirm'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.lightSlate,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int maxSubtitleLines;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.maxSubtitleLines = 1,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppColors.error : AppColors.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDestructive ? AppColors.error.withValues(alpha: 0.7) : AppColors.slateGray,
                    ),
                    maxLines: maxSubtitleLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.lightSlate,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}
