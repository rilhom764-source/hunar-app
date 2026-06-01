import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/network_image_widget.dart';
import 'messages_screen.dart';
import 'reviews_list_screen.dart';

/// Публичный профиль мастера — YouDo-style
/// Показывается: заказчику при просмотре откликов, всем при тапе на имя мастера
class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(user.id);
    final sorted = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final avg = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : user.rating;
    final isOwn = state.currentUser.id == user.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        slivers: [
          // ─── HERO HEADER ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primaryDark,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    ),
                    onPressed: () => _writeMessage(context, state),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: _HeroHeader(user: user, avg: avg, reviewCount: reviews.length),
            ),
          ),

          // ─── БЫСТРЫЕ СТАТЫ (YouDo-style) ───────────────────────────────
          SliverToBoxAdapter(
            child: _QuickStats(user: user, avg: avg, reviews: reviews),
          ),

          // ─── О СЕБЕ ────────────────────────────────────────────────────
          if (user.bio != null && user.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionCard(
                icon: Icons.format_quote_rounded,
                title: 'О себе',
                iconColor: AppColors.primary,
                child: Text(
                  user.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slateGray,
                    height: 1.6,
                  ),
                ),
              ),
            ),

          // ─── НАВЫКИ ────────────────────────────────────────────────────
          if (user.skills.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Специализация',
                iconColor: const Color(0xFF7C3AED),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills
                      .map((s) => _SkillChip(label: s))
                      .toList(),
                ),
              ),
            ),

          // ─── ПОРТФОЛИО ─────────────────────────────────────────────────
          if (user.portfolioImages.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionCard(
                icon: Icons.photo_library_rounded,
                title: 'Портфолио',
                iconColor: const Color(0xFFDB2777),
                trailing: Text(
                  '${user.portfolioImages.length} фото',
                  style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                ),
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: user.portfolioImages.length,
                    itemBuilder: (_, i) => _PortfolioThumb(
                      url: user.portfolioImages[i],
                    ),
                  ),
                ),
              ),
            ),

          // ─── РЕЙТИНГ И ОТЗЫВЫ ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ReviewsSection(
              reviews: sorted,
              avg: avg,
              user: user,
            ),
          ),

          // ─── КНОПКА "НАПИСАТЬ" СНИЗУ ───────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ─── BOTTOM STICKY ACTION ──────────────────────────────────────────
      bottomNavigationBar: !isOwn
          ? _BottomAction(
              label: 'Написать ${user.fullName.split(' ').first}',
              color: AppColors.primary,
              icon: Icons.chat_bubble_rounded,
              onTap: () => _writeMessage(context, state),
            )
          : null,
    );
  }

  void _writeMessage(BuildContext context, AppStateProvider state) async {
    final chatId = await state.getOrCreateFirestoreChat(
      participantId: user.id,
      participantName: user.fullName,
      taskId: '',
      taskTitle: '',
    );
    if (chatId.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FirestoreChatDetailScreen(chatId: chatId)),
      );
    }
  }
}

// ─── HERO HEADER ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final UserModel user;
  final double avg;
  final int reviewCount;

  const _HeroHeader({
    required this.user,
    required this.avg,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D2E), Color(0xFF00875A), Color(0xFF00C97B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Аватар с рамкой
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? smartImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Имя + роль + город
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isMasterVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 12),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Бейджи
                        Row(
                          children: [
                            _HeaderBadge(
                              icon: Icons.handyman_rounded,
                              label: 'Мастер',
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                            if (user.city.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _HeaderBadge(
                                icon: Icons.location_on_rounded,
                                label: user.city,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Рейтинг строкой
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < avg.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 16,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              avg > 0
                                  ? '${avg.toStringAsFixed(1)}  ($reviewCount отз.)'
                                  : 'Нет отзывов',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
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
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── БЫСТРЫЕ СТАТЫ (4 блока) ──────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final UserModel user;
  final double avg;
  final List<ReviewModel> reviews;

  const _QuickStats({required this.user, required this.avg, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final memberMonths = DateTime.now().difference(user.createdAt).inDays ~/ 30;
    final memberStr = memberMonths < 12
        ? '$memberMonths мес.'
        : '${memberMonths ~/ 12} г.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatBox(
            value: avg > 0 ? avg.toStringAsFixed(1) : '—',
            label: 'Рейтинг',
            icon: Icons.star_rounded,
            color: const Color(0xFFF59E0B),
          ),
          _Divider(),
          _StatBox(
            value: '${user.tasksCompleted}',
            label: 'Выполнено',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          _Divider(),
          _StatBox(
            value: '${reviews.length}',
            label: 'Отзывов',
            icon: Icons.rate_review_rounded,
            color: AppColors.info,
          ),
          _Divider(),
          _StatBox(
            value: memberStr,
            label: 'На платформе',
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFFE8F5F0));
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

// ─── СЕКЦИЯ С КАРТОЧКОЙ ────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSlate,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── НАВЫК ────────────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── ПОРТФОЛИО ФОТО ───────────────────────────────────────────────────────────
class _PortfolioThumb extends StatelessWidget {
  final String url;

  const _PortfolioThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: Container(
        width: 110,
        height: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF0F7F4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded, color: AppColors.lightSlate, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── БЛОК ОТЗЫВОВ ─────────────────────────────────────────────────────────────
class _ReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double avg;
  final UserModel user;

  const _ReviewsSection({
    required this.reviews,
    required this.avg,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final preview = reviews.take(3).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Отзывы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSlate,
                  ),
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${avg.toStringAsFixed(1)} · ${reviews.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (reviews.length > 3)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewsListScreen(
                          user: user,
                          isClient: false,
                          showName: true,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Все ${reviews.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Разбивка по звёздам (если есть)
          if (reviews.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _RatingBreakdown(reviews: reviews, avg: avg),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 28, color: Color(0xFFEEF4F1)),
          ),

          // Список превью отзывов
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 44, color: AppColors.lightSlate.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  const Text(
                    'Отзывов пока нет',
                    style: TextStyle(fontSize: 14, color: AppColors.slateGray, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'После завершения заданий здесь появятся отзывы',
                    style: TextStyle(fontSize: 12, color: AppColors.lightSlate),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              itemCount: preview.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, color: Color(0xFFEEF4F1)),
              itemBuilder: (_, i) => _ReviewTile(review: preview[i]),
            ),

          // Кнопка "Читать все"
          if (reviews.length > 3)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsListScreen(
                    user: user,
                    isClient: false,
                    showName: true,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Читать все отзывы',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── РАЗБИВКА РЕЙТИНГА ────────────────────────────────────────────────────────
class _RatingBreakdown extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double avg;

  const _RatingBreakdown({required this.reviews, required this.avg});

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(5, 0);
    for (final r in reviews) {
      counts[r.rating.round().clamp(1, 5) - 1]++;
    }
    final total = reviews.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Большая цифра рейтинга
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppColors.deepSlate,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 15,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total отз.',
              style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Полосы
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = counts[star - 1];
              final pct = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateGray,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF0F4F2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct > 0.5
                                ? const Color(0xFF34D399)
                                : pct > 0.2
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
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

// ─── КАРТОЧКА ОТЗЫВА ──────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars = review.rating.round().clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар автора
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: (review.reviewerAvatar != null &&
                        review.reviewerAvatar!.isNotEmpty)
                    ? NetworkImage(review.reviewerAvatar!)
                    : null,
                child: (review.reviewerAvatar == null || review.reviewerAvatar!.isEmpty)
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 13,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(review.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.lightSlate),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGray,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} нед. назад';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ─── НИЖНЯЯ КНОПКА ДЕЙСТВИЯ ───────────────────────────────────────────────────
class _BottomAction extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _BottomAction({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}


