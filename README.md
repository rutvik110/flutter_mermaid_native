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
| `fit` | `BoxFit` | `BoxFit.contain` | How the PNG fits its parent |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16)` | Padding around the image |
| `loadingBuilder` | `WidgetBuilder?` | progress indicator | Shown while rendering |

Rendered PNGs are cached in memory by diagram source. Call `FlutterMermaidHelper.clearMermaidCache()` when you want to free that memory.

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

Headless SVG/PNG times for the example gallery, plus widget first paint (`MermaidDiagram` until a PNG `Image` appears, cache cleared between diagrams).

**Tested on**

| | |
|---|---|
| Machine | Apple M4 Pro, 24 GB RAM, arm64 |
| OS | macOS 26.4.1 (25E253) |
| Flutter | 3.47.8 stable (Dart 3.13.7) |
| Build | debug, `flutter test integration_test/render_benchmark_test.dart -d macos` |
| Method | 1 warmup + 5 timed runs per diagram/format; PNG is rasterized at 2x |

SVG layout is typically **1–9 ms**. PNG rasterization is **150–728 ms** and dominates widget first paint (median **249 ms**). Timeline, user journey, and Gantt are the slowest PNGs.

### SVG

| Diagram | Median | p95 | Mean | Bytes |
|---|---:|---:|---:|---:|
| Flowchart | 3.0 ms | 4.7 ms | 3.3 ms | 14,937 |
| Flowchart with subgraphs | 7.0 ms | 7.3 ms | 7.1 ms | 23,615 |
| Sequence | 1.9 ms | 2.0 ms | 1.9 ms | 23,091 |
| Class | 4.3 ms | 4.6 ms | 4.4 ms | 21,714 |
| State | 8.8 ms | 9.3 ms | 8.9 ms | 172,466 |
| Entity relationship | 7.3 ms | 7.7 ms | 7.3 ms | 35,898 |
| Pie chart | 1.0 ms | 1.2 ms | 1.1 ms | 4,248 |
| Gantt | 1.6 ms | 1.6 ms | 1.6 ms | 9,507 |
| Mindmap | 5.1 ms | 5.5 ms | 5.1 ms | 40,804 |
| Git graph | 1.5 ms | 2.0 ms | 1.6 ms | 5,391 |
| Timeline | 2.0 ms | 2.6 ms | 2.1 ms | 19,939 |
| User journey | 1.6 ms | 1.6 ms | 1.6 ms | 20,841 |

### PNG (2x)

| Diagram | Median | p95 | Mean | Bytes |
|---|---:|---:|---:|---:|
| Flowchart | 157 ms | 162 ms | 158 ms | 81,783 |
| Flowchart with subgraphs | 305 ms | 316 ms | 308 ms | 219,769 |
| Sequence | 239 ms | 251 ms | 241 ms | 158,081 |
| Class | 210 ms | 273 ms | 222 ms | 160,516 |
| State | 171 ms | 173 ms | 171 ms | 97,458 |
| Entity relationship | 212 ms | 223 ms | 213 ms | 174,040 |
| Pie chart | 369 ms | 380 ms | 369 ms | 185,520 |
| Gantt | 467 ms | 473 ms | 468 ms | 151,603 |
| Mindmap | 230 ms | 245 ms | 233 ms | 118,184 |
| Git graph | 150 ms | 152 ms | 149 ms | 52,395 |
| Timeline | 728 ms | 739 ms | 728 ms | 246,967 |
| User journey | 562 ms | 578 ms | 567 ms | 334,978 |

### Widget first paint

| | Min | Median | p95 | Max |
|---|---:|---:|---:|---:|
| Gallery (12 diagrams) | 145 ms | 249 ms | 573 ms | 748 ms |

Re-run:

```bash
cd example
flutter test integration_test/render_benchmark_test.dart -d macos
```

These are debug-host numbers, not release-device numbers.

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
