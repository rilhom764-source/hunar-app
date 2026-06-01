import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/task_model.dart';
import '../models/bid_model.dart';
import '../providers/app_state_provider.dart';
import '../l10n/localization_provider.dart'; // ignore: unused_import

// ═══════════════════════════════════════════════════════════
// ANALYTICS DASHBOARD — Дашборд мастера
// Housecall Pro / ServiceTitan вдохновение
// ═══════════════════════════════════════════════════════════

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPeriod = 1; // 0=Неделя, 1=Месяц, 2=Год

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
    // l10n is available for future localization
    context.watch<LocalizationProvider>();
    final analytics = _computeAnalytics(state);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── HEADER ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart_rounded,
                                color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            const Text(
                              'Моя аналитика',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    analytics.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.currentUser.fullName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── PERIOD SELECTOR ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _PeriodSelector(
                selected: _selectedPeriod,
                onChanged: (v) => setState(() => _selectedPeriod = v),
              ),
            ),
          ),

          // ─── HERO STATS ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _HeroStatsRow(analytics: analytics, period: _selectedPeriod),
            ),
          ),

          // ─── INCOME CHART ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _IncomeChartCard(
                analytics: analytics,
                period: _selectedPeriod,
              ),
            ),
          ),

          // ─── CONVERSION FUNNEL ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ConversionFunnelCard(analytics: analytics),
            ),
          ),

          // ─── TOP CATEGORIES ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TopCategoriesCard(analytics: analytics),
            ),
          ),

          // ─── INCOME FORECAST ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ForecastCard(analytics: analytics),
            ),
          ),

          // ─── RECENT TASKS ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _RecentTasksCard(state: state),
            ),
          ),
        ],
      ),
    );
  }

  // ── Вычисление аналитики из данных приложения ───────────
  _Analytics _computeAnalytics(AppStateProvider state) {
    final userId = state.currentUser.id;
    final allTasks = state.tasks;
    final allBids = <BidModel>[];
    for (final bids in state.bidsMap.values) {
      allBids.addAll(bids);
    }

    final myBids = allBids.where((b) => b.workerId == userId).toList();
    final acceptedBids =
        myBids.where((b) => b.status == BidStatus.accepted).toList();
    final completedTasks = allTasks
        .where((t) =>
            t.assignedWorkerId == userId && t.status == TaskStatus.completed)
        .toList();

    final now = DateTime.now();
    final periodStart = _periodStart(now, _selectedPeriod);

    // Доход за период
    final periodTasks = completedTasks
        .where((t) => t.updatedAt.isAfter(periodStart))
        .toList();
    final periodIncome =
        periodTasks.fold(0.0, (sum, t) => sum + t.budget);

    // Прошлый период для сравнения
    final prevStart = _prevPeriodStart(now, _selectedPeriod);
    final prevTasks = completedTasks
        .where((t) =>
            t.updatedAt.isAfter(prevStart) &&
            t.updatedAt.isBefore(periodStart))
        .toList();
    final prevIncome = prevTasks.fold(0.0, (sum, t) => sum + t.budget);

    final incomeChange =
        prevIncome > 0 ? ((periodIncome - prevIncome) / prevIncome * 100) : 0.0;

    // Конверсия откликов
    final conversionRate = myBids.isNotEmpty
        ? (acceptedBids.length / myBids.length * 100)
        : 0.0;

    // Топ категории
    final catMap = <String, int>{};
    for (final t in completedTasks) {
      final cat = t.category.name;
      catMap[cat] = (catMap[cat] ?? 0) + 1;
    }
    final topCats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Прогноз дохода (простая линейная экстраполяция)
    final avgPerTask = completedTasks.isNotEmpty
        ? completedTasks.fold(0.0, (s, t) => s + t.budget) /
            completedTasks.length
        : 0.0;
    final avgTasksPerMonth = completedTasks.isNotEmpty ? (completedTasks.length / 3.0).clamp(1, 100) : 0.0;
    final forecastMonthly = avgPerTask * avgTasksPerMonth;

    // Недельные данные для графика (последние 7 дней)
    final weeklyData = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayIncome = completedTasks
          .where((t) =>
              t.updatedAt.isAfter(dayStart) && t.updatedAt.isBefore(dayEnd))
          .fold(0.0, (s, t) => s + t.budget);
      return dayIncome;
    });

    // Рейтинг
    final rating = state.currentUser.rating;

    return _Analytics(
      totalCompleted: completedTasks.length,
      periodIncome: periodIncome,
      prevIncome: prevIncome,
      incomeChange: incomeChange,
      totalBids: myBids.length,
      acceptedBids: acceptedBids.length,
      conversionRate: conversionRate,
      topCategories: topCats.take(5).toList(),
      forecastMonthly: forecastMonthly,
      weeklyData: weeklyData,
      avgTaskValue: avgPerTask,
      rating: rating,
      reviewsCount: state.currentUser.reviewsCount,
    );
  }

  DateTime _periodStart(DateTime now, int period) {
    switch (period) {
      case 0:
        return now.subtract(const Duration(days: 7));
      case 1:
        return DateTime(now.year, now.month, 1);
      case 2:
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _prevPeriodStart(DateTime now, int period) {
    switch (period) {
      case 0:
        return now.subtract(const Duration(days: 14));
      case 1:
        return DateTime(now.year, now.month - 1, 1);
      case 2:
        return DateTime(now.year - 1, 1, 1);
      default:
        return DateTime(now.year, now.month - 1, 1);
    }
  }
}

// ─── DATA CLASS ──────────────────────────────────────────────
class _Analytics {
  final int totalCompleted;
  final double periodIncome;
  final double prevIncome;
  final double incomeChange;
  final int totalBids;
  final int acceptedBids;
  final double conversionRate;
  final List<MapEntry<String, int>> topCategories;
  final double forecastMonthly;
  final List<double> weeklyData;
  final double avgTaskValue;
  final double rating;
  final int reviewsCount;

  const _Analytics({
    required this.totalCompleted,
    required this.periodIncome,
    required this.prevIncome,
    required this.incomeChange,
    required this.totalBids,
    required this.acceptedBids,
    required this.conversionRate,
    required this.topCategories,
    required this.forecastMonthly,
    required this.weeklyData,
    required this.avgTaskValue,
    required this.rating,
    required this.reviewsCount,
  });
}

// ─── PERIOD SELECTOR ─────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Неделя', 'Месяц', 'Год'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.slateGray,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── HERO STATS ROW ──────────────────────────────────────────
class _HeroStatsRow extends StatelessWidget {
  final _Analytics analytics;
  final int period;

  const _HeroStatsRow({required this.analytics, required this.period});

  String get _periodLabel {
    switch (period) {
      case 0:
        return 'за неделю';
      case 1:
        return 'за месяц';
      case 2:
        return 'за год';
      default:
        return 'за месяц';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Главная карточка — доход
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Заработано',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${analytics.periodIncome.toInt()} TJS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      analytics.incomeChange >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: analytics.incomeChange >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${analytics.incomeChange >= 0 ? '+' : ''}${analytics.incomeChange.toStringAsFixed(1)}% $_periodLabel',
                      style: TextStyle(
                        color: analytics.incomeChange >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Правая колонка — мини-статы
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _MiniStatTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Выполнено',
                value: '${analytics.totalCompleted}',
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              _MiniStatTile(
                icon: Icons.bar_chart_rounded,
                label: 'Конверсия',
                value:
                    '${analytics.conversionRate.toStringAsFixed(0)}%',
                color: AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.lightSlate,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── INCOME CHART ────────────────────────────────────────────
class _IncomeChartCard extends StatelessWidget {
  final _Analytics analytics;
  final int period;

  const _IncomeChartCard(
      {required this.analytics, required this.period});

  @override
  Widget build(BuildContext context) {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final maxVal = analytics.weeklyData.reduce((a, b) => a > b ? a : b);
    final hasData = maxVal > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'График дохода',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.deepSlate,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '7 дней',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = analytics.weeklyData[i];
                final heightFraction =
                    hasData ? (val / maxVal).clamp(0.05, 1.0) : 0.05;
                final isToday = i == 6;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            '${val.toInt()}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.lightSlate,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOut,
                          height: 70 * heightFraction,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? AppColors.primaryGradient
                                  : [
                                      AppColors.primary
                                          .withValues(alpha: 0.25),
                                      AppColors.primary
                                          .withValues(alpha: 0.45),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.lightSlate,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONVERSION FUNNEL ───────────────────────────────────────
class _ConversionFunnelCard extends StatelessWidget {
  final _Analytics analytics;

  const _ConversionFunnelCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Конверсия откликов',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FunnelStep(
            label: 'Всего откликов',
            value: analytics.totalBids,
            max: analytics.totalBids,
            color: AppColors.info,
            emoji: '📤',
          ),
          const SizedBox(height: 8),
          _FunnelStep(
            label: 'Принято',
            value: analytics.acceptedBids,
            max: analytics.totalBids,
            color: AppColors.warning,
            emoji: '✅',
          ),
          const SizedBox(height: 8),
          _FunnelStep(
            label: 'Выполнено',
            value: analytics.totalCompleted,
            max: analytics.totalBids,
            color: AppColors.success,
            emoji: '🎉',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Конверсия: ${analytics.conversionRate.toStringAsFixed(1)}%  •  Средний чек: ${analytics.avgTaskValue.toInt()} TJS',
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String emoji;

  const _FunnelStep({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? value / max : 0.0;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.slateGray),
                  ),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── TOP CATEGORIES ──────────────────────────────────────────
class _TopCategoriesCard extends StatelessWidget {
  final _Analytics analytics;

  const _TopCategoriesCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final cats = analytics.topCategories;
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.warning,
      AppColors.success,
      AppColors.error,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Топ категории',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cats.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Выполните задания, чтобы\nпоявилась статистика',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.lightSlate, fontSize: 13),
                ),
              ),
            )
          else
            ...cats.asMap().entries.map((e) {
              final i = e.key;
              final cat = e.value;
              final total =
                  cats.fold(0, (s, c) => s + c.value);
              final pct = total > 0 ? cat.value / total : 0.0;
              final color = colors[i % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatCategoryName(cat.key),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.deepSlate,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 80,
                        height: 6,
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor:
                              color.withValues(alpha: 0.12),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${cat.value}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatCategoryName(String name) {
    final map = {
      'plumbing': 'Сантехника',
      'electrical': 'Электрика',
      'repair': 'Ремонт',
      'cleaning': 'Уборка',
      'moving': 'Переезд',
      'delivery': 'Доставка',
      'courier': 'Курьер',
      'cargoTransport': 'Грузоперевозки',
      'beauty': 'Красота',
      'tutoring': 'Репетиторство',
      'computerRepair': 'Ремонт ПК',
      'autoRepair': 'Авторемонт',
      'painting': 'Покраска',
      'garden': 'Сад',
      'cooking': 'Кулинария',
      'toolRental': 'Аренда инструментов',
      'groceryDelivery': 'Доставка продуктов',
      'cargoSmall': 'Малогабаритный груз',
      'cargoBig': 'Крупный груз',
    };
    return map[name] ?? name;
  }
}

// ─── FORECAST CARD ───────────────────────────────────────────
class _ForecastCard extends StatelessWidget {
  final _Analytics analytics;

  const _ForecastCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final forecast = analytics.forecastMonthly;
    final optimistic = forecast * 1.2;
    final conservative = forecast * 0.8;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2332),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
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
              const Icon(Icons.auto_graph_rounded,
                  color: Color(0xFF00E396), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Прогноз дохода',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'На месяц',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ForecastItem(
                label: 'Пессимист.',
                amount: conservative.toInt(),
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              _ForecastItem(
                label: 'Средний',
                amount: forecast.toInt(),
                color: const Color(0xFF00E396),
                isMain: true,
              ),
              const SizedBox(width: 12),
              _ForecastItem(
                label: 'Оптимист.',
                amount: optimistic.toInt(),
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFF00E396), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forecast > 0
                        ? 'Для достижения цели ${forecast.toInt()} TJS — ${analytics.totalCompleted > 0 ? (forecast / (analytics.avgTaskValue > 0 ? analytics.avgTaskValue : 1)).ceil() : "?"} задания'
                        : 'Выполните первые задания для получения прогноза',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
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

class _ForecastItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool isMain;

  const _ForecastItem({
    required this.label,
    required this.amount,
    required this.color,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isMain
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: isMain
              ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(
              '$amount',
              style: TextStyle(
                color: color,
                fontSize: isMain ? 20 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'TJS',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RECENT TASKS ────────────────────────────────────────────
class _RecentTasksCard extends StatelessWidget {
  final AppStateProvider state;

  const _RecentTasksCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final myTasks = state.myWorkerTasks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.slateGray, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Последние задания',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (myTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Здесь появятся ваши выполненные задания',
                  style: TextStyle(
                      color: AppColors.lightSlate, fontSize: 13),
                ),
              ),
            )
          else
            ...myTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _statusColor(task.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(task.categoryIcon,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.deepSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              task.location,
                              style: const TextStyle(
                                color: AppColors.lightSlate,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${task.budget.toInt()} TJS',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(task.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _statusLabel(task.status),
                              style: TextStyle(
                                color: _statusColor(task.status),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.open:
        return AppColors.statusOpen;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
      case TaskStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.open:
        return 'Открыт';
      case TaskStatus.inProgress:
        return 'В работе';
      case TaskStatus.completed:
        return 'Выполнен';
      case TaskStatus.cancelled:
        return 'Отменён';
    }
  }
}
