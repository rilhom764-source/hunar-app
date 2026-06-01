import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/network_image_widget.dart';
import 'messages_screen.dart';
import 'reviews_list_screen.dart';

/// Профиль заказчика — открывается мастеру ТОЛЬКО после принятия заявки
/// YouDo-стиль с синей темой
class ClientProfileScreen extends StatelessWidget {
  final UserModel client;
  final TaskModel? relatedTask;

  const ClientProfileScreen({
    super.key,
    required this.client,
    this.relatedTask,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(client.id);
    final sorted = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final avg = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : client.rating;

    final clientTasks = state.tasks.where((t) => t.clientId == client.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final completedCount = clientTasks.where((t) => t.status == TaskStatus.completed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: CustomScrollView(
        slivers: [
          // ─── HERO HEADER (синяя тема) ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0D47A1),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _ClientHeroHeader(
                client: client,
                avg: avg,
                reviewCount: reviews.length,
              ),
            ),
          ),

          // ─── БАННЕР "ЗАЯВКА ПРИНЯТА" ──────────────────────────────────
          SliverToBoxAdapter(
            child: _AcceptedBanner(),
          ),

          // ─── СТАТИСТИКА ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ClientStats(
              avg: avg,
              totalTasks: clientTasks.length,
              completedTasks: completedCount,
              reviewCount: reviews.length,
              joinDate: client.createdAt,
            ),
          ),

          // ─── О СЕБЕ ───────────────────────────────────────────────────
          if (client.bio != null && client.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: _ClientSection(
                icon: Icons.format_quote_rounded,
                title: 'О заказчике',
                iconColor: const Color(0xFF1976D2),
                child: Text(
                  client.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slateGray,
                    height: 1.6,
                  ),
                ),
              ),
            ),

          // ─── ИСТОРИЯ ЗАКАЗОВ ──────────────────────────────────────────
          if (clientTasks.isNotEmpty)
            SliverToBoxAdapter(
              child: _ClientSection(
                icon: Icons.assignment_rounded,
                title: 'Заказы',
                iconColor: const Color(0xFF1976D2),
                trailing: Text(
                  '${clientTasks.length} всего',
                  style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                ),
                child: Column(
                  children: clientTasks
                      .take(4)
                      .map((t) => _TaskRow(task: t))
                      .toList(),
                ),
              ),
            ),

          // ─── ОТЗЫВЫ ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ClientReviewsSection(
              reviews: sorted,
              avg: avg,
              client: client,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ─── STICKY КНОПКА ────────────────────────────────────────────────
      bottomNavigationBar: _BottomChatBar(
        name: client.fullName.split(' ').first,
        onTap: () => _openChat(context, state),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, AppStateProvider state) async {
    final chatId = await state.getOrCreateFirestoreChat(
      participantId: client.id,
      participantName: client.fullName,
      taskId: relatedTask?.id ?? '',
      taskTitle: relatedTask?.title ?? '',
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
class _ClientHeroHeader extends StatelessWidget {
  final UserModel client;
  final double avg;
  final int reviewCount;

  const _ClientHeroHeader({
    required this.client,
    required this.avg,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final initials = client.fullName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Аватар
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: client.avatarUrl != null &&
                              client.avatarUrl!.isNotEmpty
                          ? smartImageProvider(client.avatarUrl!)
                          : null,
                      child: client.avatarUrl == null || client.avatarUrl!.isEmpty
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Badge(
                              icon: Icons.person_rounded,
                              label: 'Заказчик',
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            if (client.city.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _Badge(
                                icon: Icons.location_on_rounded,
                                label: client.city,
                                color: Colors.white.withValues(alpha: 0.13),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
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

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

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

// ─── БАННЕР "ЗАЯВКА ПРИНЯТА" ───────────────────────────────────────────────────
class _AcceptedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.12),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_rounded,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ваша заявка принята!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Профиль и контакты заказчика открыты',
                  style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}

// ─── СТАТИСТИКА ЗАКАЗЧИКА ─────────────────────────────────────────────────────
class _ClientStats extends StatelessWidget {
  final double avg;
  final int totalTasks;
  final int completedTasks;
  final int reviewCount;
  final DateTime joinDate;

  const _ClientStats({
    required this.avg,
    required this.totalTasks,
    required this.completedTasks,
    required this.reviewCount,
    required this.joinDate,
  });

  @override
  Widget build(BuildContext context) {
    final months = DateTime.now().difference(joinDate).inDays ~/ 30;
    final memberStr = months < 12 ? '$months мес.' : '${months ~/ 12} г.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _CStat(
            icon: Icons.star_rounded,
            value: avg > 0 ? avg.toStringAsFixed(1) : '—',
            label: 'Рейтинг',
            color: const Color(0xFFF59E0B),
          ),
          _CDivider(),
          _CStat(
            icon: Icons.assignment_rounded,
            value: '$totalTasks',
            label: 'Заказов',
            color: const Color(0xFF1976D2),
          ),
          _CDivider(),
          _CStat(
            icon: Icons.check_circle_rounded,
            value: '$completedTasks',
            label: 'Выполнено',
            color: AppColors.success,
          ),
          _CDivider(),
          _CStat(
            icon: Icons.calendar_month_rounded,
            value: memberStr,
            label: 'На платформе',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _CDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: const Color(0xFFE8EEF8));
}

class _CStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CStat({
    required this.icon,
    required this.value,
    required this.label,
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

// ─── СЕКЦИЯ С КАРТОЧКОЙ ───────────────────────────────────────────────────────
class _ClientSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  const _ClientSection({
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

// ─── СТРОКА ЗАДАНИЯ ────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final TaskModel task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final statusColor = task.status == TaskStatus.completed
        ? AppColors.success
        : task.status == TaskStatus.inProgress
            ? AppColors.warning
            : task.status == TaskStatus.open
                ? const Color(0xFF1976D2)
                : AppColors.slateGray;

    final statusLabel = task.status == TaskStatus.completed
        ? 'Завершён'
        : task.status == TaskStatus.inProgress
            ? 'В работе'
            : task.status == TaskStatus.open
                ? 'Открыт'
                : 'Отменён';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF7)),
      ),
      child: Row(
        children: [
          Text(task.categoryIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${task.budget.toInt()} TJS · ${task.location}',
                  style: const TextStyle(fontSize: 11, color: AppColors.slateGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── БЛОК ОТЗЫВОВ О ЗАКАЗЧИКЕ ─────────────────────────────────────────────────
class _ClientReviewsSection extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double avg;
  final UserModel client;

  const _ClientReviewsSection({
    required this.reviews,
    required this.avg,
    required this.client,
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
                  child: const Icon(Icons.star_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Отзывы о заказчике',
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
                          user: client,
                          isClient: true,
                          showName: true,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.07),
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
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Color(0xFF1976D2)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (reviews.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _ClientRatingBreakdown(reviews: reviews, avg: avg),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 28, color: Color(0xFFEAF0F8)),
          ),

          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined,
                      size: 44,
                      color: AppColors.lightSlate.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  const Text(
                    'Отзывов пока нет',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slateGray,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Отзывы появятся после выполнения заказов',
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
                  const Divider(height: 16, color: Color(0xFFEAF0F8)),
              itemBuilder: (_, i) => _ClientReviewTile(review: preview[i]),
            ),

          if (reviews.length > 3)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsListScreen(
                    user: client,
                    isClient: true,
                    showName: true,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Читать все отзывы',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Color(0xFF1976D2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientRatingBreakdown extends StatelessWidget {
  final List<ReviewModel> reviews;
  final double avg;

  const _ClientRatingBreakdown({required this.reviews, required this.avg});

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
                  i < avg.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 15,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('$total отз.',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.slateGray)),
          ],
        ),
        const SizedBox(width: 20),
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
                    Text('$star',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slateGray)),
                    const SizedBox(width: 3),
                    const Icon(Icons.star_rounded,
                        size: 11, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFEAF0F8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1976D2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.slateGray),
                          textAlign: TextAlign.end),
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

class _ClientReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ClientReviewTile({required this.review});

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
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                backgroundImage: (review.reviewerAvatar != null &&
                        review.reviewerAvatar!.isNotEmpty)
                    ? NetworkImage(review.reviewerAvatar!)
                    : null,
                child: (review.reviewerAvatar == null ||
                        review.reviewerAvatar!.isEmpty)
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1976D2),
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
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
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
                style:
                    const TextStyle(fontSize: 11, color: AppColors.lightSlate),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FB),
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
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ─── НИЖНЯЯ ПАНЕЛЬ ЧАТА ───────────────────────────────────────────────────────
class _BottomChatBar extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _BottomChatBar({required this.name, required this.onTap});

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
        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
        label: Text(
          'Написать $name',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
