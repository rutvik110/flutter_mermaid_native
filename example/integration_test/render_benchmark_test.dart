import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mermaid_example/mermaid_diagram_examples.dart';
import 'package:flutter_mermaid_example/models/render_benchmark_result.dart';
import 'package:flutter_mermaid_example/services/render_benchmark_service.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Native rendering benchmarks for the example gallery.
///
/// Run with:
///   cd example
///   flutter test integration_test/render_benchmark_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlutterMermaidHelper.initialize();
  });

  testWidgets('measures SVG and PNG render times for gallery diagrams', (tester) async {
    final results = <RenderBenchmarkResult>[];

    for (final example in diagramExamples) {
      final svg = await RenderBenchmarkService.measureSvg(name: example.name, diagram: example.code);
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

    final widgetSamples = <Duration>[];
    for (final example in diagramExamples) {
      FlutterMermaidHelper.clearMermaidCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MermaidDiagram(
              diagram: example.code,
              loadingBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      var foundImage = false;
      while (stopwatch.elapsed < const Duration(seconds: 30)) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byType(Image).evaluate().isNotEmpty) {
          foundImage = true;
          break;
        }
      }
      stopwatch.stop();
      expect(foundImage, isTrue, reason: '${example.name} should paint a PNG');
      widgetSamples.add(stopwatch.elapsed);
    }

    results.add(
      RenderBenchmarkService.summarize(
        name: 'widget first paint',
        format: 'png-widget',
        samples: widgetSamples,
        outputBytes: 0,
      ),
    );

    // ignore: avoid_print
    print('BENCHMARK_JSON ${jsonEncode(results.map((item) => item.toJson()).toList())}');

    for (final result in results) {
      expect(result.median.inMicroseconds, greaterThan(0));
    }
  });
}
