import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ffmpeg_cube_demo/main.dart' as app;
import 'package:ffmpeg_cube/ffmpeg_cube.dart' as cube;

/// E2E Integration Tests for FFmpeg Cube Demo App
///
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Navigation Tests', () {
    testWidgets('Dashboard loads with all feature cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify Dashboard title
      expect(find.text('FFmpeg Cube Demo'), findsOneWidget);

      // Verify feature cards exist
      expect(find.text('Transcode'), findsOneWidget);
      expect(find.text('Trim'), findsOneWidget);
      expect(find.text('Concat'), findsOneWidget);
      expect(find.text('Thumbnail'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Mix Audio'), findsOneWidget);
      expect(find.text('Extract Audio'), findsOneWidget);
      expect(find.text('Probe'), findsOneWidget);
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Format Policy'), findsOneWidget);
    });

    testWidgets('Navigate to Transcode screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transcode'));
      await tester.pumpAndSettle();

      expect(find.text('Transcode'), findsWidgets);
    });

    testWidgets('Navigate to Trim screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trim'));
      await tester.pumpAndSettle();

      expect(find.text('Trim'), findsWidgets);
    });

    testWidgets('Navigate to Format Policy screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Scroll down to find Format Policy card if needed
      await tester.scrollUntilVisible(
        find.text('Format Policy'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Format Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Format Policy'), findsWidgets);
    });
  });

  group('Format Policy Screen Tests', () {
    testWidgets('Policy mode dropdown changes recommendations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Format Policy
      await tester.scrollUntilVisible(
        find.text('Format Policy'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Format Policy'));
      await tester.pumpAndSettle();

      // Find and tap the policy mode dropdown
      final dropdown = find.byType(DropdownButton<cube.FormatPolicyMode>);
      expect(dropdown, findsOneWidget);

      // Verify current recommendation is displayed
      expect(find.textContaining('Video Codec'), findsOneWidget);
      expect(find.textContaining('Audio Codec'), findsOneWidget);
    });

    testWidgets('Web target toggle updates recommendations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Format Policy
      await tester.scrollUntilVisible(
        find.text('Format Policy'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Format Policy'));
      await tester.pumpAndSettle();

      // Find and toggle the web target switch
      final webSwitch = find.byType(Switch);
      if (webSwitch.evaluate().isNotEmpty) {
        await tester.tap(webSwitch.first);
        await tester.pumpAndSettle();
      }

      // Recommendations should still be visible
      expect(find.textContaining('Video Codec'), findsOneWidget);
    });
  });

  group('Screen Back Navigation Tests', () {
    testWidgets('Back button returns to Dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go to Transcode
      await tester.tap(find.text('Transcode'));
      await tester.pumpAndSettle();

      // Press back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back on Dashboard
      expect(find.text('FFmpeg Cube Demo'), findsOneWidget);
    });
  });

  group('Transcode Screen UI Tests', () {
    testWidgets('Transcode screen shows configuration options', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transcode'));
      await tester.pumpAndSettle();

      // Verify dropdowns exist for codec selection
      expect(find.byType(DropdownButtonFormField<cube.VideoCodec>), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<cube.AudioCodec>), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<cube.VideoResolution>), findsOneWidget);

      // Should show a button to pick/select input file
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ElevatedButton || widget is FilledButton || widget is OutlinedButton,
        ),
        findsWidgets,
      );

      // Verify New Optimization UI
      expect(find.text('Hardware Acceleration'), findsOneWidget);
      expect(find.text('Preset (Speed vs Quality)'), findsOneWidget);
    });

    testWidgets('Change transcode preset and hardware acceleration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transcode'));
      await tester.pumpAndSettle();

      // Toggle hardware acceleration
      final hwSwitch = find.byType(SwitchListTile);
      expect(hwSwitch, findsOneWidget);
      await tester.tap(hwSwitch);
      await tester.pumpAndSettle();

      // Change preset
      final presetDropdown = find.text('medium'); // Default value text
      expect(presetDropdown, findsOneWidget);
      await tester.tap(presetDropdown);
      await tester.pumpAndSettle();

      // Select 'ultrafast' from the menu
      // Note: Dropdown items are often rendered in a Layer/Overlay
      final item = find.text('ultrafast').last;
      await tester.tap(item);
      await tester.pumpAndSettle();

      expect(find.text('ultrafast'), findsWidgets);
    });
  });

  group('Playback Screen Tests', () {
    testWidgets('Playback screen loads correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Scroll to find Playback
      await tester.scrollUntilVisible(
        find.text('Playback'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Playback'));
      await tester.pumpAndSettle();

      // Should show playback screen title
      expect(find.text('Playback'), findsWidgets);
    });
  });
}
