# flutter_mermaid_native example

Run this app to try the native Mermaid renderer:

```bash
cd example
flutter run -d macos
```

The gallery covers flowcharts, sequence, class, state, ER, pie, Gantt, mindmap, git, timeline, and journey diagrams.

`FlutterMermaidHelper.initialize()` must run before `runApp`.

Rendering benchmarks (profile / AOT; macOS integration tests cannot use `--release`):

```bash
cd example
flutter drive --no-start-paused --profile -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/render_benchmark_test.dart
```
