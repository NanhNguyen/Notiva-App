import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_buttons.dart';

/// Highlighted "Tiếp tục từ đây" card on the Today (A1) screen.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.sectionName,
    required this.pieceTitle,
    required this.lastPracticedLabel,
    this.previousNote,
    this.nextAction,
    required this.onContinue,
  });

  final String sectionName;
  final String pieceTitle;
  final String lastPracticedLabel;
  final String? previousNote;
  final String? nextAction;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tiếp tục từ đây', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(sectionName, style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  pieceTitle,
                  style: AppTextStyles.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(lastPracticedLabel, style: AppTextStyles.caption),
            ],
          ),
          if (previousNote != null && previousNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              previousNote!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ],
          if (nextAction != null && nextAction!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Việc tiếp theo', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Text(nextAction!, style: AppTextStyles.label),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Tiếp tục tập',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

