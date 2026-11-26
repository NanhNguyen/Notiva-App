import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../domain/enums/plan_item_priority.dart';
import '../../../domain/enums/plan_item_state.dart';
import '../../../domain/models/today_plan_item_view.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/plan_cubit.dart';
import '../cubit/plan_state.dart';

/// A1 · Home screen with greeting, Smart Resume card, and today's plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlanCubit, PlanState>(
      builder: (context, state) {
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatHeaderDate(),
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              greetingForTime(),
                              style: AppTextStyles.display,
                            ),
                          ],
                        ),
                      ),
                      if (kDebugMode)
                        AppTextButton(
                          label: 'UI Gallery',
                          onPressed: () => context.push(AppRoutes.devGallery),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!state.hasAnyPieces)
                    Expanded(
                      child: EmptyState(
                        title: 'Hôm nay bạn muốn tập gì?',
                        message: 'Thêm bản nhạc đầu tiên của bạn để bắt đầu.',
                        actionLabel: 'Thêm bản nhạc',
                        onAction: () => context.push(AppRoutes.pieceForm),
                      ),
                    )
                  else if (state.todayItems.isEmpty &&
                      state.smartResume == null)
                    Expanded(
                      child: EmptyState(
                        title: 'Hôm nay bạn muốn tập gì?',
                        message: 'Chọn vài đoạn để bắt đầu buổi tập.',
                        actionLabel: 'Lập kế hoạch',
                        onAction: () => context.push(AppRoutes.planForm),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        children: [
                          if (state.smartResume != null) ...[
                            ResumeCard(
                              sectionName: state.smartResume!.section.name,
                              pieceTitle: state.smartResume!.piece.title,
                              lastPracticedLabel: formatLastPracticedLabel(
                                state.smartResume!.section.lastPracticedAt,
                              ),
                              previousNote: state.smartResume!.latestEntry.note,
                              nextAction:
                                  state.smartResume!.latestEntry.nextAction ??
                                      state.smartResume!.section.nextAction,
                              onContinue: () =>
                                  context.push(AppRoutes.practiceSession),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kế hoạch hôm nay',
                                style: AppTextStyles.heading,
                              ),
                              AppTextButton(
                                label: 'Chỉnh sửa',
                                onPressed: () =>
                                    context.push(AppRoutes.planForm),
                              ),
                            ],
                          ),
                          if (state.todayItems.isNotEmpty) ...[
                            Text(
                              'Đã tập ${state.completedTodayCount} trên ${state.totalTodayCount} đoạn',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (final item in state.todayItems) ...[
                              _PlanItemCard(
                                view: item,
                                onToggle: () => context
                                    .read<PlanCubit>()
                                    .togglePlanItem(item),
                              ),
                              const SizedBox(height: AppSpacing.cardGap),
                            ],
                          ] else ...[
                            Text(
                              'Chưa có kế hoạch hôm nay.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          TonalButton(
                            label: 'Bắt đầu buổi tập',
                            expand: true,
                            onPressed: state.todayItems.isEmpty
                                ? null
                                : () => context.push(AppRoutes.practiceSession),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
    required this.view,
    required this.onToggle,
  });

  final TodayPlanItemView view;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDone = view.item.state == PlanItemState.done;
    final isHigh = view.item.priority == PlanItemPriority.high;
    final goal = view.item.goal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            checked: isDone,
            label: 'Đánh dấu đã tập ${view.section.name}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.textSecondary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textSecondary,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.onPrimary,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        view.section.name,
                        style: AppTextStyles.label.copyWith(
                          color: isDone
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (isHigh && !isDone) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          'Ưu tiên cao',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(view.piece.title, style: AppTextStyles.caption),
                if (goal != null && goal.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    goal,
                    style: AppTextStyles.body.copyWith(
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

