import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/network_image_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../models/bid_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';
import '../services/media_service.dart';
import 'task_detail_screen.dart';
import 'become_master_screen.dart';
import 'reviews_list_screen.dart';
import 'settings_screen.dart';

/// Единый профиль для заказчика и мастера — полностью адаптирован под мобильные устройства
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final user = state.currentUser;
    final l10n = context.watch<LocalizationProvider>();
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;
    // Адаптивные размеры для компактного мобильного вида
    final hPad = isSmall ? 12.0 : 16.0;
    final avatarR = isSmall ? 38.0 : 44.0;

    return Container(
      color: AppColors.scaffoldBg,
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // ════════════════════════════════════════
            // КОМПАКТНЫЙ ГРАДИЕНТНЫЙ ХЕДЕР
            // ════════════════════════════════════════
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, isSmall ? 14 : 18),
                    child: Column(
                      children: [
                        // Top bar: title + settings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.tr('profile_title'),
                              style: TextStyle(
                                fontSize: isSmall ? 20 : 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.settings_outlined, color: Colors.white, size: isSmall ? 20.0 : 22.0),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmall ? 10 : 14),

                        // Аватар + имя + инфо в одну строку (компактно)
                        Row(
                          children: [
                            // Аватар
                            GestureDetector(
                              onTap: () => _showAvatarOptions(context, state, user.id),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: avatarR,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      backgroundImage: user.avatarUrl != null ? smartImageProvider(user.avatarUrl!) : null,
                                      child: user.avatarUrl == null
                                          ? Text(
                                              user.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                                              style: TextStyle(fontSize: avatarR * 0.55, fontWeight: FontWeight.w700, color: Colors.white),
                                            )
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: Icon(Icons.camera_alt, color: Colors.white, size: isSmall ? 10 : 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isSmall ? 10 : 14),
                            // Имя, телефон, город
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.fullName,
                                          style: TextStyle(
                                            fontSize: isSmall ? 18 : 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (user.isVerified) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.verified, color: Colors.white, size: isSmall ? 16 : 18),
                                      ],
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _showEditNameDialog(context, state, l10n, user.fullName),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.edit_rounded, color: Colors.white, size: isSmall ? 12 : 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  if (user.phone.isNotEmpty)
                                    Text(
                                      user.phone,
                                      style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.7)),
                                      const SizedBox(width: 2),
                                      Text(
                                        user.city,
                                        style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.85)),
                                      ),
                                    ],
                                  ),
                                  // Master badge inline
                                  if (state.isMasterVerified && state.isWorker) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified, size: isSmall ? 12 : 14, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.tr('master_verified_badge'),
                                            style: TextStyle(fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmall ? 10 : 14),

                        // Переключатель ролей (компактный)
                        _CompactRoleSwitcher(
                          isClient: state.isClient,
                          isMasterVerified: state.isMasterVerified,
                          onToggle: () => state.toggleRole(),
                          l10n: l10n,
                          isSmall: isSmall,
                        ),

                        // Become Master banner (small)
                        if (!state.isMasterVerified && state.isClient) ...[
                          SizedBox(height: isSmall ? 8 : 10),
                          _CompactBecomeMasterBanner(isSmall: isSmall),
                        ],

                        SizedBox(height: isSmall ? 10 : 14),

                        // Stats (одинаковый стиль для обеих ролей)
                        _CompactStatsRow(
                          isClient: state.isClient,
                          activeCount: state.isClient ? state.myActiveClientTasks.length : state.myActiveWorkerJobs.length,
                          completedCount: state.isClient ? state.myCompletedClientTasks.length : state.myCompletedWorkerJobs.length,
                          // 🔑 Единый аккаунт: рейтинг один для обеих ролей
                          rating: state.currentUser.rating > 0
                              ? state.currentUser.rating
                              : null,
                          isSmall: isSmall,
                          l10n: l10n,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ════════════════════════════════════════
            // BIO (если есть)
            // ════════════════════════════════════════
            if (user.bio != null && user.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: _InfoCard(
                  margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardHeader(icon: Icons.person_outline, iconColor: AppColors.info, title: l10n.tr('profile_bio')),
                      const SizedBox(height: 6),
                      Text(user.bio!, style: TextStyle(fontSize: isSmall ? 12 : 13, color: AppColors.slateGray, height: 1.4)),
                    ],
                  ),
                ),
              ),

            // ════════════════════════════════════════
            // SKILLS (только для мастера)
            // ════════════════════════════════════════
            if (state.isWorker && user.skills.isNotEmpty)
              SliverToBoxAdapter(
                child: _InfoCard(
                  margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardHeader(icon: Icons.build_circle_outlined, iconColor: AppColors.primary, title: l10n.tr('profile_skills')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.skills.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.accent.withValues(alpha: 0.06)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(s, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: isSmall ? 11 : 12)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // ════════════════════════════════════════
            // PORTFOLIO
            // ════════════════════════════════════════
            SliverToBoxAdapter(
              child: _CompactPortfolioSection(
                images: user.portfolioImages,
                onAddPhoto: () => _addPortfolioPhoto(context, state),
                onRemovePhoto: (url) => _removePortfolioPhoto(context, state, url),
                isSmall: isSmall,
                hPad: hPad,
              ),
            ),

            // ════════════════════════════════════════
            // ЗАДАНИЯ
            // ════════════════════════════════════════
            SliverToBoxAdapter(
              child: _CompactSectionHeader(
                icon: Icons.assignment,
                title: state.isClient ? l10n.tr('client_my_tasks') : l10n.tr('worker_active_jobs'),
                hPad: hPad,
              ),
            ),
            _buildTasksList(
              tasks: state.isClient ? state.myCreatedTasks : state.myActiveWorkerJobs,
              emptyMsg: state.isClient ? l10n.tr('client_no_tasks') : l10n.tr('worker_no_active'),
              emptyIcon: Icons.inbox,
              hPad: hPad,
              isSmall: isSmall,
            ),

            SliverToBoxAdapter(child: SizedBox(height: isSmall ? 16 : 20)),

            // COMPLETED
            SliverToBoxAdapter(
              child: _CompactSectionHeader(
                icon: Icons.done_all,
                title: l10n.tr('profile_completed'),
                hPad: hPad,
              ),
            ),
            _buildTasksList(
              tasks: state.isClient ? state.myCompletedClientTasks : state.myCompletedWorkerJobs,
              emptyMsg: state.isClient ? l10n.tr('client_no_tasks') : l10n.tr('worker_no_completed'),
              emptyIcon: Icons.check_circle_outline,
              hPad: hPad,
              isSmall: isSmall,
            ),

            // MY BIDS (только для мастера)
            if (state.isWorker) ...[
              SliverToBoxAdapter(child: SizedBox(height: isSmall ? 16 : 20)),
              SliverToBoxAdapter(
                child: _CompactSectionHeader(
                  icon: Icons.gavel_rounded,
                  title: l10n.tr('worker_my_bids_title'),
                  hPad: hPad,
                ),
              ),
              _buildBidsList(state, l10n, hPad, isSmall),
            ],

            // MY REVIEWS — видны обеим ролям (единый аккаунт)
            if (state.getReviewsForUser(user.id).isNotEmpty || state.isWorker) ...[
              SliverToBoxAdapter(child: SizedBox(height: isSmall ? 16 : 20)),
              SliverToBoxAdapter(
                child: _MyReviewsSection(
                  reviews: state.getReviewsForUser(user.id),
                  worker: user,
                  hPad: hPad,
                  isSmall: isSmall,
                  l10n: l10n,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // BUILDERS
  // ════════════════════════════════════════
  Widget _buildTasksList({
    required List<TaskModel> tasks,
    required String emptyMsg,
    required IconData emptyIcon,
    required double hPad,
    required bool isSmall,
  }) {
    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: _CompactEmptySection(message: emptyMsg, icon: emptyIcon, hPad: hPad, isSmall: isSmall),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _CompactTaskTile(task: tasks[index], hPad: hPad, isSmall: isSmall),
        childCount: tasks.length,
      ),
    );
  }

  Widget _buildBidsList(AppStateProvider state, LocalizationProvider l10n, double hPad, bool isSmall) {
    final bids = state.myBids;
    if (bids.isEmpty) {
      return SliverToBoxAdapter(
        child: _CompactEmptySection(message: l10n.tr('worker_no_bids'), icon: Icons.gavel_rounded, hPad: hPad, isSmall: isSmall),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final bid = bids[index];
          final task = state.getTaskById(bid.taskId);
          return _CompactBidTile(bid: bid, task: task, hPad: hPad, isSmall: isSmall);
        },
        childCount: bids.length,
      ),
    );
  }

  // ════════════════════════════════════════
  // DIALOGS
  // ════════════════════════════════════════
  void _showEditNameDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('profile_edit_name'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.tr('profile_edit_name_hint'),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.tr('cancel'), style: const TextStyle(color: AppColors.slateGray, fontSize: 13))),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                state.updateProfile(fullName: newName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tr('profile_name_updated')), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.tr('save'), style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, AppStateProvider state, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text('Выбрать фото профиля', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.camera_alt, color: AppColors.primary, size: 22),
                title: const Text('Сделать фото', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final xFile = await MediaService.pickImageFromCameraXFile();
                  if (xFile != null && context.mounted) _uploadAvatarXFile(context, state, xFile);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_library, color: AppColors.primary, size: 22),
                title: const Text('Выбрать из галереи', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final xFile = await MediaService.pickImageFromGalleryXFile();
                  if (xFile != null && context.mounted) _uploadAvatarXFile(context, state, xFile);
                },
              ),
              if (state.currentUser.avatarUrl != null)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.delete, color: AppColors.error, size: 22),
                  title: const Text('Удалить фото', style: TextStyle(color: AppColors.error, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    state.updateUserAvatar(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPortfolioPhoto(BuildContext context, AppStateProvider state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text('Добавить фото', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_library, color: AppColors.primary, size: 22),
                title: const Text('Из галереи', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final images = await MediaService.pickMultipleImages(maxCount: 5);
                  if (images.isNotEmpty && context.mounted) {
                    _uploadPortfolioPhotos(context, state, images);
                  }
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.camera_alt, color: AppColors.primary, size: 22),
                title: const Text('Сделать фото', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final image = await MediaService.pickImageFromCameraXFile();
                  if (image != null && context.mounted) {
                    _uploadPortfolioPhotos(context, state, [image]);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPortfolioPhotos(BuildContext context, AppStateProvider state, List<XFile> images) async {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text('Загрузка ${images.length} фото...', style: const TextStyle(fontSize: 13))],
        ),
      ),
    );

    int uploaded = 0;
    int failed = 0;

    try {
      for (final img in images) {
        final url = await MediaService.uploadXFile(img, folder: 'portfolio');
        if (url != null && url.isNotEmpty) {
          await state.addPortfolioImage(url);
          uploaded++;
        } else {
          failed++;
        }
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(uploaded > 0 ? (failed > 0 ? 'Загружено $uploaded, ошибок: $failed' : 'Фото добавлены! ($uploaded)') : 'Не удалось загрузить'),
          backgroundColor: uploaded > 0 ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _removePortfolioPhoto(BuildContext context, AppStateProvider state, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Удалить фото?', style: TextStyle(fontSize: 16)),
        content: const Text('Фото будет удалено из портфолио', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(fontSize: 13))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); state.removePortfolioImage(url); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('Удалить', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAvatarXFile(BuildContext context, AppStateProvider state, XFile xFile) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Загружаю аватар...', style: TextStyle(fontSize: 13))]),
      ),
    );

    try {
      final avatarUrl = await MediaService.uploadXFile(xFile, folder: 'avatars');
      if (context.mounted) {
        Navigator.pop(context);
      }
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await state.updateUserAvatar(avatarUrl);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аватар обновлён!'), backgroundColor: AppColors.success));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка загрузки аватара'), backgroundColor: AppColors.error));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}

// ════════════════════════════════════════════════════════
// КОМПАКТНЫЕ ВИДЖЕТЫ ДЛЯ МОБИЛЬНОЙ ВЕРСИИ
// ════════════════════════════════════════════════════════

/// Премиум переключатель ролей с красивыми иконками
class _CompactRoleSwitcher extends StatefulWidget {
  final bool isClient;
  final bool isMasterVerified;
  final VoidCallback onToggle;
  final LocalizationProvider l10n;
  final bool isSmall;

  const _CompactRoleSwitcher({
    required this.isClient,
    required this.isMasterVerified,
    required this.onToggle,
    required this.l10n,
    required this.isSmall,
  });

  @override
  State<_CompactRoleSwitcher> createState() => _CompactRoleSwitcherState();
}

class _CompactRoleSwitcherState extends State<_CompactRoleSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.02), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    final l10n = widget.l10n;
    final switchingToMaster = widget.isClient;

    // CRITICAL: If switching to master mode and NOT verified — force test
    if (switchingToMaster && !widget.isMasterVerified) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BecomeMasterScreen()),
      ).then((result) {
        if (result == true && mounted) {
          // Test passed — now toggle to master mode
          _doSwitch();
        }
      });
      return;
    }

    // Show confirmation dialog before switching roles
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: switchingToMaster
                      ? [const Color(0xFF10B981).withValues(alpha: 0.15), const Color(0xFF059669).withValues(alpha: 0.08)]
                      : [const Color(0xFF6366F1).withValues(alpha: 0.15), const Color(0xFF8B5CF6).withValues(alpha: 0.08)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                switchingToMaster ? Icons.handyman_rounded : Icons.person_rounded,
                color: switchingToMaster ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('role_switch_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
            ),
            const SizedBox(height: 8),
            Text(
              switchingToMaster ? l10n.tr('role_switch_to_master') : l10n.tr('role_switch_to_client'),
              style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 🔑 Единый аккаунт — подсказка
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Рейтинг и отзывы — общие для обеих ролей',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: Text(
                    l10n.tr('role_switch_cancel'),
                    style: const TextStyle(color: AppColors.slateGray, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _doSwitch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: switchingToMaster ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.tr('role_switch_confirm'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _doSwitch() {
    _ctrl.forward(from: 0);
    widget.onToggle();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.isClient ? Icons.handyman_rounded : Icons.person_rounded,
            color: Colors.white, size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.isClient ? 'Режим мастера' : 'Режим заказчика', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      backgroundColor: widget.isClient ? const Color(0xFF10B981) : const Color(0xFF6366F1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.isSmall ? 52.0 : 56.0;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Точный расчёт позиции индикатора на основе реальной ширины контейнера
              final totalW = constraints.maxWidth;
              final pillW = totalW / 2 - 4; // половина минус отступ
              final pillLeft = widget.isClient ? 4.0 : totalW / 2;
              final pillRight = widget.isClient ? totalW / 2 : 4.0;

              return Container(
                height: h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: Stack(
                  children: [
                    // ── Скользящий индикатор (pill) ──
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: pillLeft,
                      right: pillRight,
                      top: 4,
                      bottom: 4,
                      child: Container(
                        width: pillW,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.isClient
                                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                : [const Color(0xFF10B981), const Color(0xFF059669)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isClient
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF10B981))
                                  .withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Кнопки (поверх индикатора) ──
                    Row(
                      children: [
                        // Кнопка "Заказчик"
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.isClient ? null : _handleTap,
                            child: _PremiumRoleOption(
                              icon: Icons.person_rounded,
                              activeIcon: Icons.person,
                              label: widget.l10n.tr('profile_switch_client'),
                              isSelected: widget.isClient,
                              isSmall: widget.isSmall,
                            ),
                          ),
                        ),
                        // Кнопка "Мастер"
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: !widget.isClient ? null : _handleTap,
                            child: _PremiumRoleOption(
                              icon: Icons.handyman_rounded,
                              activeIcon: Icons.handyman,
                              label: widget.l10n.tr('profile_switch_role'),
                              isSelected: !widget.isClient,
                              showBadge: widget.isMasterVerified,
                              isSmall: widget.isSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumRoleOption extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool showBadge;
  final bool isSmall;

  const _PremiumRoleOption({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.showBadge = false,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Иконка с badge ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: EdgeInsets.all(isSmall ? 6 : 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    color: Colors.white
                        .withValues(alpha: isSelected ? 1.0 : 0.55),
                    size: isSmall ? 17 : 19,
                  ),
                ),
              ),
              // Бейдж верификации мастера
              if (showBadge)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 7),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 5),
          // ── Текст подписи ──
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.55),
                fontSize: isSmall ? 13 : 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Премиум статистика с красивыми иконками
class _CompactStatsRow extends StatelessWidget {
  final bool isClient;
  final int activeCount;
  final int completedCount;
  final double? rating;
  final bool isSmall;
  final LocalizationProvider l10n;

  const _CompactStatsRow({
    required this.isClient,
    required this.activeCount,
    required this.completedCount,
    this.rating,
    required this.isSmall,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _PremiumStat(
                icon: Icons.rocket_launch_rounded,
                value: '$activeCount',
                label: l10n.tr('client_active_count'),
                gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                isSmall: isSmall,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.divider.withValues(alpha: 0), AppColors.divider, AppColors.divider.withValues(alpha: 0)],
                ),
              ),
            ),
            Expanded(
              child: _PremiumStat(
                icon: Icons.verified_rounded,
                value: '$completedCount',
                label: l10n.tr('client_completed_count'),
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                isSmall: isSmall,
              ),
            ),
            if (rating != null) ...[
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.divider.withValues(alpha: 0), AppColors.divider, AppColors.divider.withValues(alpha: 0)],
                  ),
                ),
              ),
              Expanded(
                child: _PremiumStat(
                  icon: Icons.star_rounded,
                  value: rating!.toStringAsFixed(1),
                  label: l10n.tr('profile_rating'),
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFEAB308)],
                  isSmall: isSmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradientColors;
  final bool isSmall;

  const _PremiumStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradientColors,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmall ? 32 : 36,
          height: isSmall ? 32 : 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientColors[0].withValues(alpha: 0.15), gradientColors[1].withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ).createShader(bounds),
            child: Icon(icon, color: Colors.white, size: isSmall ? 18 : 20),
          ),
        ),
        SizedBox(height: isSmall ? 4 : 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmall ? 18 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isSmall ? 1 : 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            color: AppColors.slateGray,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Компактный баннер «Стать мастером»
class _CompactBecomeMasterBanner extends StatelessWidget {
  final bool isSmall;
  const _CompactBecomeMasterBanner({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final l10n = Provider.of<LocalizationProvider>(context).l10n;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeMasterScreen()));
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [const Icon(Icons.celebration, color: Colors.white, size: 18), const SizedBox(width: 8), Text(l10n['master_verified_success'] ?? 'Вы теперь мастер!')]),
            backgroundColor: AppColors.success,
          ));
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 14, vertical: isSmall ? 8 : 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.engineering, color: Colors.white, size: isSmall ? 18 : 20),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n['become_master_title'] ?? 'Стать мастером', style: TextStyle(fontSize: isSmall ? 13 : 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(l10n['become_master_description'] ?? 'Начните зарабатывать', style: TextStyle(fontSize: isSmall ? 10 : 11, color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: isSmall ? 14 : 16),
          ],
        ),
      ),
    );
  }
}

/// Карточка-контейнер
class _InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const _InfoCard({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

/// Заголовок карточки
class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _CardHeader({required this.icon, required this.iconColor, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
      ],
    );
  }
}

/// Компактный заголовок секции
class _CompactSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final double hPad;
  const _CompactSectionHeader({required this.icon, required this.title, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

/// Компактная пустая секция
class _CompactEmptySection extends StatelessWidget {
  final String message;
  final IconData icon;
  final double hPad;
  final bool isSmall;
  const _CompactEmptySection({required this.message, required this.icon, required this.hPad, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
      padding: EdgeInsets.all(isSmall ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: isSmall ? 32 : 40, color: AppColors.slateGray.withValues(alpha: 0.3)),
          SizedBox(height: isSmall ? 6 : 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: isSmall ? 12 : 13, color: AppColors.slateGray)),
        ],
      ),
    );
  }
}

/// Компактная плитка задания
class _CompactTaskTile extends StatelessWidget {
  final TaskModel task;
  final double hPad;
  final bool isSmall;
  const _CompactTaskTile({required this.task, required this.hPad, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          child: Row(
            children: [
              Container(
                width: isSmall ? 36 : 40,
                height: isSmall ? 36 : 40,
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(task.categoryIcon, style: TextStyle(fontSize: isSmall ? 16 : 18))),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 12 : 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(_statusLabel, style: TextStyle(fontSize: isSmall ? 9 : 10, color: _statusColor, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on, size: isSmall ? 10 : 12, color: AppColors.slateGray),
                        const SizedBox(width: 2),
                        Flexible(child: Text(task.location, style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.slateGray), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              Text('${task.budget.toInt()} TJS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmall ? 12 : 13, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.open: return AppColors.statusOpen;
      case TaskStatus.inProgress: return AppColors.statusInProgress;
      case TaskStatus.completed: return AppColors.statusCompleted;
      case TaskStatus.cancelled: return AppColors.statusCancelled;
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.open: return 'Открыто';
      case TaskStatus.inProgress: return 'В работе';
      case TaskStatus.completed: return 'Завершено';
      case TaskStatus.cancelled: return 'Отменено';
    }
  }
}

/// Компактная плитка ставки
class _CompactBidTile extends StatelessWidget {
  final BidModel bid;
  final TaskModel? task;
  final double hPad;
  final bool isSmall;
  const _CompactBidTile({required this.bid, this.task, required this.hPad, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final statusColor = _bidStatusColor;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: InkWell(
        onTap: task != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task!))) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          child: Row(
            children: [
              Container(
                width: isSmall ? 34 : 38,
                height: isSmall ? 34 : 38,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  bid.status == BidStatus.accepted ? Icons.check_circle : bid.status == BidStatus.rejected ? Icons.cancel : Icons.hourglass_top,
                  color: statusColor,
                  size: isSmall ? 16 : 18,
                ),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task?.title ?? 'Задание #${bid.taskId}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 12 : 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(_bidStatusLabel, style: TextStyle(fontSize: isSmall ? 9 : 10, color: statusColor, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Text(bid.estimatedTime, style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.lightSlate)),
                      ],
                    ),
                  ],
                ),
              ),
              Text('${bid.amount.toInt()} TJS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmall ? 12 : 13, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Color get _bidStatusColor {
    switch (bid.status) {
      case BidStatus.pending: return AppColors.warning;
      case BidStatus.accepted: return AppColors.success;
      case BidStatus.rejected: return AppColors.error;
    }
  }

  String get _bidStatusLabel {
    switch (bid.status) {
      case BidStatus.pending: return 'На рассмотрении';
      case BidStatus.accepted: return 'Принято';
      case BidStatus.rejected: return 'Отклонено';
    }
  }
}

/// Компактная секция портфолио
class _CompactPortfolioSection extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;
  final bool isSmall;
  final double hPad;

  const _CompactPortfolioSection({required this.images, required this.onAddPhoto, required this.onRemovePhoto, required this.isSmall, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CardHeader(icon: Icons.photo_library, iconColor: AppColors.primary, title: 'Мои фото'),
              const Spacer(),
              GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate, size: isSmall ? 12 : 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text('Добавить', style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (images.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmall ? 16 : 20),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: AppColors.lightSlate, size: isSmall ? 28 : 32),
                  const SizedBox(height: 6),
                  Text('Добавьте фото работ', textAlign: TextAlign.center, style: TextStyle(fontSize: isSmall ? 11 : 12, color: AppColors.lightSlate)),
                ],
              ),
            )
          else
            SizedBox(
              height: isSmall ? 80 : 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length + 1,
                itemBuilder: (context, index) {
                  final imgSize = isSmall ? 80.0 : 100.0;
                  if (index == images.length) {
                    return GestureDetector(
                      onTap: onAddPhoto,
                      child: Container(
                        width: imgSize * 0.75,
                        height: imgSize,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.primary, size: isSmall ? 20 : 24),
                            const SizedBox(height: 2),
                            Text('Ещё', style: TextStyle(fontSize: isSmall ? 9 : 10, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PortfolioPhotoViewer(images: images, initialIndex: index))),
                    onLongPress: () => onRemovePhoto(images[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SmartImage(
                              imageUrl: images[index],
                              width: imgSize,
                              height: imgSize,
                              fit: BoxFit.cover,
                              placeholder: Container(width: imgSize, height: imgSize, color: AppColors.divider, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: Container(width: imgSize, height: imgSize, color: AppColors.divider, child: const Icon(Icons.broken_image)),
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: GestureDetector(
                              onTap: () => onRemovePhoto(images[index]),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                child: Icon(Icons.close, size: isSmall ? 10 : 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Полноэкранный просмотр фото портфолио
class _PortfolioPhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _PortfolioPhotoViewer({required this.images, required this.initialIndex});

  @override
  State<_PortfolioPhotoViewer> createState() => _PortfolioPhotoViewerState();
}

class _PortfolioPhotoViewerState extends State<_PortfolioPhotoViewer> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: SmartImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: const Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// MY REVIEWS SECTION — Отзывы обо мне (для мастера в своём профиле)
// ════════════════════════════════════════════════════════════════════════
class _MyReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final UserModel worker;
  final double hPad;
  final bool isSmall;
  final LocalizationProvider l10n;

  const _MyReviewsSection({
    required this.reviews,
    required this.worker,
    required this.hPad,
    required this.isSmall,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayReviews = sortedReviews.take(3).toList();
    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star_rounded, color: AppColors.warning, size: isSmall ? 20 : 22),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('profile_my_reviews'),
                        style: TextStyle(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: isSmall ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ...List.generate(5, (i) => Icon(
                            i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: isSmall ? 14 : 16,
                            color: AppColors.warning,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '(${reviews.length})',
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 13,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (reviews.length > 3)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsListScreen(user: worker, isClient: false, showName: true),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      l10n.tr('reviews_view_all'),
                      style: TextStyle(fontSize: isSmall ? 12 : 13, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 40, color: AppColors.lightSlate),
                      const SizedBox(height: 8),
                      Text(
                        l10n.tr('reviews_no_reviews'),
                        style: TextStyle(fontSize: isSmall ? 13 : 14, color: AppColors.slateGray),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayReviews.map((review) => _ReviewTile(
                review: review,
                isSmall: isSmall,
              )),

            if (reviews.length > 3) ...[
              const Divider(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewsListScreen(user: worker, isClient: false, showName: true),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    '${l10n.tr('reviews_view_all')} (${reviews.length})',
                    style: TextStyle(fontSize: isSmall ? 13 : 14, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final bool isSmall;

  const _ReviewTile({required this.review, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isSmall ? 16 : 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0] : '?',
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmall ? 13 : 14,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    Text(
                      '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}',
                      style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.lightSlate),
                    ),
                  ],
                ),
              ),
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: isSmall ? 14 : 16, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              color: AppColors.slateGray,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
