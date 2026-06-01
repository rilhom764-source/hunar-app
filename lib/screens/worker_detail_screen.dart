import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';
import 'reviews_list_screen.dart';

class WorkerDetailScreen extends StatelessWidget {
  final UserModel worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(worker.id);
    final distance = state.distanceToWorker(worker);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('profile_title')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      worker.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Name + verified
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSlate,
                        ),
                      ),
                      if (worker.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.primary, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${worker.city} • ${distance.toStringAsFixed(1)} ${l10n.tr('search_km')}',
                    style: const TextStyle(fontSize: 14, color: AppColors.slateGray),
                  ),
                  if (worker.bio != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      worker.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slateGray,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        icon: Icons.star_rounded,
                        value: worker.rating.toStringAsFixed(1),
                        label: l10n.tr('profile_rating'),
                        color: AppColors.warning,
                      ),
                      _StatItem(
                        icon: Icons.check_circle_outline,
                        value: '${worker.tasksCompleted}',
                        label: l10n.tr('profile_tasks_completed'),
                        color: AppColors.success,
                      ),
                      _StatItem(
                        icon: Icons.rate_review_outlined,
                        value: '${worker.reviewsCount}',
                        label: l10n.tr('profile_reviews'),
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Skills
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr('profile_skills'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: worker.skills.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Reviews
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.tr('profile_reviews'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepSlate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reviews.length})',
                        style: const TextStyle(color: AppColors.slateGray),
                      ),
                      const Spacer(),
                      if (reviews.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsListScreen(worker: worker),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(l10n.tr('reviews_view_all')),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.tr('search_no_results'),
                          style: const TextStyle(color: AppColors.slateGray),
                        ),
                      ),
                    )
                  else
                    ...reviews.map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                                radius: 16,
                                backgroundColor: AppColors.lightSlate.withValues(alpha: 0.3),
                                child: Text(
                                  review.reviewerName.isNotEmpty ? review.reviewerName[0] : '?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepSlate,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  review.reviewerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepSlate,
                                  ),
                                ),
                              ),
                              // Stars
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 16,
                                  color: AppColors.warning,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comment,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slateGray,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}',
                            style: const TextStyle(fontSize: 12, color: AppColors.lightSlate),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
        ),
      ],
    );
  }
}
