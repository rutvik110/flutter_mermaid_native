import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mermaid_example/mermaid_diagram_examples.dart';
import 'package:flutter_mermaid_example/models/render_benchmark_result.dart';
import 'package:flutter_mermaid_example/services/render_benchmark_service.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Native rendering benchmarks.
///
/// Widget timings mount **one** [MermaidDiagram] at a time. They do not build
/// the example gallery list.
///
/// Run with:
///   cd example
///   flutter drive --no-start-paused --profile -d macos \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/render_benchmark_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlutterMermaidHelper.initialize();
  });

  testWidgets('measures isolated SVG, PNG, and widget times', (tester) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (_isFlutterSvgParseError(details)) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });

    final results = <RenderBenchmarkResult>[];

    for (final example in diagramExamples) {
      FlutterMermaidHelper.clearMermaidCache();
      final svg = await RenderBenchmarkService.measureSvg(name: example.name, diagram: example.code);
      FlutterMermaidHelper.clearMermaidCache();
      final png = await RenderBenchmarkService.measurePng(name: example.name, diagram: example.code);
      results.add(svg);
      results.add(png);
      // ignore: avoid_print
      print(
        'BENCHMARK_PROGRESS ${example.name}: '
        'svg median ${svg.median.inMilliseconds}ms, '
        'png median ${png.median.inMilliseconds}ms',
      );
    }

    for (final format in [MermaidRenderFormat.png, MermaidRenderFormat.svg]) {
      final formatLabel = format == MermaidRenderFormat.png ? 'png' : 'svg';
      for (final example in diagramExamples) {
        // ignore: avoid_print
        print('BENCHMARK_PROGRESS starting $formatLabel widget ${example.name}');
        await _WidgetPaintTimer.pumpEmpty(tester);
        FlutterMermaidHelper.clearMermaidCache();

        final firstSamples = <Duration>[];
        final secondSamples = <Duration>[];

        for (var i = 0; i < 5; i++) {
          FlutterMermaidHelper.clearMermaidCache();
          await _WidgetPaintTimer.pumpEmpty(tester);
          firstSamples.add(
            await _WidgetPaintTimer.mountUntilPicture(
              tester: tester,
              name: example.name,
              diagram: example.code,
              format: format,
              paintIndex: i * 2,
            ),
          );
          expect(find.byType(MermaidDiagram), findsOneWidget);

          secondSamples.add(
            await _WidgetPaintTimer.mountUntilPicture(
              tester: tester,
              name: example.name,
              diagram: example.code,
              format: format,
              paintIndex: i * 2 + 1,
            ),
          );
          expect(find.byType(MermaidDiagram), findsOneWidget);
        }

        await _WidgetPaintTimer.pumpEmpty(tester);
        FlutterMermaidHelper.clearMermaidCache();
        expect(find.byType(MermaidDiagram), findsNothing);

        final first = RenderBenchmarkService.summarize(
          name: example.name,
          format: '$formatLabel-widget-first',
          samples: firstSamples,
          outputBytes: 0,
        );
        final second = RenderBenchmarkService.summarize(
          name: example.name,
          format: '$formatLabel-widget-second',
          samples: secondSamples,
          outputBytes: 0,
        );
        results.add(first);
        results.add(second);
        // ignore: avoid_print
        print(
          'BENCHMARK_PROGRESS ${example.name} $formatLabel widget: '
          'first ${first.mean.inMilliseconds}ms, '
          'second ${second.mean.inMilliseconds}ms',
        );
      }
    }

    // ignore: avoid_print
    print('BENCHMARK_JSON ${jsonEncode(results.map((item) => item.toJson()).toList())}');

    for (final result in results) {
      if (result.format.endsWith('widget-second')) {
        expect(result.mean.inMicroseconds, greaterThanOrEqualTo(0));
        continue;
      }
      expect(result.mean.inMicroseconds, greaterThan(0));
    }
  });
}

bool _isFlutterSvgParseError(FlutterErrorDetails details) {
  final stack = details.stack?.toString() ?? '';
  return stack.contains('SvgParser') || stack.contains('vector_graphics_compiler');
}

abstract final class _WidgetPaintTimer {
  static Future<void> pumpEmpty(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  }

  static Future<Duration> mountUntilPicture({
    required WidgetTester tester,
    required String name,
    required String diagram,
    required MermaidRenderFormat format,
    required int paintIndex,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MermaidDiagram(
            key: ValueKey('$name-$format-$paintIndex'),
            diagram: diagram,
            format: format,
            loadingBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final pictureFinder = format == MermaidRenderFormat.png
        ? find.byType(Image)
        : find.byWidgetPredicate(
            (candidate) => candidate is SvgPicture || candidate is Icon,
          );

    final stopwatch = Stopwatch()..start();
    var foundPicture = pictureFinder.evaluate().isNotEmpty;
    while (!foundPicture && stopwatch.elapsed < const Duration(seconds: 30)) {
      await tester.pump(const Duration(milliseconds: 16));
      foundPicture = pictureFinder.evaluate().isNotEmpty;
    }
    stopwatch.stop();
    while (tester.takeException() != null) {}
    expect(foundPicture, isTrue, reason: '$name should paint ${format.name}');
    expect(find.byType(MermaidDiagram), findsOneWidget, reason: '$name must be the only diagram');
    return stopwatch.elapsed;
  }
}
