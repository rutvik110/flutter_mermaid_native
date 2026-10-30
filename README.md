# flutter_mermaid_native

Render [Mermaid](https://mermaid.js.org/) diagrams in Flutter using a native [Rust](https://www.rust-lang.org/) engine ([merman](https://crates.io/crates/merman)) bridged with [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/).

This package does **not** use a WebView or JavaScript. Diagrams are rendered to SVG/PNG on the native side and displayed with Flutter widgets.

> The Dart package is named `flutter_mermaid_native` because [`flutter_mermaid`](https://pub.dev/packages/flutter_mermaid) is already taken on pub.dev.

## Supported diagram types

- Flowcharts
- Sequence diagrams
- Class diagrams
- State diagrams
- Entity relationship diagrams
- Pie charts
- Gantt charts
- Mindmaps
- Git graphs
- Timelines
- User journey diagrams

ZenUML is not fully supported by the current Rust parser.

## Requirements

- Flutter 3.38 or newer (Dart 3.10+)
- A [Rust toolchain](https://rustup.rs/) on machines that **build** the app (the crate is compiled by [Cargokit](https://github.com/irondash/cargokit) during `flutter build` / `flutter run`)
- Android, iOS, macOS, Linux, or Windows. Web is not supported.

## Installation

```yaml
dependencies:
  flutter_mermaid_native: ^0.1.0
```

## Usage

Initialize once, then use the widget:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';

Future<void> main() async {
  await FlutterMermaidHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MermaidDiagram(
          // format: MermaidRenderFormat.png, // optional; default is SVG
          diagram: '''
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
    C --> E[End]
''',
        ),
      ),
    );
  }
}
```

### `MermaidDiagram`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `diagram` | `String` | required | Mermaid source |
| `format` | `MermaidRenderFormat` | `svg` | Independent render path: SVG **or** PNG, not both |
| `fit` | `BoxFit` | `BoxFit.contain` | How the picture fits its parent |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16)` | Padding around the picture |
| `loadingBuilder` | `WidgetBuilder?` | progress indicator | Shown while rendering |

PNG and SVG are cached separately by diagram source. Call `FlutterMermaidHelper.clearMermaidCache()` when you want to free that memory.

### Headless rendering

```dart
final svg = await FlutterMermaidHelper.renderMermaidToSvg(diagram: source);
final png = await FlutterMermaidHelper.renderMermaidToPng(diagram: source);
```

## Example

```bash
cd example
flutter run -d macos
```

## Rendering performance

Different mermaid rendering methods benchmarks.

| Benchmark | What it measures |
|---|---|
| SVG | Headless `renderMermaidToSvg` only |
| PNG | Headless `renderMermaidToPng` only |
| Widget PNG path | One isolated `MermaidDiagram(format: png)` until `Image.memory` is in the tree (first and second paint) |

**Testing Environment**

| | |
|---|---|
| Machine | Apple M4 Pro, 24 GB RAM, arm64 |
| OS | macOS 26.4.1 (25E253) |
| Flutter | 3.47.8 stable (Dart 3.13.7) |
| Build Mode | Profile (AOT), `flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/render_benchmark_test.dart` |

SVG and PNG times are the **average** of 5 timed runs after 1 warmup, one diagram at a time. Widget PNG **first paint** is a cold mount of **that diagram only** (empty cache, empty tree beforehand). **Second paint** remounts the same single diagram with cache already filled.

Benchmarks captured in Flutter Profile mode.

### SVG

Headless `FlutterMermaidHelper.renderMermaidToSvg`. Typical average **0.2–1.1 ms**.

| Diagram | Average | Bytes |
|---|---:|---:|
| Flowchart | 0.5 ms | 14,937 |
| Flowchart with subgraphs | 1.0 ms | 23,615 |
| Sequence | 0.2 ms | 23,091 |
| Class | 0.8 ms | 21,714 |
| State | 1.1 ms | 172,371 |
| Entity relationship | 1.1 ms | 35,898 |
| Pie chart | 0.2 ms | 4,248 |
| Gantt | 0.3 ms | 9,507 |
| Mindmap | 0.7 ms | 40,804 |
| Git graph | 0.3 ms | 5,391 |
| Timeline | 0.3 ms | 19,939 |
| User journey | 0.2 ms | 20,841 |

### PNG

Headless `FlutterMermaidHelper.renderMermaidToPng` at 2x. This path does **not** call the SVG helper above; it is a separate API. Typical average **19–40 ms**. Slowest in this set: timeline, user journey, Gantt.

| Diagram | Average | Bytes |
|---|---:|---:|
| Flowchart | 22 ms | 81,783 |
| Flowchart with subgraphs | 27 ms | 219,769 |
| Sequence | 26 ms | 158,081 |
| Class | 25 ms | 160,516 |
| State | 23 ms | 97,456 |
| Entity relationship | 25 ms | 174,040 |
| Pie chart | 28 ms | 185,520 |
| Gantt | 30 ms | 151,603 |
| Mindmap | 23 ms | 118,184 |
| Git graph | 19 ms | 52,395 |
| Timeline | 40 ms | 246,967 |
| User journey | 33 ms | 334,978 |

### Widget PNG path (independent)

Each row mounts **one** `MermaidDiagram(format: MermaidRenderFormat.png)` and waits until `Image.memory` is in the tree.**First paint** is a cold mount (empty cache, native PNG encode). **Second paint** remounts that same diagram with cache already filled.

| Diagram | First paint | Second paint |
|---|---:|---:|
| Flowchart | 25 ms | <1 ms |
| Flowchart with subgraphs | 50 ms | <1 ms |
| Sequence | 45 ms | <1 ms |
| Class | 35 ms | <1 ms |
| State | 35 ms | <1 ms |
| Entity relationship | 50 ms | <1 ms |
| Pie chart | 50 ms | <1 ms |
| Gantt | 50 ms | <1 ms |
| Mindmap | 45 ms | <1 ms |
| Git graph | 25 ms | <1 ms |
| Timeline | 55 ms | <1 ms |
| User journey | 50 ms | <1 ms |

Re-run:

```bash
cd example
flutter drive --no-start-paused --profile -d macos \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/render_benchmark_test.dart
```

## Development

Rust API lives in `rust/src/api/simple.rs`. After changing it:

```bash
cargo install flutter_rust_bridge_codegen --version 2.11.1
flutter_rust_bridge_codegen generate
```

Keep the `flutter_rust_bridge` Dart dependency and the codegen CLI on the same version.

## Platform support

| Platform | Supported |
|----------|-----------|
| Android  | Yes |
| iOS      | Yes |
| macOS    | Yes |
| Windows  | Yes |
| Linux    | Yes |
| Web      | No |

## License

BSD 3-Clause. See [LICENSE](LICENSE). Cargokit is vendored under its own MIT/Apache-2.0 license in `cargokit/LICENSE`.
