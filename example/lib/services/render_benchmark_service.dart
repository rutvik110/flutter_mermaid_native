import 'package:flutter_mermaid_example/models/render_benchmark_result.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';

/// Headless timing helpers for native Mermaid SVG and PNG rendering.
abstract final class RenderBenchmarkService {
  static Future<RenderBenchmarkResult> measureSvg({
    required String name,
    required String diagram,
    int warmup = 1,
    int iterations = 5,
  }) {
    return _measure(
      name: name,
      format: 'svg',
      warmup: warmup,
      iterations: iterations,
      render: () async {
        final svg = await FlutterMermaidHelper.renderMermaidToSvg(diagram: diagram);
        return svg.length;
      },
    );
  }

  static Future<RenderBenchmarkResult> measurePng({
    required String name,
    required String diagram,
    int warmup = 1,
    int iterations = 5,
  }) {
    return _measure(
      name: name,
      format: 'png',
      warmup: warmup,
      iterations: iterations,
      render: () async {
        final png = await FlutterMermaidHelper.renderMermaidToPng(diagram: diagram);
        return png.length;
      },
    );
  }

  static Future<RenderBenchmarkResult> _measure({
    required String name,
    required String format,
    required int warmup,
    required int iterations,
    required Future<int> Function() render,
  }) async {
    for (var i = 0; i < warmup; i++) {
      await render();
    }

    final samples = <Duration>[];
    var outputBytes = 0;
    for (var i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      outputBytes = await render();
      stopwatch.stop();
      samples.add(stopwatch.elapsed);
    }

    return summarize(
      name: name,
      format: format,
      samples: samples,
      outputBytes: outputBytes,
    );
  }

  static RenderBenchmarkResult summarize({
    required String name,
    required String format,
    required List<Duration> samples,
    required int outputBytes,
  }) {
    final sorted = [...samples]..sort();
    final totalUs = sorted.fold<int>(0, (sum, item) => sum + item.inMicroseconds);
    return RenderBenchmarkResult(
      name: name,
      format: format,
      iterations: sorted.length,
      min: sorted.first,
      median: sorted[sorted.length ~/ 2],
      p95: sorted[((sorted.length - 1) * 0.95).round()],
      max: sorted.last,
      mean: Duration(microseconds: totalUs ~/ sorted.length),
      outputBytes: outputBytes,
    );
  }
}
