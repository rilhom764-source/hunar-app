import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../models/bid_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/voice_message_player.dart';
import 'bid_screen.dart';
import 'payment_screen.dart';
import 'review_screen.dart';
import 'messages_screen.dart';
import 'public_profile_screen.dart';
import 'client_profile_screen.dart';
import 'reviews_list_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final bids = state.getBidsForTask(task.id);

    final currentTask = state.tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
    final isOwner = currentTask.clientId == state.currentUser.id;
    final isWorkerRole = state.isWorker;
    final canBid = isWorkerRole && !isOwner && currentTask.status == TaskStatus.open && !state.hasWorkerBidOnTask(task.id);
    final alreadyBid = isWorkerRole && state.hasWorkerBidOnTask(task.id);

    // Determine if review can be left
    final canReview = currentTask.status == TaskStatus.completed && !state.hasReviewedTask(currentTask.id);
    String? reviewTargetId;
    String? reviewTargetName;
    if (canReview) {
      if (isOwner && currentTask.assignedWorkerId != null) {
        reviewTargetId = currentTask.assignedWorkerId;
        final worker = state.workers.where((w) => w.id == currentTask.assignedWorkerId).toList();
        reviewTargetName = worker.isNotEmpty ? worker.first.fullName : 'Worker';
      } else if (!isOwner) {
        reviewTargetId = currentTask.clientId;
        reviewTargetName = currentTask.clientName;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('task_detail_title')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Favorite
          IconButton(
            onPressed: () => state.toggleFavoriteTask(currentTask.id),
            icon: Icon(
              state.isTaskFavorite(currentTask.id) ? Icons.bookmark_rounded : Icons.bookmark_outline,
              color: state.isTaskFavorite(currentTask.id) ? AppColors.warning : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (isOwner && currentTask.status == TaskStatus.open)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _showDeleteDialog(context, state, l10n);
                if (value == 'cancel') {
                  state.cancelTask(currentTask.id);
                  Navigator.pop(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'cancel', child: Row(children: [const Icon(Icons.cancel_outlined, color: AppColors.warning), const SizedBox(width: 8), Text(l10n.tr('task_cancel'))])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: AppColors.error), const SizedBox(width: 8), Text(l10n.tr('task_delete'), style: const TextStyle(color: AppColors.error))])),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: _statusColor(currentTask.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(l10n.tr('task_status_${currentTask.status.name}'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _statusColor(currentTask.status))),
                      ),
                      const SizedBox(width: 8),
                      Text(currentTask.categoryIcon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(l10n.tr('category_${currentTask.category.name}'), style: const TextStyle(fontSize: 14, color: AppColors.slateGray)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(currentTask.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepSlate, height: 1.3)),
                  const SizedBox(height: 12),
                  Text(currentTask.description, style: const TextStyle(fontSize: 15, color: AppColors.slateGray, height: 1.6)),
                  
                  // 📸 Фото заказа
                  if (currentTask.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 16, color: AppColors.slateGray),
                        const SizedBox(width: 6),
                        Text(
                          'Фото (${currentTask.imageUrls.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentTask.imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, currentTask.imageUrls, index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _SmartTaskImage(
                                  imageUrl: currentTask.imageUrls[index],
                                  width: 110,
                                  height: 110,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // 🎤 Голосовое сообщение
                  if (currentTask.voiceMessageUrl != null && currentTask.voiceMessageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.mic_outlined, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        const Text(
                          'Голосовое сообщение',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    VoiceMessagePlayer(voiceUrl: currentTask.voiceMessageUrl!),
                  ],

                  // Chat with client button (for workers on active/completed tasks)
                  if (!isOwner && (currentTask.status == TaskStatus.inProgress || currentTask.status == TaskStatus.completed)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final chatId = await state.getOrCreateFirestoreChat(
                            participantId: currentTask.clientId,
                            participantName: currentTask.clientName,
                            taskId: currentTask.id,
                            taskTitle: currentTask.title,
                          );
                          if (chatId.isNotEmpty && context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FirestoreChatDetailScreen(chatId: chatId)));
                          }
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(l10n.tr('task_detail_chat_client')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Info cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _InfoCard(icon: Icons.payments_outlined, label: l10n.tr('task_detail_budget'), value: '${currentTask.budget.toInt()} TJS', color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _InfoCard(icon: Icons.calendar_today_outlined, label: l10n.tr('task_detail_deadline'), value: '${currentTask.deadline.day}.${currentTask.deadline.month}.${currentTask.deadline.year}', color: AppColors.info)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InfoCard(icon: Icons.location_on_outlined, label: l10n.tr('task_detail_location'), value: currentTask.location, color: AppColors.error, fullWidth: true),
            ),

            // Блок заказчика — виден ВСЕМ мастерам, но с разным уровнем доступа:
            // • Все мастера → рейтинг + кол-во отзывов (без имени, без профиля)
            // • Заявка принята → полный профиль + кнопка "Написать"
            if (!isOwner) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _isWorkerAccepted(currentTask, state, bids)
                    ? _ClientProfileCard(task: currentTask, state: state, l10n: l10n)
                    : _ClientRatingCard(task: currentTask, state: state),
              ),
            ],

            // Worker (master) action buttons — process steps
            if (!isOwner && currentTask.status == TaskStatus.inProgress && currentTask.assignedWorkerId == state.currentUser.id) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _WorkerProcessButtons(
                  task: currentTask,
                  state: state,
                  l10n: l10n,
                ),
              ),
            ],

            // Owner actions
            if (isOwner && currentTask.status == TaskStatus.inProgress) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.advanceTaskStatus(currentTask.id);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(task: currentTask)));
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(l10n.tr('task_complete_and_pay')),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: AppColors.success),
                ),
              ),
            ],

            // Review prompt
            if (canReview && reviewTargetId != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l10n.tr('review_prompt'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepSlate)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(task: currentTask, targetUserId: reviewTargetId!, targetUserName: reviewTargetName!))),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: Text(l10n.tr('review_leave')),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cancel task button for owner on open tasks
            if (isOwner && currentTask.status == TaskStatus.open)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    state.cancelTask(currentTask.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.tr('task_cancel')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),

            // Bids section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(l10n.tr('task_detail_bids'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('${bids.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],
              ),
            ),

            if (bids.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.how_to_vote_outlined, size: 48, color: AppColors.lightSlate),
                      const SizedBox(height: 8),
                      Text(l10n.tr('task_detail_no_bids'), style: const TextStyle(color: AppColors.slateGray), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              ...bids.map((bid) => _BidCard(
                    bid: bid,
                    isOwner: isOwner,
                    isTaskOpen: currentTask.status == TaskStatus.open,
                    onAccept: () => _showAcceptBidDialog(context, state, l10n, currentTask, bid),
                    onReject: () => state.rejectBid(currentTask.id, bid.id),
                    onChat: () async {
                      final chatId = await state.getOrCreateFirestoreChat(
                        participantId: bid.workerId,
                        participantName: bid.workerName,
                        taskId: currentTask.id,
                        taskTitle: currentTask.title,
                      );
                      if (chatId.isNotEmpty && context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FirestoreChatDetailScreen(chatId: chatId)));
                      }
                    },
                    l10n: l10n,
                  )),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, state, l10n, currentTask, canBid, alreadyBid, isOwner),
    );
  }

  /// Нижние кнопки действий (отклик, завершение, подтверждение)
  Widget? _buildBottomActions(
    BuildContext context,
    AppStateProvider state,
    LocalizationProvider l10n,
    TaskModel currentTask,
    bool canBid,
    bool alreadyBid,
    bool isOwner,
  ) {
    // 1️⃣ Мастер может откликнуться
    if (canBid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BidScreen(task: currentTask))),
            icon: const Icon(Icons.gavel),
            label: Text(l10n.tr('task_detail_place_bid')),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ),
      );
    }

    // 2️⃣ Мастер уже откликнулся
    if (alreadyBid && currentTask.status == TaskStatus.open) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.tr('bid_success'),
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }


    return null;
  }



  /// Диалог выбора исполнителя (заказчик принимает отклик).
  /// После принятия заказ закрывается для остальных мастеров.
  void _showAcceptBidDialog(
    BuildContext context,
    AppStateProvider state,
    LocalizationProvider l10n,
    TaskModel task,
    BidModel bid,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.tr('accept_bid_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    bid.workerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bid.workerName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                  ),
                ),
                Text('${bid.amount.toInt()} TJS',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.tr('accept_bid_warning'),
                style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('common_cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              state.acceptBid(task.id, bid.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.tr('accept_bid_success')),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: Text(l10n.tr('bid_accept')),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppStateProvider state, LocalizationProvider l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tr('task_delete')),
        content: Text(l10n.tr('task_delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.tr('common_cancel'))),
          TextButton(
            onPressed: () {
              state.deleteTask(task.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(l10n.tr('common_delete'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // 📸 Показ полноэкранного просмотра фото
  void _showImageDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open: return AppColors.statusOpen;
      case TaskStatus.inProgress: return AppColors.statusInProgress;
      case TaskStatus.completed: return AppColors.statusCompleted;
      case TaskStatus.cancelled: return AppColors.statusCancelled;
    }
  }

  /// Проверяет: принята ли заявка текущего мастера на эту задачу?
  bool _isWorkerAccepted(TaskModel task, AppStateProvider state, List<BidModel> bids) {
    final myId = state.currentUser.id;
    // Вариант 1: задача уже назначена этому мастеру
    if (task.assignedWorkerId == myId) return true;
    // Вариант 2: есть принятая заявка от этого мастера
    return bids.any((b) => b.workerId == myId && b.status == BidStatus.accepted);
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _InfoCard({required this.icon, required this.label, required this.value, required this.color, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final bool isOwner;
  final bool isTaskOpen;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChat;
  final LocalizationProvider l10n;

  const _BidCard({required this.bid, required this.isOwner, required this.isTaskOpen, required this.onAccept, required this.onReject, required this.onChat, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateProvider>();
    final currentUserId = state.currentUser.id;

    // Заказчик видит имя/профиль мастера только после принятия его заявки
    final showIdentity = isOwner || bid.status == BidStatus.accepted;
    final displayName = showIdentity ? bid.workerName : 'Мастер';
    // Цену видит только заказчик и сам автор заявки
    final showPrice = isOwner || bid.workerId == currentUserId;

    // Данные о мастере для отзывов (видны ВСЕГДА заказчику)
    final workerUser = isOwner ? state.getUserById(bid.workerId) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Строка: аватар + имя/рейтинг + цена ──
            Row(
              children: [
                // Аватар
                GestureDetector(
                  onTap: showIdentity && workerUser != null ? () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(user: workerUser),
                    ));
                  } : null,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: showIdentity
                        ? Text(
                            bid.workerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          )
                        : const Icon(Icons.engineering_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя (или "Мастер")
                      GestureDetector(
                        onTap: showIdentity && workerUser != null ? () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(user: workerUser),
                          ));
                        } : null,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: showIdentity ? AppColors.primary : AppColors.deepSlate,
                            decoration: showIdentity ? TextDecoration.underline : null,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Рейтинг + кол-во отзывов — ВСЕГДА видно заказчику
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                          const SizedBox(width: 3),
                          Text(
                            bid.workerRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${bid.workerReviewsCount} ${_reviewWord(bid.workerReviewsCount)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Цена
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: showPrice
                      ? Text('${bid.amount.toInt()} TJS',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 13, color: AppColors.slateGray),
                            SizedBox(width: 4),
                            Text('···', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
                          ],
                        ),
                ),
              ],
            ),

            // ── Кнопка "Читать отзывы" — ВСЕГДА видна заказчику ──
            if (isOwner) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // Показать отзывы о мастере — имя скрыто если заявка не принята
                  if (workerUser != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ReviewsListScreen(
                        user: workerUser,
                        isClient: false,
                        showName: showIdentity,
                      ),
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 5),
                      Text(
                        bid.workerReviewsCount > 0
                            ? 'Читать ${bid.workerReviewsCount} ${_reviewWord(bid.workerReviewsCount)}'
                            : 'Отзывов пока нет',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.warning),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            // ── Сообщение мастера ──
            Text(bid.message, style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5)),
            const SizedBox(height: 8),

            // ── Нижняя строка: время + кнопки действий ──
            Row(
              children: [
                Icon(Icons.schedule, size: 15, color: AppColors.lightSlate),
                const SizedBox(width: 4),
                Text(bid.estimatedTime, style: const TextStyle(fontSize: 13, color: AppColors.slateGray)),
                const Spacer(),
                if (bid.status == BidStatus.accepted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(l10n.tr('bid_accepted'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_outlined, size: 20, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else if (bid.status == BidStatus.rejected)
                  Text(l10n.tr('bid_reject'), style: const TextStyle(fontSize: 12, color: AppColors.error))
                else if (isOwner && isTaskOpen) ...[
                  IconButton(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_outlined, size: 20, color: AppColors.info),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: Text(l10n.tr('bid_reject'), style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text(l10n.tr('bid_accept'), style: const TextStyle(fontSize: 12)),
                  ),
                ] else
                  Text(l10n.tr('bid_pending'), style: const TextStyle(fontSize: 12, color: AppColors.lightSlate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _reviewWord(int count) {
    if (count % 100 >= 11 && count % 100 <= 14) return 'отзывов';
    switch (count % 10) {
      case 1: return 'отзыв';
      case 2:
      case 3:
      case 4: return 'отзыва';
      default: return 'отзывов';
    }
  }
}

/// Smart image widget that handles both network URLs and Data URLs (base64)
class _SmartTaskImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const _SmartTaskImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:')) {
      return _buildDataUrlImage();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width, height: height,
        color: AppColors.divider,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildDataUrlImage() {
    try {
      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex == -1) return _buildErrorWidget();
      final base64Data = imageUrl.substring(commaIndex + 1);
      final bytes = base64Decode(base64Data);
      return Image.memory(
        Uint8List.fromList(bytes),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildErrorWidget(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('_SmartTaskImage: Error decoding data URL: $e');
      }
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width, height: height,
      color: AppColors.divider,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: AppColors.slateGray, size: 24),
          SizedBox(height: 4),
          Text('\u041e\u0448\u0438\u0431\u043a\u0430', style: TextStyle(fontSize: 10, color: AppColors.lightSlate)),
        ],
      ),
    );
  }
}

/// \u041f\u043e\u043b\u043d\u043e\u044d\u043a\u0440\u0430\u043d\u043d\u0430\u044f \u0433\u0430\u043b\u0435\u0440\u0435\u044f \u0438\u0437\u043e\u0431\u0440\u0430\u0436\u0435\u043d\u0438\u0439 \u0441 \u0437\u0443\u043c\u043e\u043c
class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildFullScreenImage(url),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullScreenImage(String imageUrl) {
    if (imageUrl.startsWith('data:')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex == -1) return _buildFullScreenError();
        final base64Data = imageUrl.substring(commaIndex + 1);
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => _buildFullScreenError(),
        );
      } catch (e) {
        return _buildFullScreenError();
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _buildFullScreenError(),
    );
  }

  Widget _buildFullScreenError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, color: Colors.white, size: 64),
        const SizedBox(height: 12),
        Text(
          'Не удалось загрузить фото',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
// CLIENT PROFILE CARD (for workers to see who posted the task)
// ══════════════════════════════════════════════════════
class _ClientProfileCard extends StatelessWidget {
  final TaskModel task;
  final AppStateProvider state;
  final LocalizationProvider l10n;

  const _ClientProfileCard({
    required this.task,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final clientId = task.clientId;
    final clientName = task.clientName;
    final clientUser = state.getUserById(clientId);
    final reviews = state.getReviewsForUser(clientId);
    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : 0.0;

    void openClientProfile() {
      if (clientUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientProfileScreen(
              client: clientUser,
              relatedTask: task,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.06),
            const Color(0xFF42A5F5).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Заголовок с бейджем "Доступ открыт"
          Row(
            children: [
              const Icon(Icons.lock_open_rounded, size: 15, color: Color(0xFF1976D2)),
              const SizedBox(width: 6),
              const Text(
                'Профиль заказчика',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1976D2),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Заявка принята',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Аватар + имя + рейтинг
          InkWell(
            onTap: openClientProfile,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.15),
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 13, color: AppColors.slateGray),
                          const SizedBox(width: 4),
                          const Text('Заказчик', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                          if (reviews.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              '${avgRating.toStringAsFixed(1)} (${reviews.length} отз.)',
                              style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            const Text('Нет отзывов', style: TextStyle(fontSize: 12, color: AppColors.lightSlate)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF1976D2), size: 22),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: openClientProfile,
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: const Text('Профиль'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: openClientProfile,
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Написать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Worker Process Buttons — "Начал работу" / "Завершил работу"
// ═══════════════════════════════════════════════════════════
class _WorkerProcessButtons extends StatelessWidget {
  final TaskModel task;
  final AppStateProvider state;
  final LocalizationProvider l10n;

  const _WorkerProcessButtons({
    required this.task,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bool workStarted = task.workStarted;

    // Find the accepted bid amount for this task
    final bids = state.getBidsForTask(task.id);
    final myBid = bids.where((b) => b.workerId == state.currentUser.id && b.status == BidStatus.accepted).toList();
    final double agreedAmount = myBid.isNotEmpty ? myBid.first.amount : task.budget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.engineering_rounded, size: 20, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tr('work_process_title'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
              // Show agreed amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${agreedAmount.toInt()} TJS',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress indicator
          _WorkProgressIndicator(workStarted: workStarted),
          const SizedBox(height: 16),

          // Buttons
          if (!workStarted) ...[
            // "Начал работу" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showConfirmDialog(
                    context,
                    title: l10n.tr('work_start_confirm_title'),
                    message: '${l10n.tr('work_start_confirm_msg')}\n\n${l10n.tr('work_amount_label')}: ${agreedAmount.toInt()} TJS',
                    onConfirm: () {
                      state.markWorkStarted(task.id);
                    },
                  );
                },
                icon: const Icon(Icons.play_circle_filled_rounded),
                label: Text(l10n.tr('work_start_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // "Завершил работу" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showConfirmDialog(
                    context,
                    title: l10n.tr('work_complete_confirm_title'),
                    message: '${l10n.tr('work_complete_confirm_msg')}\n\n${l10n.tr('work_amount_label')}: ${agreedAmount.toInt()} TJS',
                    onConfirm: () {
                      state.markWorkCompleted(task.id);
                    },
                  );
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(l10n.tr('work_complete_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.tr('confirm')),
          ),
        ],
      ),
    );
  }
}

class _WorkProgressIndicator extends StatelessWidget {
  final bool workStarted;

  const _WorkProgressIndicator({required this.workStarted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProgressStep(
          icon: Icons.assignment_turned_in_rounded,
          label: 'Принят',
          isActive: true,
          isCompleted: true,
        ),
        Expanded(child: _ProgressLine(isActive: workStarted)),
        _ProgressStep(
          icon: Icons.construction_rounded,
          label: 'В работе',
          isActive: workStarted,
          isCompleted: false,
        ),
        Expanded(child: _ProgressLine(isActive: false)),
        _ProgressStep(
          icon: Icons.check_circle_rounded,
          label: 'Готово',
          isActive: false,
          isCompleted: false,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive || isCompleted ? AppColors.info : AppColors.lightSlate;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppColors.info.withValues(alpha: 0.15)
                : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final bool isActive;

  const _ProgressLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.info : AppColors.background,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CLIENT RATING CARD — виден ВСЕМ мастерам (до принятия заявки)
// Показывает: аватар (анонимно) + рейтинг + кол-во отзывов + кнопка "Посмотреть отзывы"
// Имя, профиль и чат — скрыты до принятия заявки
// ══════════════════════════════════════════════════════════════
class _ClientRatingCard extends StatelessWidget {
  final TaskModel task;
  final AppStateProvider state;

  const _ClientRatingCard({required this.task, required this.state});

  @override
  Widget build(BuildContext context) {
    final clientUser = state.getUserById(task.clientId);
    final reviews = state.getReviewsForUser(task.clientId);
    final avgRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : (clientUser?.rating ?? 0.0);
    final starCount = avgRating.round().clamp(0, 5);

    // Склонение слова "отзыв"
    String reviewWord(int n) {
      if (n % 100 >= 11 && n % 100 <= 19) return 'отзывов';
      switch (n % 10) {
        case 1: return 'отзыв';
        case 2:
        case 3:
        case 4: return 'отзыва';
        default: return 'отзывов';
      }
    }

    void openReviews() {
      if (clientUser == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewsListScreen(
            user: clientUser,
            isClient: true,
            showName: false, // анонимно — имя скрыто до принятия заявки
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
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
          // ── Шапка: "Заказчик" ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 13, color: AppColors.info),
                    SizedBox(width: 4),
                    Text(
                      'Заказчик',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Замок — профиль закрыт
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'Профиль закрыт',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Основной блок: аватар + рейтинг + отзывы ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Анонимный аватар с фото если есть
              Stack(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: clientUser?.avatarUrl != null && clientUser!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              clientUser.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                size: 32,
                                color: Color(0xFF1976D2),
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: Color(0xFF1976D2),
                            ),
                    ),
                  ),
                  // Иконка замка поверх аватара
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 9, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Рейтинг
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: avgRating > 0 ? const Color(0xFFF59E0B) : AppColors.lightSlate,
                            height: 1.0,
                          ),
                        ),
                        if (avgRating > 0) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '/ 5',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Звёзды
                    Row(
                      children: List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          i < starCount ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 18,
                          color: const Color(0xFFF59E0B),
                        ),
                      )),
                    ),
                  ],
                ),
              ),

              // Вертикальный разделитель
              Container(width: 1, height: 52, color: AppColors.divider),
              const SizedBox(width: 16),

              // Количество отзывов
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${reviews.length}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: reviews.isNotEmpty ? AppColors.info : AppColors.lightSlate,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reviewWord(reviews.length),
                    style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                  ),
                ],
              ),
            ],
          ),

          // ── Кнопка "Посмотреть отзывы" (только если есть отзывы) ──
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openReviews,
                icon: const Icon(Icons.rate_review_outlined, size: 17),
                label: Text('Посмотреть все ${reviews.length} ${reviewWord(reviews.length)}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // ── Подсказка что откроется после принятия ──
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: AppColors.slateGray),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'После принятия вашей заявки откроется имя, профиль и чат',
                    style: TextStyle(fontSize: 11, color: AppColors.slateGray, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

