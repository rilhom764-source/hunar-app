import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';
import 'reviews_list_screen.dart';

/// Универсальный экран публичного профиля (как YouDo)
/// Показывает профиль любого пользователя — мастера или заказчика
/// с отзывами, рейтингом, статистикой, портфолио
class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(user.id);
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;

    // Calculate stats
    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : user.rating;
    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ══════════════════════════════════
          // APP BAR with gradient
          // ══════════════════════════════════
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: isSmall ? 36 : 42,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                user.fullName
                                    .split(' ')
                                    .map((n) => n.isNotEmpty ? n[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: isSmall ? 22 : 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, color: Colors.white, size: 18),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.city,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.isMasterVerified
                                          ? l10n.tr('public_profile_master')
                                          : l10n.tr('public_profile_client'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ══════════════════════════════════
          // STATS CARD
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    icon: Icons.star_rounded,
                    value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                    label: l10n.tr('public_profile_rating'),
                    color: AppColors.warning,
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatColumn(
                    icon: Icons.check_circle_outline,
                    value: '${user.tasksCompleted}',
                    label: l10n.tr('public_profile_completed'),
                    color: AppColors.success,
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatColumn(
                    icon: Icons.rate_review_outlined,
                    value: '${reviews.length}',
                    label: l10n.tr('public_profile_reviews'),
                    color: AppColors.info,
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatColumn(
                    icon: Icons.calendar_today_rounded,
                    value: _memberSince(user.createdAt),
                    label: l10n.tr('public_profile_member'),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════
          // BIO
          // ══════════════════════════════════
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tr('public_profile_about'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slateGray,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ══════════════════════════════════
          // SKILLS (if master)
          // ══════════════════════════════════
          if (user.skills.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build_circle_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tr('public_profile_skills'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // ══════════════════════════════════
          // PORTFOLIO (if has images)
          // ══════════════════════════════════
          if (user.portfolioImages.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.tr('public_profile_portfolio'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: user.portfolioImages.length,
                        itemBuilder: (context, i) => Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.background,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              user.portfolioImages[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: AppColors.lightSlate,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ══════════════════════════════════
          // REVIEWS SECTION (YouDo style)
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        l10n.tr('public_profile_reviews_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSlate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (reviews.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (reviews.length > 3)
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewsListScreen(user: user, isClient: false, showName: true),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: Text(
                            l10n.tr('reviews_view_all'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),

                  // Rating breakdown (YouDo style)
                  if (reviews.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _RatingBreakdown(reviews: reviews),
                  ],

                  const Divider(height: 28),

                  // Reviews list
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: AppColors.lightSlate),
                            const SizedBox(height: 12),
                            Text(
                              l10n.tr('reviews_no_reviews'),
                              style: const TextStyle(fontSize: 14, color: AppColors.slateGray),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...sortedReviews.take(5).map((review) => _ReviewItem(review: review)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  String _memberSince(DateTime date) {
    final months = DateTime.now().difference(date).inDays ~/ 30;
    if (months < 1) return '<1 мес';
    if (months < 12) return '$months мес';
    final years = months ~/ 12;
    return '$years г.';
  }
}

// ══════════════════════════════════════════════════════
// STAT COLUMN
// ══════════════════════════════════════════════════════
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.slateGray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// RATING BREAKDOWN (5 stars bar like YouDo)
// ══════════════════════════════════════════════════════
class _RatingBreakdown extends StatelessWidget {
  final List<ReviewModel> reviews;

  const _RatingBreakdown({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(5, 0);
    for (final r in reviews) {
      final idx = r.rating.round().clamp(1, 5) - 1;
      counts[idx]++;
    }
    final total = reviews.length;

    return Row(
      children: [
        // Left side — overall rating
        Column(
          children: [
            Text(
              (reviews.map((r) => r.rating).reduce((a, b) => a + b) / total).toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.deepSlate,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / total;
                return Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$total отз.',
              style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Right side — bar breakdown
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final starNum = 5 - i;
              final count = counts[starNum - 1];
              final pct = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$starNum',
                      style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// REVIEW ITEM (like YouDo review card)
// ══════════════════════════════════════════════════════
class _ReviewItem extends StatelessWidget {
  final ReviewModel review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.lightSlate),
                    ),
                  ],
                ),
              ),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slateGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
