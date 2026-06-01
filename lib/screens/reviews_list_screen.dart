import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';

/// Универсальный экран списка отзывов — работает для мастера и заказчика
/// [isClient] — если true, показывает синюю тему заказчика, иначе зелёную мастера
/// [showName] — если false, имя скрыто (до принятия заявки — имя анонимно)
class ReviewsListScreen extends StatelessWidget {
  final UserModel user;
  final bool isClient;
  final bool showName;

  const ReviewsListScreen({
    super.key,
    required this.user,
    this.isClient = false,
    this.showName = true,
  });

  // Фабричный конструктор для обратной совместимости (старый код передавал worker:)
  const ReviewsListScreen.worker({super.key, required UserModel worker})
      : user = worker,
        isClient = false,
        showName = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(user.id);

    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : user.rating;

    // Цветовая тема: синяя для заказчика, зелёная для мастера
    final themeColor = isClient ? const Color(0xFF1976D2) : AppColors.primary;
    final gradientColors = isClient
        ? const [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)]
        : AppColors.headerGradient;

    final roleLabel = isClient ? 'Заказчик' : 'Мастер';
    final displayName = showName ? user.fullName : roleLabel;
    final initials = showName
        ? user.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : (isClient ? '?' : 'М');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          showName
              ? 'Отзывы о ${user.fullName.split(' ').first}'
              : (isClient ? 'Отзывы о заказчике' : 'Отзывы о мастере'),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ══════════════════════════════
          // ШАПКА с аватаром и рейтингом
          // ══════════════════════════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                // Аватар
                CircleAvatar(
                  radius: 38,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Имя + бейдж роли
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    if (showName && user.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified, color: themeColor, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Статистика: рейтинг | выполнено | отзывов
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.star_rounded,
                      value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                      label: 'Рейтинг',
                      color: AppColors.warning,
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    _StatItem(
                      icon: Icons.check_circle_outline,
                      value: '${user.tasksCompleted}',
                      label: isClient ? 'Заказов' : 'Выполнено',
                      color: AppColors.success,
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    _StatItem(
                      icon: Icons.rate_review_outlined,
                      value: '${reviews.length}',
                      label: 'Отзывов',
                      color: themeColor,
                    ),
                  ],
                ),

                // Визуальная шкала звёзд
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RatingBreakdown(reviews: reviews, themeColor: themeColor),
                ],
              ],
            ),
          ),

          // ══════════════════════════════
          // СПИСОК ОТЗЫВОВ
          // ══════════════════════════════
          if (sortedReviews.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review_outlined, size: 64, color: AppColors.lightSlate),
                    const SizedBox(height: 16),
                    Text(
                      'Отзывов пока нет',
                      style: const TextStyle(fontSize: 16, color: AppColors.slateGray),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isClient
                          ? 'Мастера ещё не оставляли отзывов\nоб этом заказчике'
                          : 'Заказчики ещё не оставляли отзывов\nоб этом мастере',
                      style: const TextStyle(fontSize: 13, color: AppColors.lightSlate, height: 1.5),
                      textAlign: TextAlign.center,
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
                  return _ReviewCard(review: sortedReviews[index], themeColor: themeColor);
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Шкала разбивки рейтинга (5★ / 4★ / ...)
// ══════════════════════════════════════════════════
class _RatingBreakdown extends StatelessWidget {
  final List<ReviewModel> reviews;
  final Color themeColor;

  const _RatingBreakdown({required this.reviews, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(5, 0);
    for (final r in reviews) {
      final idx = (r.rating.round() - 1).clamp(0, 4);
      counts[idx]++;
    }
    final total = reviews.length;
    final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / total;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Большой рейтинг
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: themeColor,
                height: 1.0,
              ),
            ),
            Row(
              children: List.generate(5, (i) => Icon(
                i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: AppColors.warning,
              )),
            ),
            const SizedBox(height: 4),
            Text(
              '$total отзывов',
              style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Полоски по звёздам
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = counts[star - 1];
              final frac = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star', style: const TextStyle(fontSize: 12, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      child: Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.lightSlate)),
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

// ══════════════════════════════════════════════════
// Статистика (иконка + число + подпись)
// ══════════════════════════════════════════════════
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// Карточка одного отзыва
// ══════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final Color themeColor;

  const _ReviewCard({required this.review, required this.themeColor});

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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар автора отзыва
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightSlate.withValues(alpha: 0.25),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}',
                      style: const TextStyle(fontSize: 12, color: AppColors.lightSlate),
                    ),
                  ],
                ),
              ),
              // Оценка
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}
