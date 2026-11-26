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
import '../../../data/repositories/section_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/models/entry.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/sections_cubit.dart';
import 'section_form_screen.dart';

/// A9 · Section Detail screen with live HandStatusStepper, next action,
/// tempo sparkline, difficulty/note/links, and history timeline.
class SectionDetailScreen extends StatelessWidget {
  const SectionDetailScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final sectionRepo = context.read<SectionRepository>();
    final sessionRepo = context.read<SessionRepository>();

    return StreamBuilder<Section?>(
      stream: sectionRepo.watchById(sectionId),
      builder: (context, sectionSnap) {
        if (sectionSnap.connectionState == ConnectionState.waiting &&
            !sectionSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final section = sectionSnap.data;
        if (section == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Không tìm thấy đoạn nhạc.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final location = formatSectionLocation(section);

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
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        semanticLabel: 'Quay lại',
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.name,
                              style: AppTextStyles.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (location.isNotEmpty)
                              Text(location, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CircleButton(
                        icon: Icons.edit_outlined,
                        semanticLabel: 'Sửa đoạn',
                        onTap: () => context.push(
                          AppRoutes.sectionForm,
                          extra: SectionFormArgs(
                            pieceId: section.pieceId,
                            section: section,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Entry>>(
                    stream: sessionRepo.watchEntriesForSection(section.id),
                    builder: (context, entrySnap) {
                      final entries = entrySnap.data ?? const <Entry>[];
                      final tempos = entries
                          .where((e) => e.tempo != null)
                          .map((e) => e.tempo!)
                          .toList()
                          .reversed
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: AppSpacing.md,
                        ),
                        children: [
                          const Text(
                            'Trạng thái hiện tại',
                            style: AppTextStyles.heading,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          HandStatusStepper(
                            rh: section.rhStatus,
                            lh: section.lhStatus,
                            ht: section.htStatus,
                            onChanged: (hand, level) {
                              context
                                  .read<SectionsCubit>()
                                  .updateHandStatus(section, hand, level);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _NextActionCard(
                            nextAction: section.nextAction,
                            onEdit: () => _editNextAction(context, section),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _TempoCard(tempos: tempos),
                          if (section.difficultyTags.isNotEmpty ||
                              (section.note != null &&
                                  section.note!.isNotEmpty) ||
                              section.links.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            _DetailsCard(section: section),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          const Text(
                            'Lịch sử luyện tập',
                            style: AppTextStyles.heading,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (entries.isEmpty)
                            Container(
                              padding:
                                  const EdgeInsets.all(AppSpacing.cardPadding),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Chưa có lịch sử luyện tập.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
                            for (final entry in entries) ...[
                              _EntryTimelineItem(entry: entry),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      );
                    },
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
                        label: 'Thêm vào hôm nay',
                        onPressed: () async {
                          final added = await context
                              .read<SectionsCubit>()
                              .addToToday(section);
                          if (!context.mounted) return;
                          showAppToast(
                            context,
                            message: added
                                ? 'Đã thêm vào hôm nay.'
                                : 'Đoạn này đã có trong kế hoạch hôm nay.',
                          );
                        },
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

  Future<void> _editNextAction(BuildContext context, Section section) async {
    final controller = TextEditingController(text: section.nextAction ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Việc tiếp theo', style: AppTextStyles.heading),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Tập chậm tay trái, 60 bpm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && context.mounted) {
      await context.read<SectionsCubit>().updateNextAction(section, result);
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
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

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({
    required this.nextAction,
    required this.onEdit,
  });

  final String? nextAction;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasValue = nextAction != null && nextAction!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Việc tiếp theo', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasValue ? nextAction! : 'Chưa đặt việc tiếp theo.',
                  style: hasValue
                      ? AppTextStyles.body
                      : AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                ),
              ],
            ),
          ),
          AppTextButton(label: 'Sửa', onPressed: onEdit),
        ],
      ),
    );
  }
}

class _TempoCard extends StatelessWidget {
  const _TempoCard({required this.tempos});

  final List<int> tempos;

  @override
  Widget build(BuildContext context) {
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
          Text('Tempo', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          if (tempos.isEmpty)
            Text(
              'Chưa có dữ liệu tempo.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Row(
              children: [
                Text('${tempos.last} bpm', style: AppTextStyles.heading),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: CustomPaint(
                      painter: _TempoSparklinePainter(tempos),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TempoSparklinePainter extends CustomPainter {
  _TempoSparklinePainter(this.tempos);

  final List<int> tempos;

  @override
  void paint(Canvas canvas, Size size) {
    if (tempos.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    if (tempos.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(center, 3.5, dotPaint);
      return;
    }

    var minT = tempos.first;
    var maxT = tempos.first;
    for (final t in tempos) {
      if (t < minT) minT = t;
      if (t > maxT) maxT = t;
    }
    final range = (maxT - minT).toDouble();

    final path = Path();
    for (var i = 0; i < tempos.length; i++) {
      final x = (i / (tempos.length - 1)) * size.width;
      final norm = range == 0 ? 0.5 : (tempos[i] - minT) / range;
      final y = size.height - 4 - norm * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TempoSparklinePainter oldDelegate) {
    return oldDelegate.tempos != tempos;
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
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
          if (section.difficultyTags.isNotEmpty) ...[
            Text('Điểm khó', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in section.difficultyTags)
                  AppChip(label: tag),
              ],
            ),
          ],
          if (section.note != null && section.note!.isNotEmpty) ...[
            if (section.difficultyTags.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            Text('Ghi chú', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(section.note!, style: AppTextStyles.body),
          ],
          if (section.links.isNotEmpty) ...[
            if (section.difficultyTags.isNotEmpty ||
                (section.note != null && section.note!.isNotEmpty))
              const SizedBox(height: AppSpacing.md),
            Text('Liên kết tham khảo', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            for (final link in section.links)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  link,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EntryTimelineItem extends StatelessWidget {
  const _EntryTimelineItem({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
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
              Text(entry.outcome.label, style: AppTextStyles.label),
              Text(
                formatLastPracticedLabel(entry.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (entry.tempo != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('${entry.tempo} bpm', style: AppTextStyles.caption),
          ],
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(entry.note!, style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

