import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/pieces_cubit.dart';

/// A6 · Add or Edit Piece screen with validation, delete sheet, and unsaved guard.
class PieceFormScreen extends StatefulWidget {
  const PieceFormScreen({super.key, this.piece});

  final Piece? piece;

  bool get isEditing => piece != null;

  @override
  State<PieceFormScreen> createState() => _PieceFormScreenState();
}

class _PieceFormScreenState extends State<PieceFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _composerController;
  late PieceStatus _status;
  String? _titleError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.piece?.title ?? '');
    _composerController =
        TextEditingController(text: widget.piece?.composer ?? '');
    _status = widget.piece?.status ?? PieceStatus.learning;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final initialTitle = widget.piece?.title ?? '';
    final initialComposer = widget.piece?.composer ?? '';
    final initialStatus = widget.piece?.status ?? PieceStatus.learning;
    return _titleController.text != initialTitle ||
        _composerController.text != initialComposer ||
        _status != initialStatus;
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
          'Những thông tin bạn vừa nhập chưa được lưu.',
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
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Nhập tên bản nhạc.');
      return;
    }

    setState(() {
      _titleError = null;
      _isSaving = true;
    });

    final cubit = context.read<PiecesCubit>();
    if (widget.isEditing) {
      await cubit.updatePiece(
        widget.piece!,
        title: title,
        composer: _composerController.text,
        status: _status,
      );
    } else {
      await cubit.createPiece(
        title: title,
        composer: _composerController.text,
        status: _status,
      );
    }

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _handleDeletePressed() async {
    final piece = widget.piece;
    if (piece == null) return;

    final confirmed = await showModalBottomSheet<bool>(
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
                Text('Xóa ${piece.title}?', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Các đoạn và lịch sử luyện tập của bản nhạc này cũng sẽ bị xóa.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(0, 52),
                      side: const BorderSide(color: AppColors.border, width: 1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderFull,
                      ),
                    ),
                    child: Text(
                      'Xóa',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: Text(
                      'Hủy',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
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

    if (confirmed == true && mounted) {
      await context.read<PiecesCubit>().deletePiece(piece.id);
      if (mounted) {
        showAppToast(context, message: 'Đã xóa ${piece.title}.');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          child: const Icon(Icons.close, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      widget.isEditing ? 'Sửa bản nhạc' : 'Thêm bản nhạc',
                      style: AppTextStyles.title,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Tên bản nhạc ',
                          style: AppTextStyles.label,
                          children: [
                            TextSpan(
                              text: '*',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) {
                          if (_titleError != null) {
                            setState(() => _titleError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Clair de Lune',
                          errorText: _titleError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Tác giả (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _composerController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Claude Debussy',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text('Trạng thái', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      _StatusGrid(
                        selected: _status,
                        onSelected: (value) => setState(() => _status = value),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (!widget.isEditing)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Text(
                            'Bạn có thể chia bản nhạc thành các đoạn ở bước tiếp theo.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: AppTextButton(
                            label: 'Xóa bản nhạc',
                            isDestructive: true,
                            onPressed: _handleDeletePressed,
                          ),
                        ),
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
                      label: 'Lưu bản nhạc',
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
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.selected,
    required this.onSelected,
  });

  final PieceStatus selected;
  final ValueChanged<PieceStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    const rows = [
      [PieceStatus.planned, PieceStatus.learning],
      [PieceStatus.maintaining, PieceStatus.completed],
    ];

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          Row(
            children: [
              Expanded(
                child: _StatusOptionPill(
                  status: rows[r][0],
                  selected: selected == rows[r][0],
                  onTap: () => onSelected(rows[r][0]),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatusOptionPill(
                  status: rows[r][1],
                  selected: selected == rows[r][1],
                  onTap: () => onSelected(rows[r][1]),
                ),
              ),
            ],
          ),
          if (r == 0) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StatusOptionPill extends StatelessWidget {
  const _StatusOptionPill({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final PieceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: status.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: AppRadius.borderFull,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            status.label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

