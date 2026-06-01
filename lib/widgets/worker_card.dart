import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../utils/geo_utils.dart';

class WorkerCard extends StatelessWidget {
  final UserModel worker;
  final double? distance;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        worker.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.fullName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (worker.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Skills chips with color
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: worker.skills.take(3).map((skill) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.accent.withValues(alpha: 0.06)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          // Rating with star
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                const SizedBox(width: 2),
                                Text(worker.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
                                const SizedBox(width: 2),
                                Text('(${worker.reviewsCount})', style: const TextStyle(fontSize: 11, color: AppColors.lightSlate)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                          const SizedBox(width: 2),
                          Text('${worker.tasksCompleted}', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                          const Spacer(),
                          if (distance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.near_me, size: 12, color: AppColors.info),
                                  const SizedBox(width: 3),
                                  Text(
                                    GeoUtils.formatDistance(distance!),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkerCardHorizontal extends StatelessWidget {
  final UserModel worker;
  final double? distance;
  final VoidCallback? onTap;

  const WorkerCardHorizontal({
    super.key,
    required this.worker,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surface,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    worker.fullName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              worker.fullName.split(' ').first,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(worker.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
                ],
              ),
            ),
            if (distance != null) ...[
              const SizedBox(height: 4),
              Text(
                GeoUtils.formatDistance(distance!),
                style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
