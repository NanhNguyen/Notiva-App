import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../domain/enums/piece_status.dart';
import '../../../domain/models/piece_with_sections.dart';
import '../../../ui/widgets/widgets.dart';
import '../cubit/pieces_cubit.dart';
import '../cubit/pieces_state.dart';

/// A5 · Repertoire screen with search, status filter chips, and piece cards.
class RepertoireScreen extends StatefulWidget {
  const RepertoireScreen({super.key});

  @override
  State<RepertoireScreen> createState() => _RepertoireScreenState();
}

class _RepertoireScreenState extends State<RepertoireScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PiecesCubit, PiecesState>(
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: state.hasAnyPieces
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.pieceForm),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 2,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderFull,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Thêm bản nhạc',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
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
                    AppStrings.repertoireTitle,
                    style: AppTextStyles.display,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!state.hasAnyPieces)
                    Expanded(
                      child: EmptyState(
                        title: AppStrings.repertoireEmptyTitle,
                        message: AppStrings.repertoireEmptySubtitle,
                        actionLabel: 'Thêm bản nhạc',
                        onAction: () => context.push(AppRoutes.pieceForm),
                      ),
                    )
                  else ...[
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          context.read<PiecesCubit>().setSearchQuery(value),
                      onClear: () {
                        _searchController.clear();
                        context.read<PiecesCubit>().setSearchQuery('');
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _StatusFilterRow(
                      selected: state.statusFilter,
                      onSelected: (status) =>
                          context.read<PiecesCubit>().setStatusFilter(status),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: state.filteredPieces.isEmpty
                          ? Center(
                              child: Text(
                                'Không tìm thấy bản nhạc phù hợp.',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: state.filteredPieces.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.cardGap),
                              itemBuilder: (context, index) {
                                final item = state.filteredPieces[index];
                                return _PieceCard(
                                  item: item,
                                  onTap: () => context.push(
                                    '${AppRoutes.pieceDetail}/${item.piece.id}',
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm bản nhạc',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 22,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Xóa tìm kiếm',
              )
            : null,
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selected,
    required this.onSelected,
  });

  final PieceStatus? selected;
  final ValueChanged<PieceStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = <(PieceStatus?, String)>[
      (null, 'Tất cả'),
      (PieceStatus.learning, PieceStatus.learning.label),
      (PieceStatus.maintaining, PieceStatus.maintaining.label),
      (PieceStatus.planned, PieceStatus.planned.label),
      (PieceStatus.completed, PieceStatus.completed.label),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final (status, label) = filters[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: AppChip(
              label: label,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
          );
        }),
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.item,
    required this.onTap,
  });

  final PieceWithSections item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final piece = item.piece;
    final composer = piece.composer;

    return Semantics(
      button: true,
      label: piece.title,
      child: InkWell(
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
                    child: Text(
                      piece.title,
                      style: AppTextStyles.heading,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusBadge(status: piece.status),
                ],
              ),
              if (composer != null && composer.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  composer,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (item.sections.isNotEmpty)
                PieceKeysBar(
                  statuses: item.htStatuses,
                  compact: true,
                  caption: item.sectionsSummaryCaption,
                )
              else
                Text(
                  item.sectionsSummaryCaption,
                  style: AppTextStyles.caption,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                formatLastPracticedLabel(item.lastPracticedAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PieceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      PieceStatus.learning => (AppColors.primaryContainer, AppColors.primary),
      PieceStatus.maintaining => (
          AppColors.outcomeImprovedBg,
          AppColors.outcomeImprovedText,
        ),
      PieceStatus.planned => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
        ),
      PieceStatus.completed => (
          AppColors.accentContainer,
          AppColors.textPrimary,
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
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

