import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notiva/core/strings/app_strings.dart';
import 'package:notiva/data/database/app_database.dart';
import 'package:notiva/data/helpers/clock.dart';
import 'package:notiva/data/helpers/id_generator.dart';
import 'package:notiva/main.dart';

void main() {
  testWidgets('App renders 3-tab shell and switches tabs', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      NotivaApp(
        db: db,
        idGenerator: UuidIdGenerator(),
        clock: const SystemAppClock(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text(AppStrings.navToday), findsOneWidget);
    expect(find.text(AppStrings.navRepertoire), findsOneWidget);
    expect(find.text(AppStrings.navProgress), findsOneWidget);
    expect(find.text(AppStrings.todayEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navRepertoire));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text(AppStrings.repertoireEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.navProgress));
    await tester.pump();
    expect(find.text(AppStrings.progressEmptyTitle), findsOneWidget);

    // Unmount widget tree, flush Drift's cleanup timer, and close DB in real async zone.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.runAsync(() => db.close());
  });
}
