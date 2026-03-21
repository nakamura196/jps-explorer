import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jps_explorer/main.dart' as app;

/// スクリーンショット保存ディレクトリ
final ssDir = Platform.environment['SCREENSHOT_DIR'] ?? '/tmp/jps_screenshots';

/// スクリーンショットを撮影してファイルに保存する
Future<void> takeAndSave(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
  final bytes = await binding.takeScreenshot(name);
  final dir = Directory(ssDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('$ssDir/$name.png').writeAsBytesSync(bytes);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture all screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // === Screen 1: Explore tab (home) ===
    await takeAndSave(binding, tester, '01_explore');

    // === Screen 2: Search results ===
    // Tap on a sample chip (e.g. 鶴 or first ActionChip)
    final chips = find.byType(ActionChip);
    if (chips.evaluate().isNotEmpty) {
      await tester.tap(chips.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
    await takeAndSave(binding, tester, '02_search');

    // === Screen 3: Item detail ===
    // Tap first Card in search results
    final cards = find.byType(Card);
    if (cards.evaluate().length > 1) {
      await tester.tap(cards.at(1)); // skip DailyPickCard
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeAndSave(binding, tester, '03_detail');

      // Go back
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
      } else {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    }

    // === Screen 4: Map tab ===
    final navBar = find.byType(NavigationBar);
    if (navBar.evaluate().isNotEmpty) {
      // Tap Map tab (index 1)
      final mapIcon = find.byIcon(Icons.map);
      if (mapIcon.evaluate().isNotEmpty) {
        await tester.tap(mapIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
    await takeAndSave(binding, tester, '04_map');

    // === Screen 5: Gallery tab ===
    final galleryIcon = find.byIcon(Icons.collections);
    if (galleryIcon.evaluate().isNotEmpty) {
      await tester.tap(galleryIcon.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }
    await takeAndSave(binding, tester, '05_gallery');
  });
}
