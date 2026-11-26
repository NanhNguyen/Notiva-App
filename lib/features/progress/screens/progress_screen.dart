import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../domain/enums/hand_status.dart';
import '../../../domain/enums/practice_outcome.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/progress_models.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/dashed_rect_painter.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/progress_cubit.dart';
import '../cubit/progress_state.dart';
import '../widgets/tempo_line_chart.dart';

/// A10 · Progress screen with "Buổi tập" and "Tempo" views.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
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
                  const Text(
                    AppStrings.progressTitle,
                    style: AppTextStyles.display,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedControl<ProgressTabMode>(
                    options: const [
                      SegmentOption(
                        value: ProgressTabMode.sessions,
                        label: 'Buổi tập',
                      ),
                      SegmentOption(
                        value: ProgressTabMode.tempo,
                        label: 'Tempo',
                      ),
                    ],
                    selected: state.tabMode,
                    onChanged: (mode) =>
                        context.read<ProgressCubit>().setTabMode(mode),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.tabMode == ProgressTabMode.sessions)
                    Expanded(child: _SessionsView(snapshot: state.snapshot))
                  else
                    Expanded(child: _TempoView(state: state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionsView extends StatelessWidget {
  const _SessionsView({required this.snapshot});

  final ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final week = snapshot.thisWeek;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        // 1. Plain-text "Tuần này" summary card
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tuần này', style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.xs),
              Text(
                week.sessionCount == 0
                    ? 'Chưa có buổi tập nào trong tuần này.'
                    : '${week.sessionCount} buổi tập · ${week.totalMinutes} phút',
                style: AppTextStyles.body.copyWith(
                  color: week.sessionCount == 0
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. "Thay đổi gần đây" card
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thay đổi gần đây', style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.sm),
              if (snapshot.recentStatusChanges.isEmpty)
                Text(
                  'Chưa có thay đổi trạng thái nào.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (var i = 0;
                    i < snapshot.recentStatusChanges.length;
                    i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _StatusChangeRow(item: snapshot.recentStatusChanges[i]),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 3. Session history grouped by date
        const Text('Lịch sử buổi tập', style: AppTextStyles.heading),
        const SizedBox(height: AppSpacing.md),
        if (snapshot.sessionHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              'Chưa có buổi tập nào được ghi lại.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          for (final group in snapshot.sessionHistory) ...[
            _SessionHistoryCard(group: group),
            const SizedBox(height: AppSpacing.cardGap),
          ],
      ],
    );
  }
}

class _StatusChangeRow extends StatelessWidget {
  const _StatusChangeRow({required this.item});

  final StatusChangeItem item;

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final changes = <(String, HandStatus, HandStatus)>[
      if (e.rhBefore != e.rhAfter) ('RH', e.rhBefore, e.rhAfter),
      if (e.lhBefore != e.lhAfter) ('LH', e.lhBefore, e.lhAfter),
      if (e.htBefore != e.htAfter) ('HT', e.htBefore, e.htAfter),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.section.name, style: AppTextStyles.label),
        Text(item.piece.title, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (hand, before, after) in changes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$hand: ', style: AppTextStyles.caption),
                  _MiniStatusKey(status: before),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _MiniStatusKey(status: after),
                  const SizedBox(width: 4),
                  Text(after.label, style: AppTextStyles.caption),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatusKey extends StatelessWidget {
  const _MiniStatusKey({required this.status});

  final HandStatus status;

  @override
  Widget build(BuildContext context) {
    final fraction = switch (status) {
      HandStatus.notStarted => 0.0,
      HandStatus.learning => 1 / 3,
      HandStatus.solid => 2 / 3,
      HandStatus.mastered => 1.0,
    };

    return SizedBox(
      width: 12,
      height: 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderSm,
              border: status == HandStatus.notStarted
                  ? null
                  : Border.all(
                      color: status == HandStatus.mastered
                          ? AppColors.statusMastered
                          : AppColors.border,
                      width: 1,
                    ),
            ),
          ),
          if (fraction > 0)
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fraction,
                  widthFactor: 1.0,
                  child: ColoredBox(color: AppColors.statusColors[status.value]),
                ),
              ),
            ),
          if (status == HandStatus.notStarted)
            const CustomPaint(
              painter: DashedRRectPainter(
                color: AppColors.statusNotStarted,
                radius: AppRadius.sm,
                strokeWidth: 1,
                dashWidth: 2,
                dashGap: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.group});

  final SessionHistoryGroup group;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(group.session.date);
    final dateLabel =
        parsedDate != null ? formatHeaderDate(parsedDate) : group.session.date;
    final mins = group.session.durationMinutes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateLabel, style: AppTextStyles.label),
              if (mins != null)
                Text('$mins phút', style: AppTextStyles.caption),
            ],
          ),
          if (group.session.note != null &&
              group.session.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              group.session.note!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (group.entries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final e in group.entries)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${e.section.name} · ${e.piece.title}',
                        style: AppTextStyles.body,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _OutcomeBadge(outcome: e.entry.outcome),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.outcome});

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

class _TempoView extends StatelessWidget {
  const _TempoView({required this.state});

  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final allSections = <(PieceWithSections, Section)>[
      for (final p in state.piecesWithSections)
        for (final s in p.sections) (p, s),
    ];

    if (allSections.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đoạn nhạc nào.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final selectedPair = allSections.firstWhere(
      (pair) => pair.$2.id == state.selectedSectionId,
      orElse: () => allSections.first,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const Text('Chọn đoạn', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () => _pickSection(context, allSections),
          borderRadius: AppRadius.borderSm,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedPair.$2.name, style: AppTextStyles.label),
                      Text(
                        selectedPair.$1.piece.title,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.tempoPoints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu tempo cho đoạn này.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  '${state.tempoPoints.last.tempo} bpm',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.md),
                TempoLineChart(points: state.tempoPoints),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tempo bạn tự ghi lại. Đây là số đo, không phải điểm chất lượng.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickSection(
    BuildContext context,
    List<(PieceWithSections, Section)> pairs,
  ) async {
    final chosenId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (_, controller) => SafeArea(
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
                  const Text('Chọn đoạn nhạc', style: AppTextStyles.heading),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: pairs.length,
                      itemBuilder: (_, index) {
                        final (pieceGroup, section) = pairs[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(section.name, style: AppTextStyles.body),
                          subtitle: Text(
                            pieceGroup.piece.title,
                            style: AppTextStyles.caption,
                          ),
                          trailing: section.id == state.selectedSectionId
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(sheetContext).pop(section.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosenId != null && context.mounted) {
      context.read<ProgressCubit>().selectTempoSection(chosenId);
    }
  }
}

