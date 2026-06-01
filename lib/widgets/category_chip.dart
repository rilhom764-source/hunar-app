import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/task_model.dart';

class CategoryChipRow extends StatelessWidget {
  final TaskCategory? selected;
  final ValueChanged<TaskCategory?> onSelected;
  final String Function(String) localizer;

  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.localizer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(null, localizer('home_view_all'), '📋'),
          ...TaskCategory.values.map((cat) => _buildChip(
            cat,
            localizer('category_${cat.name}'),
            _categoryEmoji(cat),
          )),
        ],
      ),
    );
  }

  Widget _buildChip(TaskCategory? category, String label, String emoji) {
    final isSelected = selected == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Text(emoji, style: const TextStyle(fontSize: 16)),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : AppColors.slateGray,
        ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (_) => onSelected(isSelected ? null : category),
      ),
    );
  }

  String _categoryEmoji(TaskCategory cat) {
    final dummyTask = TaskModel(
      id: '', clientId: '', clientName: '', title: '', description: '',
      category: cat, budget: 0, location: '', latitude: 0, longitude: 0,
      deadline: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    return dummyTask.categoryIcon;
  }
}
