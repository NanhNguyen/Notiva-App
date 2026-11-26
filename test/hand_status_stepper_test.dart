import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/core/theme/app_theme.dart';
import 'package:notiva/domain/enums/hand_status.dart';
import 'package:notiva/ui/widgets/hand_status_stepper.dart';

void main() {
  testWidgets('HandStatusStepper renders all 3 hands and updates each level',
      (tester) async {
    var rh = HandStatus.notStarted;
    var lh = HandStatus.learning;
    var ht = HandStatus.solid;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: HandStatusStepper(
                rh: rh,
                lh: lh,
                ht: ht,
                onChanged: (hand, level) {
                  setState(() {
                    switch (hand) {
                      case PracticeHand.rh:
                        rh = level;
                      case PracticeHand.lh:
                        lh = level;
                      case PracticeHand.ht:
                        ht = level;
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Tay phải (RH)'), findsOneWidget);
    expect(find.text('Tay trái (LH)'), findsOneWidget);
    expect(find.text('Hai tay (HT)'), findsOneWidget);

    expect(find.text('Chưa tập'), findsOneWidget);
    expect(find.text('Đang tập'), findsOneWidget);
    expect(find.text('Khá ổn'), findsOneWidget);

    // Tap "Thuần thục" on Tay phải (RH).
    await tester.tap(find.bySemanticsLabel('Tay phải (RH): Thuần thục'));
    await tester.pump();
    expect(rh, equals(HandStatus.mastered));
    expect(find.text('Thuần thục'), findsOneWidget);

    // Tap "Khá ổn" on Tay trái (LH).
    await tester.tap(find.bySemanticsLabel('Tay trái (LH): Khá ổn'));
    await tester.pump();
    expect(lh, equals(HandStatus.solid));

    // Tap "Chưa tập" on Hai tay (HT).
    await tester.tap(find.bySemanticsLabel('Hai tay (HT): Chưa tập'));
    await tester.pump();
    expect(ht, equals(HandStatus.notStarted));
  });

  testWidgets('HandStatusStepper shows before -> after diff when changed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HandStatusStepper(
            rh: HandStatus.solid,
            lh: HandStatus.solid,
            ht: HandStatus.learning,
            beforeRh: HandStatus.solid,
            beforeLh: HandStatus.learning,
            beforeHt: HandStatus.notStarted,
            onChanged: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.text('Khá ổn'), findsOneWidget);
    expect(find.text('Đang tập → Khá ổn'), findsOneWidget);
    expect(find.text('Chưa tập → Đang tập'), findsOneWidget);
    // Two rows changed from before, so two faded Opacity(0.45) "before" keys.
    expect(
      find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0.45),
      findsNWidgets(2),
    );
  });
}

