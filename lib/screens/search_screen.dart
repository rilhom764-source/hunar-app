import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/worker_card.dart';
import 'task_detail_screen.dart';
import 'worker_detail_screen.dart';
import 'bid_screen.dart';
import 'map_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;

    final filteredTasks = state.searchTasks(_query);
    final filteredWorkers = state.searchWorkers(_query);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════
            // HEADER: Обзор + поиск + фильтр
            // ═══════════════════════════════════
            Container(
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
                  // Title row
                  Padding(
                    padding: EdgeInsets.fromLTRB(isSmall ? 14 : 18, isSmall ? 10 : 14, isSmall ? 14 : 18, 0),
                    child: Row(
                      children: [
                        Icon(Icons.explore_rounded, color: Colors.white, size: isSmall ? 22 : 26),
                        SizedBox(width: isSmall ? 8 : 10),
                        Text(
                          l10n.tr('nav_overview'),
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        // Map button
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Icon(Icons.map_rounded, color: Colors.white, size: isSmall ? 20 : 22),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmall ? 10 : 14),

                  // Search bar + filter button
                  Padding(
                    padding: EdgeInsets.fromLTRB(isSmall ? 14 : 18, 0, isSmall ? 14 : 18, isSmall ? 12 : 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              onTap: () => setState(() => _isSearchFocused = true),
                              onEditingComplete: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _isSearchFocused = false);
                              },
                              style: TextStyle(color: AppColors.deepSlate, fontSize: isSmall ? 13 : 14),
                              decoration: InputDecoration(
                                hintText: l10n.tr('search_hint'),
                                hintStyle: TextStyle(color: AppColors.lightSlate, fontSize: isSmall ? 13 : 14),
                                prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: isSmall ? 20 : 22),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded, size: isSmall ? 18 : 20),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() {
                                            _query = '';
                                            _isSearchFocused = false;
                                          });
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                                ),
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
                              color: _hasActiveFilters(state)
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _hasActiveFilters(state)
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.25),
                                width: _hasActiveFilters(state) ? 2 : 1,
                              ),
                              boxShadow: _hasActiveFilters(state) ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: _hasActiveFilters(state) ? AppColors.primary : Colors.white,
                                  size: isSmall ? 20 : 22,
                                ),
                                if (_hasActiveFilters(state))
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
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

            // ═══════════════════════════════════
            // CATEGORIES (horizontal chips)
            // ═══════════════════════════════════
            if (!_isSearchFocused || _query.isEmpty)
              SizedBox(
                height: isSmall ? 44 : 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 6 : 8),
                  children: [
                    _CategoryChip(
                      icon: Icons.grid_view_rounded,
                      label: l10n.tr('overview_all'),
                      isSelected: state.selectedCategory == null,
                      onTap: () => state.setCategory(null),
                      isSmall: isSmall,
                    ),
                    ...TaskCategory.values.map((cat) => _CategoryChip(
                      icon: _categoryIcon(cat),
                      label: l10n.tr('category_${cat.name}'),
                      isSelected: state.selectedCategory == cat,
                      onTap: () => state.setCategory(cat),
                      isSmall: isSmall,
                    )),
                  ],
                ),
              ),

            // ═══════════════════════════════════
            // RADIUS + SORT (compact row)
            // ═══════════════════════════════════
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
              child: Row(
                children: [
                  Icon(Icons.radar_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${state.searchRadius.toInt()} ${l10n.tr('search_km')}',
                    style: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.w600, color: AppColors.slateGray),
                  ),
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
                      child: Slider(
                        value: state.searchRadius,
                        min: 1, max: 100, divisions: 20,
                        onChanged: (v) => state.setSearchRadius(v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════
            // TAB BAR: Задания / Мастера
            // ═══════════════════════════════════
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
              child: Container(
                height: isSmall ? 38 : 42,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.headerGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.slateGray,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 12 : 13),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: isSmall ? 12 : 13),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_rounded, size: isSmall ? 14 : 16),
                          SizedBox(width: isSmall ? 4 : 6),
                          Text('${l10n.tr('tab_tasks')} (${filteredTasks.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_rounded, size: isSmall ? 14 : 16),
                          SizedBox(width: isSmall ? 4 : 6),
                          Text('${l10n.tr('tab_workers')} (${filteredWorkers.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isSmall ? 6 : 8),

            // ═══════════════════════════════════
            // CONTENT
            // ═══════════════════════════════════
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tasks
                  filteredTasks.isEmpty
                      ? _EmptyState(message: l10n.tr('search_no_results'), icon: Icons.assignment_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, i) {
                            final task = filteredTasks[i];
                            return TaskCard(
                              task: task,
                              distance: state.distanceToTask(task),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
                              trailing: state.isWorker && task.status == TaskStatus.open && !state.hasWorkerBidOnTask(task.id)
                                  ? _QuickBidChip(label: l10n.tr('worker_quick_bid'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BidScreen(task: task))))
                                  : null,
                            );
                          },
                        ),
                  // Workers
                  filteredWorkers.isEmpty
                      ? _EmptyState(message: l10n.tr('search_no_results'), icon: Icons.people_outline)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredWorkers.length,
                          itemBuilder: (context, i) {
                            final worker = filteredWorkers[i];
                            return WorkerCard(
                              worker: worker,
                              distance: state.distanceToWorker(worker),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker))),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
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

  bool _hasActiveFilters(AppStateProvider state) {
    return state.selectedCategory != null || state.minBudget > 0 || state.maxBudget < 10000 || state.minRating > 0;
  }

  void _showFilterSheet(BuildContext context, AppStateProvider state, LocalizationProvider l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.tr('search_filters'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.deepSlate)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () { state.resetFilters(); Navigator.pop(ctx); },
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(l10n.tr('filter_reset')),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category filter
              Text(l10n.tr('task_category_label'), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.tr('filter_all')),
                    selected: state.selectedCategory == null,
                    onSelected: (_) => state.setCategory(null),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: state.selectedCategory == null ? Colors.white : AppColors.slateGray),
                  ),
                  ...TaskCategory.values.map((cat) => FilterChip(
                    label: Text(l10n.tr('category_${cat.name}')),
                    selected: state.selectedCategory == cat,
                    onSelected: (_) => state.setCategory(cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: state.selectedCategory == cat ? Colors.white : AppColors.slateGray),
                  )),
                ],
              ),

              const SizedBox(height: 24),

              // Budget range
              Text('${l10n.tr('filter_budget')}: ${state.minBudget.toInt()} - ${state.maxBudget.toInt()} TJS', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
              const SizedBox(height: 4),
              RangeSlider(
                values: RangeValues(state.minBudget, state.maxBudget),
                min: 0, max: 10000, divisions: 100,
                activeColor: AppColors.primary,
                onChanged: (values) => state.setBudgetRange(values.start, values.end),
              ),

              const SizedBox(height: 16),

              // Min rating
              Text('${l10n.tr('filter_min_rating')}: ${state.minRating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepSlate)),
              const SizedBox(height: 4),
              Slider(
                value: state.minRating,
                min: 0, max: 5, divisions: 10,
                activeColor: AppColors.warning,
                onChanged: (v) => state.setMinRating(v),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.tr('filter_apply')),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CATEGORY CHIP
// ═══════════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmall;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 4 : 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: AppColors.headerGradient)
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.divider,
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isSmall ? 14 : 16, color: isSelected ? Colors.white : AppColors.slateGray),
              SizedBox(width: isSmall ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.slateGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBidChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickBidChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.headerGradient),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, this.icon = Icons.search_off});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.lightSlate),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, color: AppColors.slateGray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
