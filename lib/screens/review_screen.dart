import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';

class ReviewScreen extends StatefulWidget {
  final TaskModel task;
  final String targetUserId;
  final String targetUserName;

  const ReviewScreen({
    super.key,
    required this.task,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5.0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('review_title')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(widget.task.categoryIcon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.tr('review_for')}: ${widget.targetUserName}',
                          style: const TextStyle(fontSize: 13, color: AppColors.slateGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rating
            Center(
              child: Text(l10n.tr('review_rating_label'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1.0;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        _rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(l10n),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
            ),

            const SizedBox(height: 32),

            // Comment
            Text(l10n.tr('review_comment_label'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.tr('review_comment_hint'),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.tr('review_submit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(LocalizationProvider l10n) {
    if (_rating >= 5) return l10n.tr('review_excellent');
    if (_rating >= 4) return l10n.tr('review_good');
    if (_rating >= 3) return l10n.tr('review_average');
    if (_rating >= 2) return l10n.tr('review_poor');
    return l10n.tr('review_terrible');
  }

  void _submit() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.read<AppStateProvider>().addReview(
      taskId: widget.task.id,
      targetUserId: widget.targetUserId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
    );

    final l10n = context.read<LocalizationProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('review_success')), backgroundColor: AppColors.success),
    );
    Navigator.pop(context);
  }
}
