import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/piece_repository.dart';
import '../../data/repositories/section_repository.dart';
import '../../domain/enums/hand_status.dart';
import '../../domain/enums/piece_status.dart';
import '../../domain/enums/practice_outcome.dart';
import '../../ui/widgets/widgets.dart';

/// Debug-only gallery showcasing every shared widget in all states.
class DevGalleryScreen extends StatefulWidget {
  const DevGalleryScreen({super.key});

  @override
  State<DevGalleryScreen> createState() => _DevGalleryScreenState();
}

class _DevGalleryScreenState extends State<DevGalleryScreen> {
  final List<HandStatus> _pieceStatuses = [
    HandStatus.mastered,
    HandStatus.learning,
    HandStatus.solid,
    HandStatus.learning,
    HandStatus.notStarted,
    HandStatus.notStarted,
  ];

  HandStatus _rh = HandStatus.solid;
  HandStatus _lh = HandStatus.learning;
  HandStatus _ht = HandStatus.notStarted;

  HandStatus _logRh = HandStatus.solid;
  HandStatus _logLh = HandStatus.solid;
  HandStatus _logHt = HandStatus.learning;

  bool _chipSelected = true;
  PracticeOutcome _outcome = PracticeOutcome.improved;
  int _chartMode = 0;
  int _tempo = 64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UI Gallery (Debug)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          children: [
            _sectionTitle('0. Debug Data'),
            TonalButton(
              label: 'Seed sample data',
              expand: true,
              onPressed: _seedSampleData,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionTitle('1. PieceKeysBar (28dp & compact 20dp)'),
            PieceKeysBar(
              statuses: _pieceStatuses,
              caption: 'Chạm phím để đổi mức trạng thái (${_summary(_pieceStatuses)})',
              onKeyTap: (index) {
                setState(() {
                  final next = (_pieceStatuses[index].value + 1) % 4;
                  _pieceStatuses[index] = HandStatus.fromValue(next);
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            PieceKeysBar(
              statuses: _pieceStatuses,
              compact: true,
              caption: 'Compact 20dp',
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('2. HandStatusStepper (mặc định)'),
            HandStatusStepper(
              rh: _rh,
              lh: _lh,
              ht: _ht,
              onChanged: (hand, level) {
                setState(() {
                  switch (hand) {
                    case PracticeHand.rh:
                      _rh = level;
                    case PracticeHand.lh:
                      _lh = level;
                    case PracticeHand.ht:
                      _ht = level;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('3. HandStatusStepper (chế độ ghi kết quả - có Before)'),
            HandStatusStepper(
              rh: _logRh,
              lh: _logLh,
              ht: _logHt,
              beforeRh: HandStatus.solid,
              beforeLh: HandStatus.learning,
              beforeHt: HandStatus.notStarted,
              onChanged: (hand, level) {
                setState(() {
                  switch (hand) {
                    case PracticeHand.rh:
                      _logRh = level;
                    case PracticeHand.lh:
                      _logLh = level;
                    case PracticeHand.ht:
                      _logHt = level;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('4. HandStatusDots'),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HandStatusDots(
                  rh: HandStatus.notStarted,
                  lh: HandStatus.learning,
                  ht: HandStatus.solid,
                ),
                HandStatusDots(
                  rh: HandStatus.mastered,
                  lh: HandStatus.mastered,
                  ht: HandStatus.mastered,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('5. AppChip'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppChip(
                  label: _chipSelected ? 'Đã chọn' : 'Chưa chọn',
                  selected: _chipSelected,
                  onTap: () => setState(() => _chipSelected = !_chipSelected),
                ),
                const AppChip(label: 'Tĩnh (chưa chọn)', selected: false),
                const AppChip(label: 'Tĩnh (đã chọn)', selected: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('6. SegmentedControl (2 & 3 lựa chọn)'),
            SegmentedControl<int>(
              options: const [
                SegmentOption(value: 0, label: 'Buổi tập'),
                SegmentOption(value: 1, label: 'Tempo'),
              ],
              selected: _chartMode,
              onChanged: (v) => setState(() => _chartMode = v),
            ),
            const SizedBox(height: AppSpacing.md),
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

            _sectionTitle('7. NumberStepper'),
            NumberStepper(
              value: _tempo,
              unit: 'bpm',
              subtitle: 'Lần trước: 60 bpm',
              onChanged: (v) => setState(() => _tempo = v),
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('8. Buttons & Toast'),
            PrimaryButton(
              label: 'PrimaryButton (Lưu kết quả)',
              onPressed: () => showAppToast(
                context,
                message: 'Đã lưu buổi tập.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'TonalButton (Bắt đầu buổi tập)',
              expand: true,
              onPressed: () => showAppToast(
                context,
                message: 'Nhập tempo từ 20 đến 300 bpm.',
                isError: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AppTextButton(
                label: 'AppTextButton (Chỉnh sửa)',
                onPressed: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('9. ResumeCard'),
            ResumeCard(
              sectionName: 'Giai điệu chính',
              pieceTitle: 'Clair de Lune',
              lastPracticedLabel: 'Tập gần nhất: hôm qua',
              previousNote: 'Tay trái còn chưa đều ở ô nhịp 12.',
              nextAction: 'Tập chậm tay trái, 60 bpm',
              onContinue: () {},
            ),
            const SizedBox(height: AppSpacing.xl),

            _sectionTitle('10. EmptyState'),
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyState(
                title: 'Hôm nay bạn muốn tập gì?',
                message: 'Thêm bản nhạc đầu tiên của bạn để bắt đầu.',
                actionLabel: 'Thêm bản nhạc',
                onAction: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.heading),
    );
  }

  String _summary(List<HandStatus> list) {
    final counts = [0, 0, 0, 0];
    for (final s in list) {
      counts[s.value]++;
    }
    return '${list.length} đoạn: ${counts[3]} thuần thục, ${counts[2]} khá ổn, ${counts[1]} đang tập, ${counts[0]} chưa tập';
  }

  Future<void> _seedSampleData() async {
    final pieceRepo = context.read<PieceRepository>();
    final sectionRepo = context.read<SectionRepository>();
    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));

    final clair = await pieceRepo.create(
      title: 'Clair de Lune',
      composer: 'Claude Debussy',
      status: PieceStatus.learning,
    );

    final clairSections = <(String, HandStatus, HandStatus, HandStatus, DateTime?)>[
      ('Mở đầu', HandStatus.mastered, HandStatus.mastered, HandStatus.mastered, yesterday),
      ('Giai điệu chính', HandStatus.solid, HandStatus.learning, HandStatus.learning, yesterday),
      ('Ô nhịp 15 đến 26', HandStatus.solid, HandStatus.solid, HandStatus.solid, null),
      ('Đoạn arpeggio', HandStatus.learning, HandStatus.notStarted, HandStatus.learning, null),
      ('Cao trào', HandStatus.notStarted, HandStatus.notStarted, HandStatus.notStarted, null),
      ('Kết', HandStatus.notStarted, HandStatus.notStarted, HandStatus.notStarted, null),
    ];

    for (var i = 0; i < clairSections.length; i++) {
      final (name, rh, lh, ht, practicedAt) = clairSections[i];
      await sectionRepo.create(
        pieceId: clair.id,
        name: name,
        orderIndex: i,
        rhStatus: rh,
        lhStatus: lh,
        htStatus: ht,
        lastPracticedAt: practicedAt,
      );
    }

    await pieceRepo.create(
      title: 'Nocturne Op. 9 No. 2',
      composer: 'Frédéric Chopin',
      status: PieceStatus.learning,
    );
    await pieceRepo.create(
      title: 'Für Elise',
      composer: 'Ludwig van Beethoven',
      status: PieceStatus.maintaining,
    );
    await pieceRepo.create(
      title: 'Gymnopédie No. 1',
      composer: 'Erik Satie',
      status: PieceStatus.planned,
    );

    if (mounted) {
      showAppToast(context, message: 'Đã thêm 4 bản nhạc mẫu.');
    }
  }
}

