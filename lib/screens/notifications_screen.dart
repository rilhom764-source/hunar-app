import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/notification_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/confetti_celebration.dart';
import 'task_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final notifs = state.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('notifications_title')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (state.unreadNotificationCount > 0)
            TextButton(
              onPressed: () => state.markAllNotificationsRead(),
              child: Text(l10n.tr('notifications_mark_all_read'), style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.lightSlate),
                  const SizedBox(height: 12),
                  Text(l10n.tr('notifications_empty'), style: const TextStyle(color: AppColors.slateGray, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (ctx, i) {
                final n = notifs[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () {
                    state.markNotificationRead(n.id);
                    // 🎉 Show confetti for special notifications
                    if (!n.isRead) {
                      if (n.type == NotificationType.bidAccepted) {
                        ConfettiCelebration.show(context,
                            type: CelebrationType.bidAccepted);
                      } else if (n.type == NotificationType.taskCompleted) {
                        ConfettiCelebration.show(context,
                            type: CelebrationType.taskCompleted);
                      }
                    }
                    if (n.relatedTaskId != null) {
                      final task = state.getTaskById(n.relatedTaskId!);
                      if (task != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primary.withValues(alpha: 0.04) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(notification.iconEmoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.deepSlate,
                          ),
                        ),
                      ),
                      Text(timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.lightSlate)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 13, color: AppColors.slateGray, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newTask:
        return AppColors.primary;
      case NotificationType.newBid:
        return AppColors.info;
      case NotificationType.bidAccepted:
        return AppColors.success;
      case NotificationType.bidRejected:
        return AppColors.error;
      case NotificationType.taskCompleted:
        return AppColors.primary;
      case NotificationType.taskCancelled:
        return AppColors.error;
      case NotificationType.taskUpdate:
        return AppColors.info;
      case NotificationType.newReview:
        return AppColors.warning;
      case NotificationType.newMessage:
        return AppColors.info;
      case NotificationType.paymentReceived:
        return AppColors.primary;
      case NotificationType.taskAssigned:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.slateGray;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }
}
