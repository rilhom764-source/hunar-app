import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';
import 'messages_screen.dart';

/// Экран профиля заказчика — доступен мастеру ТОЛЬКО после принятия его заявки
/// Показывает: аватар, имя, рейтинг, историю заказов, отзывы + кнопку "Написать"
class ClientProfileScreen extends StatelessWidget {
  final UserModel client;
  final TaskModel? relatedTask; // задача по которой принята заявка (для чата)

  const ClientProfileScreen({
    super.key,
    required this.client,
    this.relatedTask,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final reviews = state.getReviewsForUser(client.id);

    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : client.rating;

    final sortedReviews = List<ReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Количество заказов клиента
    final clientTasks = state.tasks.where((t) => t.clientId == client.id).toList();
    final completedTasks = clientTasks.where((t) => t.status == TaskStatus.completed).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ══════════════════════════════════
          // HERO APP BAR — синяя тема (заказчик)
          // ══════════════════════════════════
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
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
                            // Аватар
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                child: Text(
                                  client.fullName
                                      .split(' ')
                                      .map((n) => n.isNotEmpty ? n[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  // Бейдж "Заказчик"
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_rounded, size: 13, color: Colors.white),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'Заказчик',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                                      const SizedBox(width: 4),
                                      Text(
                                        client.city,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withValues(alpha: 0.85),
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
              ),
            ),
          ),

          // ══════════════════════════════════
          // БАННЕР: "Вы работаете с этим заказчиком"
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.12),
                    AppColors.success.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_rounded, color: AppColors.success, size: 20),
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
                          'Профиль заказчика открыт для вас',
                          style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════
          // СТАТИСТИКА
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.star_rounded,
                    value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                    label: 'Рейтинг',
                    color: AppColors.warning,
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatItem(
                    icon: Icons.assignment_rounded,
                    value: '${clientTasks.length}',
                    label: 'Заказов',
                    color: const Color(0xFF1976D2),
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatItem(
                    icon: Icons.check_circle_rounded,
                    value: '$completedTasks',
                    label: 'Выполнено',
                    color: AppColors.success,
                  ),
                  Container(width: 1, height: 44, color: AppColors.divider),
                  _StatItem(
                    icon: Icons.rate_review_rounded,
                    value: '${reviews.length}',
                    label: 'Отзывов',
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════
          // КНОПКА "НАПИСАТЬ ЗАКАЗЧИКУ"
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context, state, l10n),
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text(
                  'Написать заказчику',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ),

          // ══════════════════════════════════
          // О ЗАКАЗЧИКЕ (bio)
          // ══════════════════════════════════
          if (client.bio != null && client.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Color(0xFF1976D2)),
                        SizedBox(width: 8),
                        Text(
                          'О заказчике',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      client.bio!,
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
          // АКТИВНЫЕ ЗАКАЗЫ КЛИЕНТА
          // ══════════════════════════════════
          if (clientTasks.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF1976D2)),
                    SizedBox(width: 8),
                    Text(
                      'Заказы этого клиента',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = clientTasks[index];
                  return _ClientTaskTile(task: task, l10n: l10n);
                },
                childCount: clientTasks.length > 5 ? 5 : clientTasks.length,
              ),
            ),
          ],

          // ══════════════════════════════════
          // ОТЗЫВЫ О ЗАКАЗЧИКЕ
          // ══════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.star_half_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Отзывы о заказчике',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepSlate,
                      ),
                    ),
                  ),
                  if (reviews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            '${avgRating.toStringAsFixed(1)} · ${reviews.length} отз.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (sortedReviews.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _EmptyReviews(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ReviewCard(review: sortedReviews[index]),
                childCount: sortedReviews.length > 5 ? 5 : sortedReviews.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),

      // ══════════════════════════════════
      // НИЖНЯЯ КНОПКА "НАПИСАТЬ"
      // ══════════════════════════════════
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _openChat(context, state, l10n),
          icon: const Icon(Icons.send_rounded, size: 20),
          label: Text(
            'Написать ${client.fullName.split(' ').first}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, AppStateProvider state, LocalizationProvider l10n) async {
    final chatId = await state.getOrCreateFirestoreChat(
      participantId: client.id,
      participantName: client.fullName,
      taskId: relatedTask?.id ?? '',
      taskTitle: relatedTask?.title ?? '',
    );
    if (chatId.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FirestoreChatDetailScreen(chatId: chatId),
        ),
      );
    }
  }
}

// ══════════════════════════════════
// Виджет статистики
// ══════════════════════════════════
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
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
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

// ══════════════════════════════════
// Тайл задачи клиента
// ══════════════════════════════════
class _ClientTaskTile extends StatelessWidget {
  final TaskModel task;
  final LocalizationProvider l10n;

  const _ClientTaskTile({required this.task, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final statusColor = task.status == TaskStatus.completed
        ? AppColors.success
        : task.status == TaskStatus.inProgress
            ? AppColors.info
            : task.status == TaskStatus.open
                ? AppColors.primary
                : AppColors.slateGray;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(task.categoryIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.budget.toInt()} TJS · ${task.location}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.tr('task_status_${task.status.name}'),
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

// ══════════════════════════════════
// Карточка отзыва
// ══════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _StarRow(rating: review.rating.toInt()),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.lightSlate),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
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
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ══════════════════════════════════
// Звёздочки рейтинга
// ══════════════════════════════════
class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 14,
        color: AppColors.warning,
      )),
    );
  }
}

// ══════════════════════════════════
// Нет отзывов
// ══════════════════════════════════
class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 36, color: AppColors.lightSlate),
          SizedBox(height: 10),
          Text(
            'Отзывов пока нет',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slateGray,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Отзывы появятся после завершения заказов',
            style: TextStyle(fontSize: 12, color: AppColors.lightSlate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
