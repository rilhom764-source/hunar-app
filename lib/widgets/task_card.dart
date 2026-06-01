import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/task_model.dart';
import '../utils/geo_utils.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final double? distance;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TaskCard({
    super.key,
    required this.task,
    this.distance,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon with gradient background
                    Container(
                      width: isSmall ? 48 : 54,
                      height: isSmall ? 48 : 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.08)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(task.categoryIcon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(fontSize: isSmall ? 15 : 17, fontWeight: FontWeight.w600, color: AppColors.deepSlate, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(task.clientName, style: const TextStyle(fontSize: 14, color: AppColors.slateGray)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: task.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 14, color: AppColors.slateGray, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                // Bottom row
                Row(
                  children: [
                    // Budget with vivid color
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${task.budget.toInt()} TJS',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.lightSlate),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(task.location, style: const TextStyle(fontSize: 13, color: AppColors.lightSlate), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 14, color: AppColors.info),
                            const SizedBox(width: 3),
                            Text(GeoUtils.formatDistance(distance!), style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(Icons.people_outline, size: 18, color: AppColors.lightSlate),
                    const SizedBox(width: 3),
                    Text('${task.bidsCount}', style: const TextStyle(fontSize: 13, color: AppColors.lightSlate, fontWeight: FontWeight.w500)),
                    if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                    if (task.voiceMessageUrl != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.mic, size: 18, color: AppColors.warning),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.open:
        color = AppColors.statusOpen;
        label = 'Open';
        break;
      case TaskStatus.inProgress:
        color = AppColors.statusInProgress;
        label = 'In Progress';
        break;
      case TaskStatus.completed:
        color = AppColors.statusCompleted;
        label = 'Done';
        break;
      case TaskStatus.cancelled:
        color = AppColors.statusCancelled;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
