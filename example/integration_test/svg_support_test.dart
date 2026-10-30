import 'package:flutter/material.dart';
import 'package:flutter_mermaid_example/mermaid_diagram_examples.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Checks which example diagrams render correctly through `MermaidDiagram`
/// for each [MermaidRenderFormat].
///
/// The PNG path must render every example. The SVG path is expected to fail on
/// some diagrams because `flutter_svg` does not support every tag that merman
/// emits. The failing SVG diagrams are printed as `SVG_SUPPORT` lines.
///
/// Run with:
///   cd example
///   flutter test integration_test/svg_support_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlutterMermaidHelper.initialize();
  });

  testWidgets('every example renders as PNG', (tester) async {
    final failures = await _renderAll(tester, MermaidRenderFormat.png);
    expect(failures, isEmpty, reason: 'PNG failed for: ${failures.keys.join(', ')}');
  });

  testWidgets('SVG support per example', (tester) async {
    final failures = await _renderAll(tester, MermaidRenderFormat.svg);
    // ignore: avoid_print
    print('SVG_SUPPORT summary: ${diagramExamples.length - failures.length} ok, ${failures.length} failed');
    // SVG failures are the finding being documented, so this test does not fail on them.
    expect(diagramExamples, isNotEmpty);
  });
}

/// Renders each example in [format] and returns `name -> error` for failures.
Future<Map<String, String>> _renderAll(WidgetTester tester, MermaidRenderFormat format) async {
  final previousOnError = FlutterError.onError;
  final flutterErrors = <String>[];
  FlutterError.onError = (details) {
    flutterErrors.add(details.exceptionAsString().split('\n').first);
  };
  addTearDown(() {
    FlutterError.onError = previousOnError;
  });

  final failures = <String, String>{};
  final label = format == MermaidRenderFormat.png ? 'PNG' : 'SVG';

  for (final example in diagramExamples) {
    flutterErrors.clear();
    final builderErrors = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MermaidDiagram(
            key: ValueKey('${example.name}-${format.name}'),
            diagram: example.code,
            format: format,
            loadingBuilder: (_) => const SizedBox.shrink(),
            diagramSourceProcessingErrorBuilder: (_, error, _) {
              builderErrors.add('source: $error');
              return const SizedBox.shrink();
            },
            diagramWidgetRenderingErrorBuilder: (_, error, _) {
              builderErrors.add('widget: $error');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // Give the native render and the image/SVG loader real time to finish.
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 3)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (builderErrors.isNotEmpty || flutterErrors.isNotEmpty) {
        break;
      }
    }
    while (tester.takeException() != null) {}

    final pictureFound = format == MermaidRenderFormat.png
        ? find.byType(Image).evaluate().isNotEmpty
        : find.byType(SvgPicture).evaluate().isNotEmpty;
    final errors = [...builderErrors, ...flutterErrors];

    if (errors.isNotEmpty || !pictureFound) {
      final message = errors.isNotEmpty ? errors.first : 'no $label picture in tree';
      failures[example.name] = message;
      // ignore: avoid_print
      print('SVG_SUPPORT ${example.name} ($label): FAIL - $message');
    } else {
      // ignore: avoid_print
      print('SVG_SUPPORT ${example.name} ($label): ok');
    }
  }

  return failures;
}
