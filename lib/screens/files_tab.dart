import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class FilesTab extends StatelessWidget {
  const FilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationHelper.of(context).myFiles,
            style: TextStyle(
              fontSize: AppTheme.isSmallScreen(context) ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 未实现功能占位
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.file_copy_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocalizationHelper.of(context).filesFeatureComingSoon,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocalizationHelper.of(context).stayTuned,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 