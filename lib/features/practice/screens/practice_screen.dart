import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/enums/practice_outcome.dart';
import '../../../ui/widgets/widgets.dart';
import '../../repertoire/cubit/pieces_cubit.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';

/// A3 · Practice Session screen (no bottom navigation, active timer + queue).
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.initialSectionId});

  final String? initialSectionId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Timer? _ticker;
  DateTime _nowUtc = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    context
        .read<SessionCubit>()
        .startSession(initialSectionId: widget.initialSectionId);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _nowUtc = DateTime.now().toUtc());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mins:$secs';
    }
    return '$mins:$secs';
  }

  Future<void> _showAddExtraSectionSheet() async {
    final pieces = context.read<PiecesCubit>().state.allPieces;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppRadius.borderFull,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Thêm đoạn ngoài kế hoạch',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          for (final group in pieces)
                            if (group.sections.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                  bottom: AppSpacing.xs,
                                ),
                                child: Text(
                                  group.piece.title,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              for (final section in group.sections)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    section.name,
                                    style: AppTextStyles.body,
                                  ),
                                  trailing: const Icon(
                                    Icons.add,
                                    color: AppColors.primary,
                                  ),
                                  onTap: () {
                                    context
                                        .read<SessionCubit>()
                                        .addExtraSection(section, group.piece);
                                    Navigator.of(sheetContext).pop();
                                  },
                                ),
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEndSessionSheet(SessionState state) async {
    final elapsedMinutes =
        state.elapsedAt(DateTime.now().toUtc()).inMinutes.clamp(1, 300);
    var durationMinutes = elapsedMinutes;
    final noteController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: AppRadius.borderFull,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Kết thúc buổi tập',
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('Thời lượng', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      NumberStepper(
                        value: durationMinutes,
                        unit: 'phút',
                        min: 1,
                        max: 300,
                        step: 1,
                        onChanged: (v) =>
                            setSheetState(() => durationMinutes = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Cảm nhận chung (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Hôm nay buổi tập thế nào?',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Lưu buổi tập',
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final note = noteController.text;
    noteController.dispose();

    if (saved == true && mounted) {
      await context.read<SessionCubit>().endSession(
            durationMinutes: durationMinutes,
            note: note,
          );
      if (mounted) {
        showAppToast(context, message: 'Đã lưu buổi tập.');
        context.go(AppRoutes.today);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final elapsed = state.elapsedAt(_nowUtc);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đang tập', style: AppTextStyles.title),
                      Row(
                        children: [
                          _CircleControlButton(
                            icon: state.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            semanticLabel:
                                state.isPaused ? 'Tiếp tục' : 'Tạm dừng',
                            onTap: () =>
                                context.read<SessionCubit>().togglePause(),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _CircleControlButton(
                            icon: Icons.stop_rounded,
                            semanticLabel: 'Dừng buổi tập',
                            onTap: () => _showEndSessionSheet(state),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.cardPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isPaused ? 'Đang tạm dừng' : 'Thời gian tập',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _formatDuration(elapsed),
                            style: AppTextStyles.display.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (state.queue.isNotEmpty)
                        Text(
                          '${state.queue.where((q) => q.isDone).length}/${state.queue.length} đoạn',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: state.isStarting
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal,
                          ),
                          children: [
                            if (state.queue.isEmpty)
                              Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.cardPadding),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: AppRadius.borderMd,
                                ),
                                child: Text(
                                  'Chưa có đoạn nào trong buổi tập. Hãy thêm một đoạn để bắt đầu.',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              for (var i = 0; i < state.queue.length; i++) ...[
                                _PracticeQueueCard(
                                  item: state.queue[i],
                                  isCurrent: i == state.currentIndex,
                                  onSelect: () => context
                                      .read<SessionCubit>()
                                      .selectIndex(i),
                                  onLog: () => context.push(
                                    AppRoutes.practiceLog,
                                    extra: state.queue[i],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.cardGap),
                              ],
                            const SizedBox(height: AppSpacing.sm),
                            TonalButton(
                              label: 'Thêm đoạn ngoài kế hoạch',
                              expand: true,
                              onPressed: _showAddExtraSectionSheet,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                        vertical: AppSpacing.lg,
                      ),
                      child: PrimaryButton(
                        label: 'Kết thúc buổi tập',
                        onPressed: () => _showEndSessionSheet(state),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CircleControlButton extends StatelessWidget {
  const _CircleControlButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(icon, size: 24, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PracticeQueueCard extends StatelessWidget {
  const _PracticeQueueCard({
    required this.item,
    required this.isCurrent,
    required this.onSelect,
    required this.onLog,
  });

  final PracticeQueueItem item;
  final bool isCurrent;
  final VoidCallback onSelect;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final bgColor = item.isDone
        ? AppColors.surfaceVariant.withValues(alpha: 0.6)
        : (isCurrent ? AppColors.primaryContainer : AppColors.surface);
    final borderColor = isCurrent && !item.isDone
        ? AppColors.primary
        : AppColors.border;

    return InkWell(
      onTap: onSelect,
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.section.name,
                    style: AppTextStyles.heading.copyWith(
                      color: item.isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (item.loggedOutcome != null)
                  _OutcomeChip(outcome: item.loggedOutcome!),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(item.piece.title, style: AppTextStyles.caption),
            if (item.section.nextAction != null &&
                item.section.nextAction!.isNotEmpty &&
                !item.isDone) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.section.nextAction!,
                style: AppTextStyles.body,
              ),
            ],
            if (isCurrent && !item.isDone) ...[
              const SizedBox(height: AppSpacing.md),
              TonalButton(
                label: 'Ghi kết quả',
                expand: true,
                onPressed: onLog,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome});

  final PracticeOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (outcome) {
      PracticeOutcome.improved => (
          AppColors.outcomeImprovedBg,
          AppColors.outcomeImprovedText,
        ),
      PracticeOutcome.same => (
          AppColors.outcomeSameBg,
          AppColors.outcomeSameText,
        ),
      PracticeOutcome.difficult => (
          AppColors.outcomeDifficultBg,
          AppColors.outcomeDifficultText,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        outcome.label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

