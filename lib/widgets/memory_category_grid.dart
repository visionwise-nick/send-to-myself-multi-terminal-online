import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_model.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class MemoryCategoryGrid extends StatelessWidget {
  final Function(String?)? onCategorySelected;

  const MemoryCategoryGrid({
    super.key,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryProvider>(
      builder: (context, memoryProvider, child) {
        final categories = _buildCategoryData(memoryProvider);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '记忆分类',
              style: AppTheme.titleStyle.copyWith(
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = false;
                
                return _CategoryItem(
                  icon: category['icon'],
                  name: category['name'],
                  count: category['count'],
                  isSelected: isSelected,
                  onTap: () {
                    final categoryName = isSelected ? null : category['name'] as String?;
                    onCategorySelected?.call(categoryName);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildCategoryData(MemoryProvider memoryProvider) {
    final memoriesByType = memoryProvider.memoriesByType;
    
    return [
      {
        'icon': '📝',
        'name': MemoryType.text.displayName,
        'count': memoriesByType[MemoryType.text] ?? 0,
      },
      {
        'icon': '🔐',
        'name': MemoryType.password.displayName,
        'count': memoriesByType[MemoryType.password] ?? 0,
      },
      {
        'icon': '💰',
        'name': MemoryType.financial.displayName,
        'count': memoriesByType[MemoryType.financial] ?? 0,
      },
      {
        'icon': '📅',
        'name': MemoryType.schedule.displayName,
        'count': memoriesByType[MemoryType.schedule] ?? 0,
      },
      {
        'icon': '✅',
        'name': MemoryType.todo.displayName,
        'count': memoriesByType[MemoryType.todo] ?? 0,
      },
      {
        'icon': '🖼️',
        'name': MemoryType.image.displayName,
        'count': memoriesByType[MemoryType.image] ?? 0,
      },
      {
        'icon': '🎬',
        'name': MemoryType.video.displayName,
        'count': memoriesByType[MemoryType.video] ?? 0,
      },
      {
        'icon': '📄',
        'name': MemoryType.document.displayName,
        'count': memoriesByType[MemoryType.document] ?? 0,
      },
    ];
  }
}

class _CategoryItem extends StatelessWidget {
  final String icon;
  final String name;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.name,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTheme.captionStyle.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? AppTheme.fontWeightMedium : AppTheme.fontWeightNormal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: AppTheme.smallStyle.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiaryColor,
                  fontWeight: AppTheme.fontWeightMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 