import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/enums/hand_status.dart';
import '../../../domain/enums/practice_outcome.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/session_cubit.dart';
import '../cubit/session_state.dart';

/// A4 · Log Result screen with smart defaults and single-transaction save.
class LogResultScreen extends StatefulWidget {
  const LogResultScreen({super.key, required this.item});

  final PracticeQueueItem item;

  @override
  State<LogResultScreen> createState() => _LogResultScreenState();
}

class _LogResultScreenState extends State<LogResultScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _nextActionController = TextEditingController();

  LogEntryDefaults? _defaults;
  late Set<String> _hands;
  int? _tempo;
  PracticeOutcome _outcome = PracticeOutcome.same;
  late HandStatus _rhAfter;
  late HandStatus _lhAfter;
  late HandStatus _htAfter;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.item.section;
    _hands = {'ht'};
    _rhAfter = s.rhStatus;
    _lhAfter = s.lhStatus;
    _htAfter = s.htStatus;
    _nextActionController.text = s.nextAction ?? '';

    context.read<SessionCubit>().loadDefaults(s).then((defaults) {
      if (!mounted) return;
      setState(() {
        _defaults = defaults;
        _hands = Set<String>.from(defaults.hands);
        _tempo = defaults.lastTempo;
        _outcome = defaults.outcome;
        _rhAfter = defaults.rh;
        _lhAfter = defaults.lh;
        _htAfter = defaults.ht;
        _nextActionController.text = defaults.nextAction ?? '';
      });
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _nextActionController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final d = _defaults;
    if (d == null) return false;
    return _noteController.text.isNotEmpty ||
        _nextActionController.text != (d.nextAction ?? '') ||
        _tempo != d.lastTempo ||
        _outcome != d.outcome ||
        _rhAfter != d.rh ||
        _lhAfter != d.lh ||
        _htAfter != d.ht ||
        _hands.length != d.hands.length ||
        !_hands.containsAll(d.hands);
  }

  Future<void> _handleAttemptClose() async {
    if (!_hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Bỏ thay đổi?', style: AppTextStyles.heading),
        content: const Text(
          'Kết quả buổi tập chưa được lưu.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Bỏ thay đổi',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      context.pop();
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await context.read<SessionCubit>().logEntry(
          item: widget.item,
          hands: _hands.isEmpty ? const ['ht'] : _hands.toList(),
          tempo: _tempo,
          outcome: _outcome,
          note: _noteController.text,
          nextAction: _nextActionController.text,
          rhAfter: _rhAfter,
          lhAfter: _lhAfter,
          htAfter: _htAfter,
        );

    await HapticFeedback.lightImpact();
    if (mounted) {
      showAppToast(context, message: 'Đã lưu kết quả.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item.section;
    final lastTempo = _defaults?.lastTempo;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleAttemptClose();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Quay lại',
                          child: InkWell(
                            onTap: _handleAttemptClose,
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
                              child: const Icon(Icons.arrow_back, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Text('Ghi kết quả', style: AppTextStyles.heading),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(s.name, style: AppTextStyles.heading),
                    Text(widget.item.piece.title, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bạn tập tay nào?', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _handChip('rh', 'Tay phải'),
                          _handChip('lh', 'Tay trái'),
                          _handChip('ht', 'Hai tay'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tempo (không bắt buộc)',
                            style: AppTextStyles.label,
                          ),
                          if (_tempo != null)
                            AppTextButton(
                              label: 'Bỏ tempo',
                              onPressed: () => setState(() => _tempo = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (_tempo == null)
                        TonalButton(
                          label: lastTempo != null
                              ? 'Ghi tempo (Lần trước: $lastTempo bpm)'
                              : 'Ghi tempo (bpm)',
                          onPressed: () =>
                              setState(() => _tempo = lastTempo ?? 60),
                        )
                      else
                        NumberStepper(
                          value: _tempo!,
                          unit: 'bpm',
                          min: 20,
                          max: 300,
                          step: 2,
                          subtitle: lastTempo != null
                              ? 'Lần trước: $lastTempo bpm'
                              : null,
                          onChanged: (v) => setState(() => _tempo = v),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Kết quả', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedControl<PracticeOutcome>(
                        options: const [
                          SegmentOption(
                            value: PracticeOutcome.improved,
                            label: 'Tiến bộ',
                            icon: Icons.check,
                            backgroundColor: AppColors.outcomeImprovedBg,
                            foregroundColor: AppColors.outcomeImprovedText,
                            selectedBorderColor: AppColors.outcomeImprovedText,
                          ),
                          SegmentOption(
                            value: PracticeOutcome.same,
                            label: 'Giữ nguyên',
                            backgroundColor: AppColors.outcomeSameBg,
                            foregroundColor: AppColors.outcomeSameText,
                            selectedBorderColor: AppColors.outcomeSameText,
                          ),
                          SegmentOption(
                            value: PracticeOutcome.difficult,
                            label: 'Vẫn khó',
                            backgroundColor: AppColors.outcomeDifficultBg,
                            foregroundColor: AppColors.outcomeDifficultText,
                            selectedBorderColor: AppColors.outcomeDifficultText,
                          ),
                        ],
                        selected: _outcome,
                        onChanged: (v) => setState(() => _outcome = v),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Cập nhật trạng thái',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      HandStatusStepper(
                        rh: _rhAfter,
                        lh: _lhAfter,
                        ht: _htAfter,
                        beforeRh: s.rhStatus,
                        beforeLh: s.lhStatus,
                        beforeHt: s.htStatus,
                        onChanged: (hand, level) {
                          setState(() {
                            switch (hand) {
                              case PracticeHand.rh:
                                _rhAfter = level;
                              case PracticeHand.lh:
                                _lhAfter = level;
                              case PracticeHand.ht:
                                _htAfter = level;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Ghi chú (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _noteController,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Điều gì đã tốt hơn? Điều gì còn khó?',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Việc tiếp theo', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _nextActionController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Tập chậm tay trái, 60 bpm',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
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
                      label: 'Lưu kết quả',
                      onPressed: _isSaving ? null : _handleSave,
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

  Widget _handChip(String code, String label) {
    final selected = _hands.contains(code);
    return AppChip(
      label: label,
      selected: selected,
      onTap: () {
        setState(() {
          if (selected && _hands.length > 1) {
            _hands.remove(code);
          } else {
            _hands.add(code);
          }
        });
      },
    );
  }
}

