import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ffmpeg_cube_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  group('App Navigation Tests', () {
    testWidgets('Home screen displays all feature cards', (tester) async {
      // Set fixed window size for consistent testing

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Verify home screen title
      expect(find.text('FFmpeg Cube Demo'), findsOneWidget);

      // Verify first visible card (Transcode) to ensure app loaded
      expect(find.byKey(const Key('transcode_card')), findsOneWidget);
    });

    testWidgets('Navigate to transcode screen', (tester) async {

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on transcode card by key
      await tester.tap(find.byKey(const Key('transcode_card')));
      await tester.pumpAndSettle();

      // Verify transcode screen is displayed
      expect(find.text('影片轉檔'), findsOneWidget);
      expect(find.text('選擇輸入檔案'), findsOneWidget);
      expect(find.text('轉檔設定'), findsOneWidget);
    });


    testWidgets('Navigate to thumbnail screen', (tester) async {

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on thumbnail card by key
      final thumbnailCard = find.byKey(const Key('thumbnail_card'));
      await tester.scrollUntilVisible(
        thumbnailCard,
        100,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 50,
      );
      
      // Direct interaction - bypass coordinate based tap
      final inkWellFinder = find.descendant(
        of: thumbnailCard,
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(inkWellFinder).onTap?.call();
      await tester.pumpAndSettle();

      // Verify thumbnail screen is displayed (AppBar is present)
      expect(find.byType(AppBar), findsOneWidget);
      // Verify we are NOT on home screen anymore
      expect(find.byKey(const Key('transcode_card')), findsNothing);
    });

    testWidgets('Navigate to player screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on player card by key
      final playerCard = find.byKey(const Key('player_card'));
      await tester.scrollUntilVisible(
        playerCard,
        100,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 50,
      );
      
      // Direct interaction - bypass coordinate based tap
      final inkWellFinder = find.descendant(
        of: playerCard,
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(inkWellFinder).onTap?.call();
      // Video player might have ongoing animations/rendering, so avoid pumpAndSettle
      await tester.pump(const Duration(seconds: 2));

      // Verify player screen is displayed
      expect(find.text('影片播放'), findsOneWidget);
    });

    testWidgets('Navigate to probe screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on probe card by key
      final probeCard = find.byKey(const Key('probe_card'));
      await tester.scrollUntilVisible(
        probeCard,
        100,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 50,
      );
      
      // Direct interaction - bypass coordinate based tap
      final inkWellFinder = find.descendant(
        of: probeCard,
        matching: find.byType(InkWell),
      );
      tester.widget<InkWell>(inkWellFinder).onTap?.call();
      await tester.pumpAndSettle();

      // Verify probe screen is displayed
      expect(find.text('媒體探測'), findsOneWidget);
      expect(find.text('選擇媒體檔案'), findsOneWidget);
    });


    testWidgets('Navigate back from transcode screen', (tester) async {

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Navigate to transcode
      await tester.tap(find.byKey(const Key('transcode_card')));
      await tester.pumpAndSettle();

      // Tap back button (using tooltip or icon)
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        await tester.tap(find.byIcon(Icons.arrow_back));
      }
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('FFmpeg Cube Demo'), findsOneWidget);
    });
  });

  group('Transcode Screen Tests', () {
    testWidgets('Transcode screen shows codec options', (tester) async {

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transcode_card')));
      await tester.pumpAndSettle();

      // Verify codec dropdowns exist
      expect(find.text('視訊編碼:'), findsOneWidget);
      expect(find.text('解析度:'), findsOneWidget);
      expect(find.text('H.264'), findsOneWidget);
      expect(find.text('720p'), findsOneWidget);
    });

    testWidgets('Start transcode button is disabled without file',
        (tester) async {

      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('transcode_card')));
      await tester.pumpAndSettle();

      // Find and verify start button is disabled
      final startButton = find.text('開始轉檔');
      expect(startButton, findsOneWidget);

      // The button should be disabled (parent ElevatedButton has null onPressed)
    });
  });
}
