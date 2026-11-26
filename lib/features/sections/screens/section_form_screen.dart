import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/enums/difficulty_tags.dart';
import '../../../domain/models/section.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/sections_cubit.dart';

/// Arguments for opening [SectionFormScreen].
class SectionFormArgs {
  const SectionFormArgs({
    required this.pieceId,
    this.section,
  });

  final String pieceId;
  final Section? section;
}

/// A8 · Add or Edit Section screen with unsaved-changes guard.
class SectionFormScreen extends StatefulWidget {
  const SectionFormScreen({super.key, required this.args});

  final SectionFormArgs args;

  bool get isEditing => args.section != null;

  @override
  State<SectionFormScreen> createState() => _SectionFormScreenState();
}

class _SectionFormScreenState extends State<SectionFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _pageController;
  late final TextEditingController _measureStartController;
  late final TextEditingController _measureEndController;
  late final TextEditingController _noteController;
  late final TextEditingController _nextActionController;
  final TextEditingController _linkInputController = TextEditingController();

  late List<String> _selectedTags;
  late List<String> _links;
  String? _nameError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.args.section;
    _nameController = TextEditingController(text: s?.name ?? '');
    _pageController = TextEditingController(text: s?.pageRef ?? '');
    _measureStartController = TextEditingController(
      text: s?.measureStart?.toString() ?? '',
    );
    _measureEndController = TextEditingController(
      text: s?.measureEnd?.toString() ?? '',
    );
    _noteController = TextEditingController(text: s?.note ?? '');
    _nextActionController = TextEditingController(text: s?.nextAction ?? '');
    _selectedTags = List<String>.from(s?.difficultyTags ?? const []);
    _links = List<String>.from(s?.links ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _measureStartController.dispose();
    _measureEndController.dispose();
    _noteController.dispose();
    _nextActionController.dispose();
    _linkInputController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final s = widget.args.section;
    return _nameController.text != (s?.name ?? '') ||
        _pageController.text != (s?.pageRef ?? '') ||
        _measureStartController.text != (s?.measureStart?.toString() ?? '') ||
        _measureEndController.text != (s?.measureEnd?.toString() ?? '') ||
        _noteController.text != (s?.note ?? '') ||
        _nextActionController.text != (s?.nextAction ?? '') ||
        _selectedTags.join(',') != (s?.difficultyTags ?? const []).join(',') ||
        _links.join(',') != (s?.links ?? const []).join(',');
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

  void _addLink() {
    final raw = _linkInputController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _links.add(raw);
      _linkInputController.clear();
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Nhập tên đoạn.');
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final measureStart = int.tryParse(_measureStartController.text.trim());
    final measureEnd = int.tryParse(_measureEndController.text.trim());
    final cubit = context.read<SectionsCubit>();

    if (widget.isEditing) {
      await cubit.updateSection(
        widget.args.section!,
        name: name,
        pageRef: _pageController.text,
        measureStart: measureStart,
        measureEnd: measureEnd,
        difficultyTags: _selectedTags,
        note: _noteController.text,
        links: _links,
        nextAction: _nextActionController.text,
      );
    } else {
      await cubit.createSection(
        pieceId: widget.args.pieceId,
        name: name,
        pageRef: _pageController.text,
        measureStart: measureStart,
        measureEnd: measureEnd,
        difficultyTags: _selectedTags,
        note: _noteController.text,
        links: _links,
        nextAction: _nextActionController.text,
      );
    }

    if (mounted) {
      context.pop();
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
                      widget.isEditing ? 'Sửa đoạn' : 'Thêm đoạn',
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
                          text: 'Tên đoạn ',
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
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Giai điệu chính',
                          errorText: _nameError,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Từ ô nhịp',
                                  style: AppTextStyles.label,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _measureStartController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đến ô nhịp',
                                  style: AppTextStyles.label,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _measureEndController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '8',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trang',
                                  style: AppTextStyles.label,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _pageController,
                                  decoration: const InputDecoration(
                                    hintText: '1',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Điểm khó (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final tag in DifficultyTags.all)
                            AppChip(
                              label: tag,
                              selected: _selectedTags.contains(tag),
                              onTap: () {
                                setState(() {
                                  if (_selectedTags.contains(tag)) {
                                    _selectedTags.remove(tag);
                                  } else {
                                    _selectedTags.add(tag);
                                  }
                                });
                              },
                            ),
                        ],
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
                          hintText: 'Ví dụ: Chú ý ngón 4-5 ở ô nhịp 12',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Liên kết tham khảo (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _linkInputController,
                              keyboardType: TextInputType.url,
                              onSubmitted: (_) => _addLink(),
                              decoration: const InputDecoration(
                                hintText: 'https://...',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TonalButton(label: 'Thêm', onPressed: _addLink),
                        ],
                      ),
                      if (_links.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < _links.length; i++)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _links[i],
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _links.removeAt(i)),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Việc tiếp theo (không bắt buộc)',
                        style: AppTextStyles.label,
                      ),
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
                      label: 'Lưu đoạn',
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

