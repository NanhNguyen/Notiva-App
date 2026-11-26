import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/section_formatters.dart';
import '../../../domain/enums/hand_status.dart';
import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/dashed_rect_painter.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/sections_cubit.dart';
import '../cubit/sections_state.dart';
import 'section_form_screen.dart';

/// A7 · Piece Detail screen with PieceKeysBar, legend, stats, and section list.
class PieceDetailScreen extends StatefulWidget {
  const PieceDetailScreen({super.key, required this.pieceId});

  final String pieceId;

  @override
  State<PieceDetailScreen> createState() => _PieceDetailScreenState();
}

class _PieceDetailScreenState extends State<PieceDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SectionsCubit>().watchPiece(widget.pieceId);
  }

  @override
  void didUpdateWidget(covariant PieceDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pieceId != widget.pieceId) {
      context.read<SectionsCubit>().watchPiece(widget.pieceId);
    }
  }

  Future<void> _showStatusPicker(Piece piece) async {
    final selected = await showModalBottomSheet<PieceStatus>(
      context: context,
      builder: (sheetContext) {
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
                const Text('Trạng thái bản nhạc', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.md),
                for (final status in PieceStatus.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(status.label, style: AppTextStyles.body),
                    trailing: status == piece.status
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(status),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.read<SectionsCubit>().updatePieceStatus(selected);
    }
  }

  Future<void> _handleAddToToday(Section section) async {
    final added = await context.read<SectionsCubit>().addToToday(section);
    if (!mounted) return;
    showAppToast(
      context,
      message: added
          ? 'Đã thêm vào hôm nay.'
          : 'Đoạn này đã có trong kế hoạch hôm nay.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SectionsCubit, SectionsState>(
      builder: (context, state) {
        final piece = state.piece;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        semanticLabel: 'Quay lại',
                        onTap: () => context.pop(),
                      ),
                      if (piece != null)
                        _CircleIconButton(
                          icon: Icons.more_vert,
                          semanticLabel: 'Tùy chọn bản nhạc',
                          onTap: () => context.push(
                            AppRoutes.pieceForm,
                            extra: piece,
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (piece == null)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Không tìm thấy bản nhạc.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                        vertical: AppSpacing.md,
                      ),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(piece.title, style: AppTextStyles.title),
                                  if (piece.composer != null &&
                                      piece.composer!.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      piece.composer!,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppChip(
                              label: piece.status.label,
                              selected: true,
                              onTap: () => _showStatusPicker(piece),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.sections.isNotEmpty)
                                PieceKeysBar(
                                  statuses: state.sections
                                      .map((s) => s.htStatus)
                                      .toList(),
                                  sectionLabels: state.sections
                                      .map((s) => s.name)
                                      .toList(),
                                  caption: state.sectionsSummaryCaption,
                                  onKeyTap: (index) {
                                    final section = state.sections[index];
                                    context.push(
                                      '${AppRoutes.sectionDetail}/${section.id}',
                                    );
                                  },
                                )
                              else
                                Text(
                                  'Chưa có đoạn nào. Thêm đoạn để theo dõi tiến độ từng phần.',
                                  style: AppTextStyles.caption,
                                ),
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              const _KeysLegendRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatLastPracticedLabel(state.lastPracticedAt),
                                style: AppTextStyles.caption,
                              ),
                              Text(
                                'Buổi tập: ${state.sessionCount}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Các đoạn', style: AppTextStyles.heading),
                            TonalButton(
                              label: 'Thêm đoạn',
                              onPressed: () => context.push(
                                AppRoutes.sectionForm,
                                extra: SectionFormArgs(pieceId: piece.id),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (state.sections.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.cardPadding),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppRadius.borderMd,
                            ),
                            child: Text(
                              'Chia bản nhạc thành các đoạn nhỏ giúp bạn tập trung hơn vào từng chỗ khó.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          for (final section in state.sections) ...[
                            _SectionCard(
                              section: section,
                              onTap: () => context.push(
                                '${AppRoutes.sectionDetail}/${section.id}',
                              ),
                              onAddToToday: () => _handleAddToToday(section),
                            ),
                            const SizedBox(height: AppSpacing.cardGap),
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
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
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

class _KeysLegendRow extends StatelessWidget {
  const _KeysLegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final status in HandStatus.values) _LegendItem(status: status),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.status});

  final HandStatus status;

  @override
  Widget build(BuildContext context) {
    final fraction = switch (status) {
      HandStatus.notStarted => 0.0,
      HandStatus.learning => 1 / 3,
      HandStatus.solid => 2 / 3,
      HandStatus.mastered => 1.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
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
                      child: ColoredBox(
                        color: AppColors.statusColors[status.value],
                      ),
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
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(status.label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onTap,
    required this.onAddToToday,
  });

  final Section section;
  final VoidCallback onTap;
  final VoidCallback onAddToToday;

  @override
  Widget build(BuildContext context) {
    final location = formatSectionLocation(section);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.name, style: AppTextStyles.heading),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(location, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                HandStatusDots(
                  rh: section.rhStatus,
                  lh: section.lhStatus,
                  ht: section.htStatus,
                ),
              ],
            ),
            if (section.difficultyTags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in section.difficultyTags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.borderFull,
                      ),
                      child: Text(tag, style: AppTextStyles.caption),
                    ),
                ],
              ),
            ],
            if (section.nextAction != null &&
                section.nextAction!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Việc tiếp theo: ${section.nextAction}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTextButton(
                label: 'Thêm vào hôm nay',
                onPressed: onAddToToday,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
