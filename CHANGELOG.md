# Unreleased

* `MermaidDiagram` accepts optional `imageDiagramBuilder` and `svgDiagramBuilder` callbacks to replace `Image.memory` / `SvgPicture.string`.

# 0.1.0

* First pub.dev-ready release of the native Mermaid renderer.
* Targets Flutter 3.38+ / Dart 3.10+ (verified on Flutter 3.47).
* Adds Android and iOS FFI plugin scaffolding so mobile apps can build the Rust crate.
* Documents installation from pub.dev, supported diagram types, and platform requirements.
* Example gallery samples live in `example/lib/mermaid_diagram_examples.dart`.
* `MermaidDiagram.format` selects an independent PNG or SVG render path (default SVG).

# 0.0.2

* Expose SVG and PNG rendering helpers from `FlutterMermaidHelper`.

# 0.0.1

* Initial development release with `MermaidDiagram` and native rendering via merman.
