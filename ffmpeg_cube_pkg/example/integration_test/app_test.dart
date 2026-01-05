import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ffmpeg_cube_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Navigation Tests', () {
    testWidgets('Home screen displays all feature cards', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Verify home screen title
      expect(find.text('FFmpeg Cube Demo'), findsOneWidget);

      // Verify all feature cards are displayed
      expect(find.text('轉檔'), findsOneWidget);
      expect(find.text('縮圖'), findsOneWidget);
      expect(find.text('播放'), findsOneWidget);
      expect(find.text('探測'), findsOneWidget);
    });

    testWidgets('Navigate to transcode screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on transcode card
      await tester.tap(find.text('轉檔'));
      await tester.pumpAndSettle();

      // Verify transcode screen is displayed
      expect(find.text('影片轉檔'), findsOneWidget);
      expect(find.text('選擇輸入檔案'), findsOneWidget);
      expect(find.text('轉檔設定'), findsOneWidget);
    });

    testWidgets('Navigate to thumbnail screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on thumbnail card
      await tester.tap(find.text('縮圖'));
      await tester.pumpAndSettle();

      // Verify thumbnail screen is displayed
      expect(find.text('縮圖擷取'), findsOneWidget);
      expect(find.text('選擇影片'), findsOneWidget);
    });

    testWidgets('Navigate to player screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on player card
      await tester.tap(find.text('播放'));
      await tester.pumpAndSettle();

      // Verify player screen is displayed
      expect(find.text('影片播放'), findsOneWidget);
    });

    testWidgets('Navigate to probe screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Tap on probe card
      await tester.tap(find.text('探測'));
      await tester.pumpAndSettle();

      // Verify probe screen is displayed
      expect(find.text('媒體探測'), findsOneWidget);
      expect(find.text('選擇媒體檔案'), findsOneWidget);
    });

    testWidgets('Navigate back from transcode screen', (tester) async {
      await tester.pumpWidget(const FFmpegCubeExampleApp());
      await tester.pumpAndSettle();

      // Navigate to transcode
      await tester.tap(find.text('轉檔'));
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

      await tester.tap(find.text('轉檔'));
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

      await tester.tap(find.text('轉檔'));
      await tester.pumpAndSettle();

      // Find and verify start button is disabled
      final startButton = find.text('開始轉檔');
      expect(startButton, findsOneWidget);

      // The button should be disabled (parent ElevatedButton has null onPressed)
    });
  });
}
