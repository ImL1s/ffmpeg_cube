import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube_example/main.dart';

void main() {
  testWidgets('App should load and show home screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FFmpegCubeExampleApp());

    // Verify the app title is displayed
    expect(find.text('FFmpeg Cube Demo'), findsOneWidget);

    // Verify feature cards are displayed
    expect(find.text('轉檔'), findsOneWidget);
    expect(find.text('縮圖'), findsOneWidget);
    expect(find.text('播放'), findsOneWidget);
    expect(find.text('探測'), findsOneWidget);
  });
}
