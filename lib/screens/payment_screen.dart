import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../services/payment_service.dart';
import '../providers/app_state_provider.dart';

class PaymentScreen extends StatefulWidget {
  final TaskModel task;
  const PaymentScreen({super.key, required this.task});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.alifMobi;
  bool _isProcessing = false;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('payment_title')),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSuccess ? _buildSuccess(l10n) : _buildPaymentForm(l10n),
    );
  }

  Widget _buildPaymentForm(LocalizationProvider l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  l10n.tr('payment_amount'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.task.budget.toInt()} TJS',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            l10n.tr('payment_method'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.deepSlate,
            ),
          ),
          const SizedBox(height: 12),

          // Alif Mobi
          _PaymentMethodTile(
            icon: Icons.phone_android,
            name: l10n.tr('payment_alif'),
            subtitle: 'P2P Transfer',
            color: const Color(0xFF6C63FF),
            isSelected: _selectedMethod == PaymentMethod.alifMobi,
            onTap: () => setState(() => _selectedMethod = PaymentMethod.alifMobi),
          ),
          const SizedBox(height: 10),

          // DC Next
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet,
            name: l10n.tr('payment_dc_next'),
            subtitle: 'Digital Wallet',
            color: const Color(0xFF00BCD4),
            isSelected: _selectedMethod == PaymentMethod.dcNext,
            onTap: () => setState(() => _selectedMethod = PaymentMethod.dcNext),
          ),
          const SizedBox(height: 10),

          // Cash
          _PaymentMethodTile(
            icon: Icons.money,
            name: l10n.tr('payment_cash'),
            subtitle: 'Cash on Delivery',
            color: AppColors.success,
            isSelected: _selectedMethod == PaymentMethod.cash,
            onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
          ),

          const SizedBox(height: 32),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.tr('payment_processing')),
                      ],
                    )
                  : Text(
                      '${l10n.tr('payment_confirm')} • ${widget.task.budget.toInt()} TJS',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(LocalizationProvider l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('payment_success'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.deepSlate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.task.budget.toInt()} TJS',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(l10n.tr('nav_home')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    final state = context.read<AppStateProvider>();
    final result = await state.processPayment(
      method: _selectedMethod,
      amount: widget.task.budget,
      taskId: widget.task.id,
    );

    setState(() {
      _isProcessing = false;
      _isSuccess = result.success;
    });

    if (!result.success && mounted) {
      final l10n = context.read<LocalizationProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('payment_failed')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.deepSlate,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : AppColors.lightSlate,
            ),
          ],
        ),
      ),
    );
  }
}
