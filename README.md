# flutter_mermaid_native

Render [Mermaid](https://mermaid.js.org/) diagrams in Flutter using a native [Rust](https://www.rust-lang.org/) engine ([merman](https://crates.io/crates/merman)) bridged with [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/).

Mermaid diagrams PNG/SVG are created using the native rust layer based on the provided diagram source and the output is then rendered on the flutter side.

> **Note on generated SVG rendering with flutter_svg:** `flutter_mermaid_native` uses `flutter_svg` to render generated diagram SVG. But as of right now, `flutter_svg` does not support every SVG tag that the Rust layer emits to properly render mermaid diagrams. For example, the Entity relationship diagram triggers a `RangeError` inside `flutter_svg`'s `SvgParser`. Diagrams rendered with `format: MermaidRenderFormat.svg` may therefore look inaccurate or fail to render. Use `MermaidRenderFormat.png` for those diagrams, or pass `svgDiagramBuilder` to draw the SVG with another library.
>
> There is no single `flutter_svg` issue tracking this mermaid/`RangeError` gap. Incomplete SVG support is treated as known, with separate issues for individual missing features:
>
> - [SVG filter spec not supported](https://github.com/flutter/flutter/issues/158811)
> - [Filter / blur effects unimplemented](https://github.com/flutter/flutter/issues/158592)
> - [Nested `<svg>` elements not supported](https://github.com/flutter/flutter/issues/158603)
> - [Does not support fallback `font-family` lists](https://github.com/flutter/flutter/issues/187087)
> - [No proper message when an SVG is unsupported](https://github.com/flutter/flutter/issues/179240)
> - [SVG is not rendered without any errors](https://github.com/flutter/flutter/issues/165879)
> - [Parse exception](https://github.com/dnfield/flutter_svg/issues/1112) (original `dnfield/flutter_svg` repo)

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

- Flutter 3.38 or newer (Dart 3.10+).
- A [Rust toolchain](https://rustup.rs/) on machines that **build** the app (the crate is compiled by [Cargokit](https://github.com/irondash/cargokit) during `flutter build` / `flutter run`).

## Installation

```yaml
dependencies:
  flutter_mermaid_native: ^0.1.0
```

## Usage

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
          // format(optional): MermaidRenderFormat.svg, // default format is PNG.
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
| `format` | `MermaidRenderFormat` | `png` | Rendering format: SVG **or** PNG|
| `fit` | `BoxFit` | `BoxFit.contain` | How the rendered diagram fits its parent |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16)` | Padding around the picture |
| `loadingBuilder` | `WidgetBuilder?` | progress indicator | Shown while rendering |
| `diagramSourceProcessingErrorBuilder` | `MermaidErrorWidgetBuilder?` | Package error widget | Native SVG/PNG generation error |
| `diagramWidgetRenderingErrorBuilder` | `MermaidErrorWidgetBuilder?` | Package error widget | `Image` / `SvgPicture` widget load error |
| `imageDiagramBuilder` | `MermaidImageDiagramBuilder?` | `Image.memory` | Used to render generated diagram image bytes |
| `svgDiagramBuilder` | `MermaidSvgDiagramBuilder?` | `SvgPicture.string` | Used to render generated diagram svg string |

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
| Widget SVG path | One isolated `MermaidDiagram(format: svg)` until `SvgPicture` is in the tree (first and second paint) |

**Testing Environment**

| | |
|---|---|
| Machine | Apple M4 Pro, 24 GB RAM, arm64 |
| OS | macOS 26.4.1 (25E253) |
| Flutter | 3.47.8 stable (Dart 3.13.7) |
| Build Mode | Profile (AOT), `flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/render_benchmark_test.dart` |

SVG and PNG times are the **average** of 5 timed runs after 1 warmup, one diagram at a time. Widget **first paint** is a cold mount of **that diagram only** (empty cache, empty tree beforehand). **Second paint** remounts the same single diagram with cache already filled.

Benchmarks captured in Flutter Profile mode.

### SVG

Headless `FlutterMermaidHelper.renderMermaidToSvg`. Typical average **0.2–1.1 ms**.

| Diagram | Average | Bytes |
|---|---:|---:|
| Flowchart | 0.6 ms | 14,937 |
| Flowchart with subgraphs | 1.1 ms | 23,615 |
| Sequence | 0.2 ms | 23,091 |
| Class | 0.7 ms | 21,714 |
| State | 1.2 ms | 172,384 |
| Entity relationship | 1.2 ms | 35,898 |
| Pie chart | 0.2 ms | 4,248 |
| Gantt | 0.3 ms | 9,507 |
| Mindmap | 0.7 ms | 40,804 |
| Git graph | 0.3 ms | 5,391 |
| Timeline | 0.3 ms | 19,939 |
| User journey | 0.3 ms | 20,841 |

### PNG

Headless `FlutterMermaidHelper.renderMermaidToPng` at 2x. Typical average **17–39 ms**.

| Diagram | Average | Bytes |
|---|---:|---:|
| Flowchart | 21 ms | 81,783 |
| Flowchart with subgraphs | 26 ms | 219,769 |
| Sequence | 23 ms | 158,081 |
| Class | 23 ms | 160,516 |
| State | 23 ms | 97,457 |
| Entity relationship | 24 ms | 174,040 |
| Pie chart | 27 ms | 185,520 |
| Gantt | 29 ms | 151,603 |
| Mindmap | 22 ms | 118,184 |
| Git graph | 17 ms | 52,395 |
| Timeline | 39 ms | 246,967 |
| User journey | 32 ms | 334,978 |

### Widget PNG path (independent)

Each row mounts **one** `MermaidDiagram(format: MermaidRenderFormat.png)` and waits until `Image.memory` is in the tree. **First paint** is a cold mount (empty cache, native PNG encode). **Second paint** remounts that same diagram with cache already filled.

| Diagram | First paint | Second paint |
|---|---:|---:|
| Flowchart | 25 ms | <1 ms |
| Flowchart with subgraphs | 50 ms | <1 ms |
| Sequence | 50 ms | <1 ms |
| Class | 50 ms | <1 ms |
| State | 35 ms | <1 ms |
| Entity relationship | 25 ms | <1 ms |
| Pie chart | 50 ms | <1 ms |
| Gantt | 50 ms | <1 ms |
| Mindmap | 50 ms | <1 ms |
| Git graph | 25 ms | <1 ms |
| Timeline | 50 ms | <1 ms |
| User journey | 50 ms | <1 ms |

### Widget SVG path (independent)

Each row mounts **one** `MermaidDiagram(format: MermaidRenderFormat.svg)` and waits until `SvgPicture` is in the tree. **First paint** is a cold mount (empty cache, native SVG). **Second paint** remounts that same diagram with cache already filled.

| Diagram | First paint | Second paint |
|---|---:|---:|
| Flowchart | 25 ms | <1 ms |
| Flowchart with subgraphs | 25 ms | <1 ms |
| Sequence | 25 ms | <1 ms |
| Class | 25 ms | <1 ms |
| State | 26 ms | <1 ms |
| Entity relationship | 27 ms | 25 ms |
| Pie chart | 25 ms | <1 ms |
| Gantt | 25 ms | <1 ms |
| Mindmap | 26 ms | 26 ms |
| Git graph | 25 ms | <1 ms |
| Timeline | 25 ms | <1 ms |
| User journey | 25 ms | <1 ms |

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
