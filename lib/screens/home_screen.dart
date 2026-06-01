import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/category_chip.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return state.isClient ? const _ClientHomeScreen() : const _WorkerHomeScreen();
  }
}

// ═══════════════════════════════════════════════
// CLIENT HOME
// ═══════════════════════════════════════════════
class _ClientHomeScreen extends StatelessWidget {
  const _ClientHomeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;
    final hPad = isSmall ? 12.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => state.refreshFromFirestore(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _CompactHeader(l10n: l10n, state: state, isSmall: isSmall)),

              // Client subtitle
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 8),
                  child: Text(l10n.tr('client_home_subtitle'), style: TextStyle(fontSize: isSmall ? 12 : 13, color: AppColors.slateGray)),
                ),
              ),

              // Quick stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    children: [
                      _MiniStatCard(icon: Icons.assignment_outlined, value: '${state.myActiveClientTasks.length}', label: l10n.tr('client_active_count'), color: AppColors.statusOpen, isSmall: isSmall),
                      SizedBox(width: isSmall ? 6 : 8),
                      _MiniStatCard(icon: Icons.check_circle_outline, value: '${state.myCompletedClientTasks.length}', label: l10n.tr('client_completed_count'), color: AppColors.statusCompleted, isSmall: isSmall),
                      SizedBox(width: isSmall ? 6 : 8),
                      _MiniStatCard(icon: Icons.gavel_outlined, value: '${state.totalBidsOnMyTasks}', label: l10n.tr('task_detail_bids'), color: AppColors.warning, isSmall: isSmall),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: isSmall ? 12 : 16)),

              // My Tasks
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.tr('client_my_tasks')} (${state.myCreatedTasks.length})',
                        style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline, size: isSmall ? 14 : 16, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(l10n.tr('nav_create'), style: TextStyle(fontSize: isSmall ? 11 : 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.myCreatedTasks.isEmpty)
                SliverToBoxAdapter(
                  child: _CompactEmptyPrompt(
                    icon: Icons.post_add_rounded,
                    message: l10n.tr('client_no_tasks'),
                    buttonText: l10n.tr('task_create_title'),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
                    isSmall: isSmall,
                    hPad: hPad,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = state.myCreatedTasks[index];
                      return _ClientTaskTile(
                        task: task,
                        bidsCount: state.getBidsForTask(task.id).length,
                        l10n: l10n,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
                        isSmall: isSmall,
                        hPad: hPad,
                      );
                    },
                    childCount: state.myCreatedTasks.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// WORKER HOME (хедер + поиск/фильтры + категории + задания)
// ═══════════════════════════════════════════════
class _WorkerHomeScreen extends StatefulWidget {
  const _WorkerHomeScreen();

  @override
  State<_WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<_WorkerHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;
    final hPad = isSmall ? 12.0 : 16.0;

    // Filter tasks by search query
    final allTasks = state.filteredTasks;
    final tasks = _query.isEmpty
        ? allTasks
        : allTasks.where((t) =>
            t.title.toLowerCase().contains(_query.toLowerCase()) ||
            t.description.toLowerCase().contains(_query.toLowerCase()) ||
            t.location.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => state.refreshFromFirestore(),
          child: CustomScrollView(
            slivers: [
              // ═══ HEADER with search ═══
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.headerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top row: logo + name + notifications
                      Padding(
                        padding: EdgeInsets.fromLTRB(isSmall ? 14 : 18, isSmall ? 12 : 14, isSmall ? 14 : 18, 0),
                        child: Row(
                          children: [
                            Container(
                              width: isSmall ? 42 : 48,
                              height: isSmall ? 42 : 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                              ),
                              child: Center(child: Text('U', style: TextStyle(color: Colors.white, fontSize: isSmall ? 22 : 24, fontWeight: FontWeight.w800))),
                            ),
                            SizedBox(width: isSmall ? 10 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.tr('app_name'), style: TextStyle(fontSize: isSmall ? 20 : 22, fontWeight: FontWeight.w700, color: Colors.white)),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: isSmall ? 13 : 14, color: Colors.white.withValues(alpha: 0.85)),
                                      const SizedBox(width: 3),
                                      Text(state.currentUser.city, style: TextStyle(fontSize: isSmall ? 12 : 13, color: Colors.white.withValues(alpha: 0.85))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.notifications_outlined, color: Colors.white.withValues(alpha: 0.9), size: isSmall ? 26 : 28),
                                  ),
                                ),
                                if (state.unreadNotificationCount > 0)
                                  Positioned(
                                    right: 4, top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                      child: Text('${state.unreadNotificationCount}', style: TextStyle(color: Colors.white, fontSize: isSmall ? 9 : 10, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmall ? 10 : 14),

                      // Search bar + filter button
                      Padding(
                        padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, 0, isSmall ? 12 : 16, isSmall ? 12 : 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: TextStyle(color: AppColors.deepSlate, fontSize: isSmall ? 13 : 14),
                                  decoration: InputDecoration(
                                    hintText: l10n.tr('search_hint'),
                                    hintStyle: TextStyle(color: AppColors.lightSlate, fontSize: isSmall ? 13 : 14),
                                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: isSmall ? 20 : 22),
                                    suffixIcon: _query.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.close_rounded, size: isSmall ? 18 : 20),
                                            onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); FocusScope.of(context).unfocus(); },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmall ? 10 : 12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isSmall ? 8 : 10),
                            GestureDetector(
                              onTap: () => _showFilterSheet(context, state, l10n),
                              child: Container(
                                padding: EdgeInsets.all(isSmall ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: _hasActiveFilters(state) ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _hasActiveFilters(state) ? AppColors.primary : Colors.white.withValues(alpha: 0.25),
                                    width: _hasActiveFilters(state) ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(Icons.tune_rounded, color: _hasActiveFilters(state) ? AppColors.primary : Colors.white, size: isSmall ? 20 : 22),
                                    if (_hasActiveFilters(state))
                                      Positioned(
                                        right: -6, top: -6,
                                        child: Container(
                                          width: 16, height: 16,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [AppColors.error, Color(0xFFFF6B6B)]),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          child: Center(child: Text('${_activeFilterCount(state)}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══ RADIUS SLIDER ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.radar_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${state.searchRadius.toInt()} ${l10n.tr('search_km')}', style: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.divider,
                            thumbColor: AppColors.primary,
                          ),
                          child: Slider(value: state.searchRadius, min: 1, max: 100, divisions: 20, onChanged: (v) => state.setSearchRadius(v)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══ CATEGORIES ═══
              SliverToBoxAdapter(child: CategoryChipRow(selected: state.selectedCategory, onSelected: state.setCategory, localizer: l10n.tr)),

              // ═══ RESULTS COUNT ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 4),
                  child: Text(
                    '${l10n.tr('worker_nearby_tasks')} (${tasks.length})',
                    style: TextStyle(fontSize: isSmall ? 13 : 14, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
                  ),
                ),
              ),

              // ═══ TASKS LIST ═══
              tasks.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(isSmall ? 24 : 32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: isSmall ? 36 : 44, color: AppColors.lightSlate),
                              SizedBox(height: isSmall ? 6 : 8),
                              Text(l10n.tr('home_no_tasks'), style: TextStyle(color: AppColors.slateGray, fontSize: isSmall ? 12 : 13)),
                              SizedBox(height: isSmall ? 8 : 10),
                              GestureDetector(
                                onTap: () { setState(() => _query = ''); _searchCtrl.clear(); state.resetFilters(); },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: isSmall ? 14 : 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(l10n.tr('filter_reset'), style: TextStyle(fontSize: isSmall ? 12 : 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            distance: state.distanceToTask(task),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters(AppStateProvider state) {
    return state.selectedCategory != null || state.minBudget > 0 || state.maxBudget < 10000 || state.minRating > 0 || state.sortBy != 'newest';
  }

  int _activeFilterCount(AppStateProvider state) {
    int count = 0;
    if (state.selectedCategory != null) count++;
    if (state.minBudget > 0 || state.maxBudget < 10000) count++;
    if (state.minRating > 0) count++;
    if (state.sortBy != 'newest') count++;
    if (state.searchRadius != 10.0) count++;
    return count;
  }

  // Группы категорий для удобной навигации
  static final Map<String, List<TaskCategory>> _categoryGroups = {
    'home_services': [
      TaskCategory.plumbing, TaskCategory.electrical, TaskCategory.repair,
      TaskCategory.painting, TaskCategory.construction, TaskCategory.tiling,
      TaskCategory.welding, TaskCategory.roofing, TaskCategory.windows,
    ],
    'cleaning_household': [
      TaskCategory.cleaning, TaskCategory.garden, TaskCategory.laundry,
      TaskCategory.cooking, TaskCategory.pestControl,
    ],
    'transport_delivery': [
      TaskCategory.moving, TaskCategory.delivery, TaskCategory.courier,
      TaskCategory.cargoTransport,
    ],
    'tech_repair': [
      TaskCategory.applianceRepair, TaskCategory.furnitureAssembly,
      TaskCategory.acRepair, TaskCategory.computerRepair,
      TaskCategory.phoneRepair, TaskCategory.networkSetup,
    ],
    'auto_services': [
      TaskCategory.autoRepair, TaskCategory.carWash, TaskCategory.tireService,
    ],
    'beauty_health': [
      TaskCategory.beauty, TaskCategory.massage, TaskCategory.fitness,
    ],
    'education': [
      TaskCategory.tutoring, TaskCategory.musicLessons,
      TaskCategory.languageLessons, TaskCategory.drivingLessons,
    ],
    'digital_services': [
      TaskCategory.remoteWork, TaskCategory.webDevelopment, TaskCategory.design,
      TaskCategory.copywriting, TaskCategory.photoVideo, TaskCategory.smmMarketing,
      TaskCategory.translation,
    ],
    'business_events': [
      TaskCategory.legalHelp, TaskCategory.accounting,
      TaskCategory.events, TaskCategory.entertainment, TaskCategory.other,
    ],
  };

  static const Map<String, IconData> _groupIcons = {
    'home_services': Icons.home_repair_service,
    'cleaning_household': Icons.cleaning_services,
    'transport_delivery': Icons.local_shipping,
    'tech_repair': Icons.build_circle,
    'auto_services': Icons.directions_car,
    'beauty_health': Icons.spa,
    'education': Icons.school,
    'digital_services': Icons.computer,
    'business_events': Icons.business_center,
  };

  void _showFilterSheet(BuildContext context, AppStateProvider state, LocalizationProvider l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                ),

                // Header (fixed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.headerGradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.tr('search_filters'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepSlate)),
                            if (_hasActiveFilters(state))
                              Text('${_activeFilterCount(state)} ${l10n.tr('filter_active_count')}', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ]),
                      TextButton.icon(
                        onPressed: () {
                          state.resetFilters();
                          setState(() { _query = ''; _searchCtrl.clear(); });
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: Text(l10n.tr('filter_reset')),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      // ═══ CATEGORIES BY GROUPS ═══
                      _FilterSectionHeader(
                        icon: Icons.category_rounded,
                        title: l10n.tr('task_category_label'),
                        trailing: state.selectedCategory != null
                            ? GestureDetector(
                                onTap: () { state.setCategory(null); setSheetState(() {}); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.close, size: 12, color: AppColors.error),
                                      const SizedBox(width: 3),
                                      Text(l10n.tr('filter_clear'), style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),

                      // "All" chip
                      _FilterCategoryChip(
                        icon: Icons.grid_view_rounded,
                        label: l10n.tr('filter_all'),
                        isSelected: state.selectedCategory == null,
                        onTap: () { state.setCategory(null); setSheetState(() {}); },
                      ),
                      const SizedBox(height: 12),

                      // Category groups
                      ..._categoryGroups.entries.map((entry) {
                        final groupKey = entry.key;
                        final cats = entry.value;
                        final groupIcon = _groupIcons[groupKey] ?? Icons.category;
                        final hasSelectedInGroup = cats.contains(state.selectedCategory);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(groupIcon, size: 15, color: hasSelectedInGroup ? AppColors.primary : AppColors.slateGray),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.tr('category_group_$groupKey'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: hasSelectedInGroup ? FontWeight.w700 : FontWeight.w500,
                                    color: hasSelectedInGroup ? AppColors.primary : AppColors.slateGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: cats.map((cat) => _FilterCategoryChip(
                                icon: _categoryIcon(cat),
                                label: l10n.tr('category_${cat.name}'),
                                isSelected: state.selectedCategory == cat,
                                onTap: () { state.setCategory(cat); setSheetState(() {}); },
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),

                      const Divider(height: 24),

                      // ═══ BUDGET ═══
                      _FilterSectionHeader(icon: Icons.payments_rounded, title: '${l10n.tr('filter_budget')}: ${state.minBudget.toInt()} - ${state.maxBudget.toInt()} TJS'),
                      const SizedBox(height: 4),
                      RangeSlider(
                        values: RangeValues(state.minBudget, state.maxBudget),
                        min: 0, max: 10000, divisions: 100,
                        activeColor: AppColors.primary,
                        onChanged: (v) { state.setBudgetRange(v.start, v.end); setSheetState(() {}); },
                      ),

                      // Quick budget presets
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: [
                          _BudgetPreset(label: '0-500', isSelected: state.minBudget == 0 && state.maxBudget == 500, onTap: () { state.setBudgetRange(0, 500); setSheetState(() {}); }),
                          _BudgetPreset(label: '500-2000', isSelected: state.minBudget == 500 && state.maxBudget == 2000, onTap: () { state.setBudgetRange(500, 2000); setSheetState(() {}); }),
                          _BudgetPreset(label: '2000-5000', isSelected: state.minBudget == 2000 && state.maxBudget == 5000, onTap: () { state.setBudgetRange(2000, 5000); setSheetState(() {}); }),
                          _BudgetPreset(label: '5000+', isSelected: state.minBudget == 5000 && state.maxBudget == 10000, onTap: () { state.setBudgetRange(5000, 10000); setSheetState(() {}); }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ═══ RADIUS ═══
                      _FilterSectionHeader(icon: Icons.radar_rounded, title: '${l10n.tr('search_radius')}: ${state.searchRadius.toInt()} ${l10n.tr('search_km')}'),
                      const SizedBox(height: 4),
                      Slider(
                        value: state.searchRadius, min: 1, max: 100, divisions: 20,
                        activeColor: AppColors.info,
                        onChanged: (v) { state.setSearchRadius(v); setSheetState(() {}); },
                      ),

                      const SizedBox(height: 8),

                      // ═══ RATING ═══
                      _FilterSectionHeader(icon: Icons.star_rounded, title: '${l10n.tr('filter_min_rating')}: ${state.minRating > 0 ? state.minRating.toStringAsFixed(1) : l10n.tr('filter_any')}'),
                      const SizedBox(height: 4),
                      Slider(
                        value: state.minRating, min: 0, max: 5, divisions: 10,
                        activeColor: AppColors.warning,
                        onChanged: (v) { state.setMinRating(v); setSheetState(() {}); },
                      ),

                      const Divider(height: 24),

                      // ═══ SORT ═══
                      _FilterSectionHeader(icon: Icons.sort_rounded, title: l10n.tr('sort_title')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: AppStateProvider.sortOptions.map((opt) {
                          final isSelected = state.sortBy == opt;
                          return ChoiceChip(
                            label: Text(l10n.tr('sort_$opt')),
                            selected: isSelected,
                            onSelected: (_) { state.setSortBy(opt); setSheetState(() {}); },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.slateGray, fontSize: 12, fontWeight: FontWeight.w500),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // ═══ APPLY BUTTON ═══
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.headerGradient),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: Text(
                            '${l10n.tr('filter_apply')} (${state.filteredTasks.length} ${l10n.tr('filter_results')})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
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

  IconData _categoryIcon(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.plumbing: return Icons.plumbing;
      case TaskCategory.electrical: return Icons.electrical_services;
      case TaskCategory.repair: return Icons.build;
      case TaskCategory.painting: return Icons.format_paint;
      case TaskCategory.construction: return Icons.construction;
      case TaskCategory.tiling: return Icons.grid_on;
      case TaskCategory.welding: return Icons.local_fire_department;
      case TaskCategory.roofing: return Icons.roofing;
      case TaskCategory.windows: return Icons.window;
      case TaskCategory.cleaning: return Icons.cleaning_services;
      case TaskCategory.garden: return Icons.yard;
      case TaskCategory.laundry: return Icons.local_laundry_service;
      case TaskCategory.cooking: return Icons.restaurant;
      case TaskCategory.pestControl: return Icons.bug_report;
      case TaskCategory.moving: return Icons.local_shipping;
      case TaskCategory.delivery: return Icons.delivery_dining;
      case TaskCategory.courier: return Icons.directions_bike;
      case TaskCategory.cargoTransport: return Icons.fire_truck;
      case TaskCategory.groceryDelivery: return Icons.shopping_cart;
      case TaskCategory.toolRental: return Icons.handyman;
      case TaskCategory.applianceRepair: return Icons.kitchen;
      case TaskCategory.furnitureAssembly: return Icons.chair;
      case TaskCategory.acRepair: return Icons.ac_unit;
      case TaskCategory.computerRepair: return Icons.computer;
      case TaskCategory.phoneRepair: return Icons.phone_android;
      case TaskCategory.networkSetup: return Icons.wifi;
      case TaskCategory.autoRepair: return Icons.directions_car;
      case TaskCategory.carWash: return Icons.local_car_wash;
      case TaskCategory.tireService: return Icons.tire_repair;
      case TaskCategory.beauty: return Icons.face;
      case TaskCategory.massage: return Icons.spa;
      case TaskCategory.fitness: return Icons.fitness_center;
      case TaskCategory.tutoring: return Icons.school;
      case TaskCategory.musicLessons: return Icons.music_note;
      case TaskCategory.languageLessons: return Icons.translate;
      case TaskCategory.drivingLessons: return Icons.drive_eta;
      case TaskCategory.remoteWork: return Icons.laptop;
      case TaskCategory.webDevelopment: return Icons.code;
      case TaskCategory.design: return Icons.design_services;
      case TaskCategory.copywriting: return Icons.edit_note;
      case TaskCategory.photoVideo: return Icons.camera_alt;
      case TaskCategory.smmMarketing: return Icons.trending_up;
      case TaskCategory.translation: return Icons.g_translate;
      case TaskCategory.legalHelp: return Icons.gavel;
      case TaskCategory.accounting: return Icons.calculate;
      case TaskCategory.events: return Icons.celebration;
      case TaskCategory.entertainment: return Icons.theater_comedy;
      case TaskCategory.other: return Icons.more_horiz;
    }
  }
}

/// Чип категории для фильтр-шита
class _FilterCategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCategoryChip({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: AppColors.headerGradient) : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.divider),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.slateGray),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? Colors.white : AppColors.slateGray)),
          ],
        ),
      ),
    );
  }
}

/// Заголовок секции фильтров
class _FilterSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _FilterSectionHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.deepSlate))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Быстрый пресет бюджета
class _BudgetPreset extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BudgetPreset({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text('$label TJS', style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.slateGray, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED COMPACT WIDGETS
// ═══════════════════════════════════════════════

/// Компактный хедер (для обоих ролей)
class _CompactHeader extends StatelessWidget {
  final LocalizationProvider l10n;
  final AppStateProvider state;
  final bool isSmall;

  const _CompactHeader({required this.l10n, required this.state, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, isSmall ? 10 : 12, isSmall ? 12 : 16, isSmall ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: isSmall ? 36 : 40,
            height: isSmall ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Center(child: Text('U', style: TextStyle(color: Colors.white, fontSize: isSmall ? 18 : 20, fontWeight: FontWeight.w800))),
          ),
          SizedBox(width: isSmall ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tr('app_name'), style: TextStyle(fontSize: isSmall ? 17 : 19, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(
                  children: [
                    Icon(Icons.location_on, size: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 2),
                    Text(state.currentUser.city, style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ],
            ),
          ),
          // Notifications
          Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.notifications_outlined, color: Colors.white.withValues(alpha: 0.9), size: isSmall ? 22 : 24),
                ),
              ),
              if (state.unreadNotificationCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text('${state.unreadNotificationCount}', style: TextStyle(color: Colors.white, fontSize: isSmall ? 8 : 9, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isSmall;

  const _MiniStatCard({required this.icon, required this.value, required this.label, required this.color, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmall ? 6 : 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
          borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: isSmall ? 30 : 34,
              height: isSmall ? 30 : 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: isSmall ? 16 : 18),
            ),
            SizedBox(height: isSmall ? 4 : 5),
            Text(value, style: TextStyle(fontSize: isSmall ? 18 : 20, fontWeight: FontWeight.w700, color: color)),
            SizedBox(height: isSmall ? 2 : 3),
            Text(label, style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.slateGray), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CompactEmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isSmall;
  final double hPad;

  const _CompactEmptyPrompt({required this.icon, required this.message, required this.buttonText, required this.onPressed, required this.isSmall, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 20 : 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              width: isSmall ? 48 : 56,
              height: isSmall ? 48 : 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.1)]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: isSmall ? 22 : 26),
            ),
            SizedBox(height: isSmall ? 10 : 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: isSmall ? 12 : 13, color: AppColors.slateGray, height: 1.3)),
            SizedBox(height: isSmall ? 10 : 12),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(Icons.arrow_forward_rounded, size: isSmall ? 14 : 16),
              label: Text(buttonText, style: TextStyle(fontSize: isSmall ? 12 : 13)),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 18, vertical: isSmall ? 8 : 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientTaskTile extends StatelessWidget {
  final TaskModel task;
  final int bidsCount;
  final LocalizationProvider l10n;
  final VoidCallback onTap;
  final bool isSmall;
  final double hPad;

  const _ClientTaskTile({required this.task, required this.bidsCount, required this.l10n, required this.onTap, required this.isSmall, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          child: Row(
            children: [
              Container(
                width: isSmall ? 36 : 40,
                height: isSmall ? 36 : 40,
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(task.categoryIcon, style: TextStyle(fontSize: isSmall ? 16 : 18))),
              ),
              SizedBox(width: isSmall ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 12 : 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(l10n.tr('task_status_${task.status.name}'), style: TextStyle(fontSize: isSmall ? 9 : 10, color: _statusColor, fontWeight: FontWeight.w600)),
                        ),
                        if (bidsCount > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.gavel, size: isSmall ? 11 : 12, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text('$bidsCount', style: TextStyle(fontSize: isSmall ? 10 : 11, color: AppColors.slateGray, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${task.budget.toInt()} TJS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmall ? 12 : 13, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Icon(Icons.chevron_right, color: AppColors.lightSlate, size: isSmall ? 16 : 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.open: return AppColors.statusOpen;
      case TaskStatus.inProgress: return AppColors.statusInProgress;
      case TaskStatus.completed: return AppColors.statusCompleted;
      case TaskStatus.cancelled: return AppColors.statusCancelled;
    }
  }
}

// Extension для конвертации SizedBox в Widget для sliver
extension SizedBoxSliver on SizedBox {
  Widget toSliverBox() => SliverToBoxAdapter(child: this);
}
