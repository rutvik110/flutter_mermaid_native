# flutter_mermaid_native example

Run this app to try the native Mermaid renderer:

```bash
cd example
flutter run -d macos
```

The gallery covers flowcharts, sequence, class, state, ER, pie, Gantt, mindmap, git, timeline, and journey diagrams.

`FlutterMermaidHelper.initialize()` must run before `runApp`.

Rendering benchmarks (SVG, PNG, and widget first paint):

```bash
cd example
flutter test integration_test/render_benchmark_test.dart -d macos
```
