/// Timing summary for one diagram/format pair.
final class RenderBenchmarkResult {
  const RenderBenchmarkResult({
    required this.name,
    required this.format,
    required this.iterations,
    required this.min,
    required this.median,
    required this.p95,
    required this.max,
    required this.mean,
    required this.outputBytes,
  });

  final String name;
  final String format;
  final int iterations;
  final Duration min;
  final Duration median;
  final Duration p95;
  final Duration max;
  final Duration mean;
  final int outputBytes;

  Map<String, Object> toJson() => {
        'name': name,
        'format': format,
        'iterations': iterations,
        'minMs': min.inMicroseconds / 1000,
        'medianMs': median.inMicroseconds / 1000,
        'p95Ms': p95.inMicroseconds / 1000,
        'maxMs': max.inMicroseconds / 1000,
        'meanMs': mean.inMicroseconds / 1000,
        'outputBytes': outputBytes,
      };
}
