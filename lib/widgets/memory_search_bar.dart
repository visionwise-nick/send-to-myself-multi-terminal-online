import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class MemorySearchBar extends StatefulWidget {
  const MemorySearchBar({super.key});

  @override
  State<MemorySearchBar> createState() => _MemorySearchBarState();
}

class _MemorySearchBarState extends State<MemorySearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyStyle,
        decoration: InputDecoration(
          hintText: '搜索记忆...',
          hintStyle: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textTertiaryColor,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textSecondaryColor,
            size: 18,
          ),
          suffixIcon: _isSearching
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppTheme.textSecondaryColor,
                  size: 18,
                ),
                onPressed: _clearSearch,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    // 实时搜索（防抖）
    _debounceSearch(query);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<MemoryProvider>().setSearchQuery(query.trim());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    context.read<MemoryProvider>().setSearchQuery('');
  }

  // 防抖搜索
  void _debounceSearch(String query) {
    // 简单的防抖实现
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query && query.trim().isNotEmpty) {
        context.read<MemoryProvider>().setSearchQuery(query.trim());
      }
    });
  }
} 