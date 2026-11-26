import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Minimal placeholder screen for each tab in Slice 0.
class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.display),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _EmptyPianoKeys(),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          emptyTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          emptySubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five minimal white piano keys for empty states (docs/design.md 6.10).
class _EmptyPianoKeys extends StatelessWidget {
  const _EmptyPianoKeys();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Container(
          width: 24,
          height: 56,
          margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderSm,
            border: Border.all(color: AppColors.border, width: 1),
          ),
        );
      }),
    );
  }
}

