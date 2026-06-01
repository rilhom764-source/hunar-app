import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';

class ReviewsListScreen extends StatelessWidget {
  final UserModel worker;

  const ReviewsListScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(worker.id);

    // Sort reviews by date (newest first)
    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('reviews_list_title')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Worker summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    worker.fullName
                        .split(' ')
                        .map((n) => n.isNotEmpty ? n[0] : '')
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name + verified
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      worker.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    if (worker.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppColors.primary, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
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
                    Container(width: 1, height: 40, color: AppColors.divider),
                    _StatItem(
                      icon: Icons.check_circle_outline,
                      value: '${worker.tasksCompleted}',
                      label: l10n.tr('profile_tasks_completed'),
                      color: AppColors.success,
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    _StatItem(
                      icon: Icons.rate_review_outlined,
                      value: '${reviews.length}',
                      label: l10n.tr('profile_reviews'),
                      color: AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reviews list
          if (sortedReviews.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: AppColors.lightSlate,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('reviews_no_reviews'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedReviews.length,
                itemBuilder: (context, index) {
                  final review = sortedReviews[index];
                  return _ReviewCard(review: review, l10n: l10n);
                },
              ),
            ),
        ],
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
        Icon(icon, color: color, size: 22),
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.slateGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final LocalizationProvider l10n;

  const _ReviewCard({
    required this.review,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightSlate.withValues(alpha: 0.3),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0] : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightSlate,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Review comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slateGray,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
