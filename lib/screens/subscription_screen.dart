import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/subscription_model.dart';
import '../providers/app_state_provider.dart';

// ═══════════════════════════════════════════════════════════
// SUBSCRIPTION SCREEN — Абонементы для клиентов
// Вдохновение: DARI, Helpling, ServiceMarket
// ═══════════════════════════════════════════════════════════

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Предопределённые тарифы
  static final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Базовый',
      description: 'Для редких регулярных задач',
      priceMonthly: 149,
      tasksIncluded: 2,
      discountPercent: 10,
      priorityWorker: false,
      expressBooking: false,
      badge: '⭐',
      gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
    SubscriptionPlan(
      id: 'standard',
      name: 'Стандарт',
      description: 'Самый популярный выбор',
      priceMonthly: 279,
      tasksIncluded: 4,
      discountPercent: 20,
      priorityWorker: true,
      expressBooking: false,
      badge: '🔥',
      gradient: const [Color(0xFF00875A), Color(0xFF00C97B)],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Премиум',
      description: 'Максимум сервиса и комфорта',
      priceMonthly: 449,
      tasksIncluded: 0, // безлимит
      discountPercent: 30,
      priorityWorker: true,
      expressBooking: true,
      badge: '💎',
      gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
    ),
  ];

  int _selectedPlanIndex = 1; // Стандарт по умолчанию

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final mySubscriptions = state.mySubscriptions;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF00875A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Text('💳', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            const Text(
                              'Абонементы',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Регулярный сервис со скидкой и личным мастером',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Тарифы'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Мои абонементы'),
                      if (mySubscriptions.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${mySubscriptions.length}',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _PlansTab(
              plans: _plans,
              selectedIndex: _selectedPlanIndex,
              onSelect: (i) => setState(() => _selectedPlanIndex = i),
              onSubscribe: _showSubscribeDialog,
            ),
            _MySubscriptionsTab(
              subscriptions: mySubscriptions,
              onGoToPlans: () => _tabController.animateTo(0),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscribeDialog(SubscriptionPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscribeSheet(
        plan: plan,
        onConfirm: (category, description, frequency, preferredTime) {
          final state = context.read<AppStateProvider>();
          state.createSubscription(
            planId: plan.id,
            planName: plan.name,
            frequency: frequency,
            serviceCategory: category,
            serviceDescription: description,
            preferredTime: preferredTime,
            pricePerVisit: plan.priceMonthly /
                (plan.tasksIncluded > 0 ? plan.tasksIncluded : 4),
            tasksTotal: plan.tasksIncluded > 0 ? plan.tasksIncluded : 30,
          );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('✅ '),
                  Expanded(
                    child: Text(
                      'Абонемент "${plan.name}" оформлен! Мастер будет назначен.',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _tabController.animateTo(1);
        },
      ),
    );
  }
}

// ─── PLANS TAB ───────────────────────────────────────────────
class _PlansTab extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(SubscriptionPlan) onSubscribe;

  const _PlansTab({
    required this.plans,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Преимущества
        _BenefitsRow(),
        const SizedBox(height: 16),

        // Карточки тарифов
        ...plans.asMap().entries.map((e) {
          final i = e.key;
          final plan = e.value;
          final isSelected = i == selectedIndex;
          return _PlanCard(
            plan: plan,
            isSelected: isSelected,
            onTap: () => onSelect(i),
            onSubscribe: () => onSubscribe(plan),
          );
        }),

        const SizedBox(height: 8),

        // FAQ
        _FaqCard(),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('🏷️', 'Скидка до 30%'),
      ('👤', 'Свой мастер'),
      ('⚡', 'Приоритет'),
      ('🔄', 'Авто-заказ'),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.slateGray,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.id == 'standard';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? plan.gradient.first
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? plan.gradient.first.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: plan.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Text(plan.badge,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Хит',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          plan.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${plan.priceMonthly.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'TJS/мес',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FeatureRow(
                    icon: Icons.task_alt_rounded,
                    text: plan.tasksIncluded > 0
                        ? '${plan.tasksIncluded} задания в месяц'
                        : 'Безлимитные задания',
                    active: true,
                    color: plan.gradient.first,
                  ),
                  const SizedBox(height: 8),
                  _FeatureRow(
                    icon: Icons.local_offer_rounded,
                    text: 'Скидка ${plan.discountPercent}% на каждый заказ',
                    active: true,
                    color: plan.gradient.first,
                  ),
                  const SizedBox(height: 8),
                  _FeatureRow(
                    icon: Icons.person_pin_rounded,
                    text: 'Закреплённый мастер',
                    active: plan.priorityWorker,
                    color: plan.gradient.first,
                  ),
                  const SizedBox(height: 8),
                  _FeatureRow(
                    icon: Icons.flash_on_rounded,
                    text: 'Приоритетное бронирование',
                    active: plan.expressBooking,
                    color: plan.gradient.first,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.gradient.first,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Оформить "${plan.name}"',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool active;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          active ? icon : Icons.remove_rounded,
          color: active ? color : AppColors.paleSlate,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: active ? AppColors.deepSlate : AppColors.lightSlate,
            fontSize: 13,
            decoration: active ? null : TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Можно ли отменить абонемент?',
          'Да, в любой момент без штрафов. Оставшиеся задания остаются доступными.'),
      ('Как назначается мастер?',
          'При первом заказе мы подберём мастера с наилучшим рейтингом. В дальнейшем он закрепляется за вами.'),
      ('Что если мастер не придёт?',
          'Мы немедленно назначим другого мастера или вернём средства.'),
    ];

    return Column(
      children: items.map((item) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              leading: const Icon(Icons.help_outline_rounded,
                  color: AppColors.primary, size: 20),
              title: Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepSlate,
                ),
              ),
              children: [
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppColors.slateGray,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── MY SUBSCRIPTIONS TAB ────────────────────────────────────
class _MySubscriptionsTab extends StatelessWidget {
  final List<SubscriptionModel> subscriptions;
  final VoidCallback? onGoToPlans;

  const _MySubscriptionsTab({
    required this.subscriptions,
    this.onGoToPlans,
  });

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.subscriptions_outlined,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Нет активных абонементов',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSlate,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Оформите абонемент и получайте\nрегулярный сервис со скидкой',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onGoToPlans,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Выбрать тариф'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...subscriptions.map((sub) => _SubscriptionCard(sub: sub)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;

  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final isActive = sub.status == SubscriptionStatus.active;
    final progress =
        sub.tasksTotal > 0 ? sub.tasksUsed / sub.tasksTotal : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sub.planId == 'premium'
                        ? const [Color(0xFF7C3AED), Color(0xFFA855F7)]
                        : sub.planId == 'standard'
                            ? AppColors.primaryGradient
                            : const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sub.planName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sub.statusLabel,
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                sub.frequencyLabel,
                style: const TextStyle(
                  color: AppColors.lightSlate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.build_circle_outlined,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sub.serviceDescription,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.slateGray, size: 14),
              const SizedBox(width: 6),
              Text(
                sub.preferredTime,
                style: const TextStyle(
                    color: AppColors.slateGray, fontSize: 13),
              ),
              const Spacer(),
              Text(
                'Следующий: ${_formatDate(sub.nextVisit)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (sub.assignedWorkerName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ваш мастер',
                        style: TextStyle(
                          color: AppColors.lightSlate,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        sub.assignedWorkerName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepSlate,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.verified_rounded,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Использовано: ${sub.tasksUsed} / ${sub.tasksTotal == 30 ? '∞' : '${sub.tasksTotal}'}',
                style: const TextStyle(
                    color: AppColors.slateGray, fontSize: 12),
              ),
              Text(
                '${sub.pricePerVisit.toInt()} TJS / визит',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, sub),
                  icon: const Icon(Icons.pause_rounded, size: 16),
                  label: const Text('Пауза',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slateGray,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('⏰ Дата следующего визита изменена')),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: const Text('Перенести',
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  void _showCancelDialog(BuildContext context, SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Приостановить абонемент?'),
        content: Text(
          'Абонемент "${sub.planName}" будет приостановлен. Оставшиеся визиты сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppStateProvider>().pauseSubscription(sub.id);
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Приостановить'),
          ),
        ],
      ),
    );
  }
}

// ─── SUBSCRIBE BOTTOM SHEET ──────────────────────────────────
class _SubscribeSheet extends StatefulWidget {
  final SubscriptionPlan plan;
  final void Function(
    String category,
    String description,
    SubscriptionFrequency frequency,
    String preferredTime,
  ) onConfirm;

  const _SubscribeSheet({required this.plan, required this.onConfirm});

  @override
  State<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<_SubscribeSheet> {
  String _selectedCategory = 'cleaning';
  SubscriptionFrequency _frequency = SubscriptionFrequency.weekly;
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: 'Пятница, 10:00');

  final _categories = [
    ('cleaning', '🧹', 'Уборка'),
    ('laundry', '👕', 'Стирка'),
    ('garden', '🌿', 'Сад/огород'),
    ('cooking', '🍳', 'Готовка'),
    ('childcare', '👶', 'Уход за детьми'),
    ('petcare', '🐾', 'Уход за питомцами'),
    ('groceryDelivery', '🛒', 'Доставка продуктов'),
    ('other', '📋', 'Другое'),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(widget.plan.badge,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Абонемент "${widget.plan.name}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.deepSlate,
                      ),
                    ),
                    Text(
                      '${widget.plan.priceMonthly.toInt()} TJS/месяц',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            const Text(
              'Тип услуги',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.$2,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat.$3,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.deepSlate,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Описание (например: уборка 2-комн. квартиры)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Опишите задачу подробнее...',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Frequency
            const Text(
              'Частота',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: SubscriptionFrequency.values
                  .where((f) => f != SubscriptionFrequency.once)
                  .map((f) {
                final isSelected = _frequency == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _freqLabel(f),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.slateGray,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Preferred time
            const Text(
              'Удобное время',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(
                hintText: 'Напр.: Пятница, 14:00',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _SummaryRow('Тариф', widget.plan.name),
                  _SummaryRow('Скидка', '${widget.plan.discountPercent}%'),
                  _SummaryRow(
                    'Визитов',
                    widget.plan.tasksIncluded > 0
                        ? '${widget.plan.tasksIncluded} в месяц'
                        : 'Безлимит',
                  ),
                  _SummaryRow(
                      'Стоимость',
                      '${widget.plan.priceMonthly.toInt()} TJS/мес',
                      isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final desc = _descCtrl.text.trim().isEmpty
                      ? _getCategoryName(_selectedCategory)
                      : _descCtrl.text.trim();
                  widget.onConfirm(
                    _selectedCategory,
                    desc,
                    _frequency,
                    _timeCtrl.text.trim().isEmpty
                        ? 'Любое время'
                        : _timeCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.plan.gradient.first,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Оформить за ${widget.plan.priceMonthly.toInt()} TJS/мес',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _freqLabel(SubscriptionFrequency f) {
    switch (f) {
      case SubscriptionFrequency.weekly:
        return 'Раз в\nнеделю';
      case SubscriptionFrequency.biweekly:
        return 'Раз в 2\nнедели';
      case SubscriptionFrequency.monthly:
        return 'Раз в\nмесяц';
      default:
        return '';
    }
  }

  String _getCategoryName(String id) {
    return _categories.firstWhere((c) => c.$1 == id, orElse: () => (id, '', id)).$3;
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryRow(this.label, this.value, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.slateGray, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.primary : AppColors.deepSlate,
              fontWeight:
                  isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: isHighlight ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
