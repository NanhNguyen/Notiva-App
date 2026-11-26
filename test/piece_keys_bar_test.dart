import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/core/theme/app_theme.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/ui/widgets/piece_keys_bar.dart';

void main() {
  testWidgets('PieceKeysBar renders all 4 HandStatus levels and handles taps',
      (tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PieceKeysBar(
            statuses: const [
              HandStatus.notStarted,
              HandStatus.learning,
              HandStatus.solid,
              HandStatus.mastered,
            ],
            sectionLabels: const ['Mở đầu', 'Đoạn A', 'Đoạn B', 'Kết'],
            caption: '4 đoạn: 1 thuần thục, 1 khá ổn, 1 đang tập, 1 chưa tập',
            onKeyTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(
      find.text('4 đoạn: 1 thuần thục, 1 khá ổn, 1 đang tập, 1 chưa tập'),
      findsOneWidget,
    );

    // Verify semantic labels for each level.
    expect(
      find.bySemanticsLabel('Mở đầu, hai tay: chưa tập'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Đoạn A, hai tay: đang tập'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Đoạn B, hai tay: khá ổn'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Kết, hai tay: thuần thục'),
      findsOneWidget,
    );

    // Verify fill fractions for learning (1/3), solid (2/3), mastered (1.0).
    final fractions = tester
        .widgetList<AnimatedFractionallySizedBox>(
          find.byType(AnimatedFractionallySizedBox),
        )
        .map((w) => w.heightFactor)
        .toList();
    expect(fractions, equals([1 / 3, 2 / 3, 1.0]));

    // Tap the 3rd key (index 2).
    await tester.tap(find.bySemanticsLabel('Đoạn B, hai tay: khá ổn'));
    expect(tappedIndex, equals(2));
  });

  testWidgets('PieceKeysBar compact variant uses 20dp key height',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PieceKeysBar(
            statuses: [HandStatus.learning, HandStatus.mastered],
            compact: true,
          ),
        ),
      ),
    );

    final sizedBoxes = tester.widgetList<SizedBox>(
      find.descendant(
        of: find.byType(PieceKeysBar),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.height == 20.0),
      ),
    );
    expect(sizedBoxes.length, equals(2));
  });
}

