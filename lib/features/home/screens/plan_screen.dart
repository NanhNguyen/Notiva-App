import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/enums/plan_item_priority.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../domain/models/plan_selection_draft.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/plan_cubit.dart';

/// A2 · Plan screen: select sections across pieces, set goals and priorities.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final Map<String, _SectionDraftState> _selected = {};
  final Set<String> _expandedPieceIds = {};
  Set<String> _carryOverIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PlanCubit>();
    final state = cubit.state;

    for (final item in state.todayItems) {
      _selected[item.section.id] = _SectionDraftState(
        goalController: TextEditingController(text: item.item.goal ?? ''),
        priority: item.item.priority,
      );
      _expandedPieceIds.add(item.piece.id);
    }

    if (_expandedPieceIds.isEmpty && state.piecesWithSections.isNotEmpty) {
      _expandedPieceIds.add(state.piecesWithSections.first.piece.id);
    }

    cubit.loadCarryOverSectionIds().then((ids) {
      if (mounted) {
        setState(() => _carryOverIds = ids);
      }
    });
  }

  @override
  void dispose() {
    for (final draft in _selected.values) {
      draft.goalController.dispose();
    }
    super.dispose();
  }

  void _toggleSection(Section section) {
    setState(() {
      if (_selected.containsKey(section.id)) {
        _selected.remove(section.id)?.goalController.dispose();
      } else {
        _selected[section.id] = _SectionDraftState(
          goalController: TextEditingController(text: section.nextAction ?? ''),
          priority: PlanItemPriority.normal,
        );
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final drafts = _selected.entries
        .map(
          (entry) => PlanSelectionDraft(
            sectionId: entry.key,
            goal: entry.value.goalController.text,
            priority: entry.value.priority,
          ),
        )
        .toList();

    await context.read<PlanCubit>().savePlan(drafts);
    if (mounted) {
      showAppToast(context, message: 'Đã lưu kế hoạch.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pieces = context.watch<PlanCubit>().state.piecesWithSections;

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
                children: [
                  Semantics(
                    button: true,
                    label: 'Đóng',
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: AppRadius.borderFull,
                      child: Container(
                        width: AppSpacing.minTouchTarget,
                        height: AppSpacing.minTouchTarget,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.close, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Lập kế hoạch', style: AppTextStyles.title),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                itemCount: pieces.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.cardGap),
                itemBuilder: (context, index) {
                  final group = pieces[index];
                  final isExpanded = _expandedPieceIds.contains(group.piece.id);
                  return _PieceGroupCard(
                    group: group,
                    isExpanded: isExpanded,
                    selected: _selected,
                    carryOverIds: _carryOverIds,
                    onToggleExpand: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedPieceIds.remove(group.piece.id);
                        } else {
                          _expandedPieceIds.add(group.piece.id);
                        }
                      });
                    },
                    onToggleSection: _toggleSection,
                    onPriorityChanged: (sectionId, priority) {
                      setState(() {
                        _selected[sectionId]?.priority = priority;
                      });
                    },
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
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đã chọn ${_selected.length} đoạn',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        label: 'Lưu kế hoạch',
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDraftState {
  _SectionDraftState({
    required this.goalController,
    required this.priority,
  });

  final TextEditingController goalController;
  PlanItemPriority priority;
}

class _PieceGroupCard extends StatelessWidget {
  const _PieceGroupCard({
    required this.group,
    required this.isExpanded,
    required this.selected,
    required this.carryOverIds,
    required this.onToggleExpand,
    required this.onToggleSection,
    required this.onPriorityChanged,
  });

  final PieceWithSections group;
  final bool isExpanded;
  final Map<String, _SectionDraftState> selected;
  final Set<String> carryOverIds;
  final VoidCallback onToggleExpand;
  final ValueChanged<Section> onToggleSection;
  final void Function(String sectionId, PlanItemPriority priority)
      onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            borderRadius: AppRadius.borderMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.piece.title,
                          style: AppTextStyles.heading,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  if (group.sections.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    PieceKeysBar(
                      statuses: group.htStatuses,
                      compact: true,
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Chưa có đoạn', style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded && group.sections.isNotEmpty) ...[
            const Divider(height: 1),
            for (final section in group.sections)
              _SelectableSectionRow(
                section: section,
                draft: selected[section.id],
                isCarriedOver: carryOverIds.contains(section.id),
                onToggle: () => onToggleSection(section),
                onPriorityChanged: (p) => onPriorityChanged(section.id, p),
              ),
          ],
        ],
      ),
    );
  }
}

class _SelectableSectionRow extends StatelessWidget {
  const _SelectableSectionRow({
    required this.section,
    required this.draft,
    required this.isCarriedOver,
    required this.onToggle,
    required this.onPriorityChanged,
  });

  final Section section;
  final _SectionDraftState? draft;
  final bool isCarriedOver;
  final VoidCallback onToggle;
  final ValueChanged<PlanItemPriority> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = draft != null;
    final nextAction = section.nextAction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.cardPadding,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.borderSm,
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(section.name, style: AppTextStyles.label),
                ),
                if (isCarriedOver) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.accentContainer,
                      borderRadius: AppRadius.borderFull,
                    ),
                    child: Text(
                      'Dời từ hôm qua',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: draft!.goalController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Mục tiêu buổi tập (không bắt buộc)',
                    ),
                  ),
                  if (nextAction != null && nextAction.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: () {
                        draft!.goalController.text = nextAction;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          'Gợi ý: $nextAction',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedControl<PlanItemPriority>(
                    options: [
                      SegmentOption(
                        value: PlanItemPriority.normal,
                        label: PlanItemPriority.normal.label,
                      ),
                      SegmentOption(
                        value: PlanItemPriority.high,
                        label: PlanItemPriority.high.label,
                      ),
                    ],
                    selected: draft!.priority,
                    onChanged: onPriorityChanged,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

