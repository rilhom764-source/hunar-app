import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';

class BidScreen extends StatefulWidget {
  final TaskModel task;
  const BidScreen({super.key, required this.task});

  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('task_detail_place_bid')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.task.categoryIcon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepSlate,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.tr('task_detail_budget')}: ${widget.task.budget.toInt()} TJS',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bid amount
              Text(
                l10n.tr('bid_amount_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.tr('bid_amount_hint'),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: 'TJS',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.tr('error_field_required');
                  if (double.tryParse(v) == null) return l10n.tr('error_field_required');
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Message
              Text(
                l10n.tr('bid_message_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.tr('bid_message_hint'),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? l10n.tr('error_field_required') : null,
              ),

              const SizedBox(height: 20),

              // Timeline
              Text(
                l10n.tr('bid_timeline_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _timeCtrl,
                decoration: InputDecoration(
                  hintText: l10n.tr('bid_timeline_hint'),
                  prefixIcon: const Icon(Icons.schedule),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? l10n.tr('error_field_required') : null,
              ),

              const SizedBox(height: 36),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitBid,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(l10n.tr('bid_submit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitBid() {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppStateProvider>();
    final l10n = context.read<LocalizationProvider>();

    state.placeBid(
      taskId: widget.task.id,
      amount: double.parse(_amountCtrl.text.trim()),
      message: _messageCtrl.text.trim(),
      estimatedTime: _timeCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tr('bid_success')),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
