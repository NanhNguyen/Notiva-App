import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Displays a calm, notebook-styled floating SnackBar toast.
void showAppToast(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.textPrimary,
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        content: Text(
          message,
          style: AppTextStyles.label.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
}

