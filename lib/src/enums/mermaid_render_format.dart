/// Output used by [MermaidDiagram] when turning Mermaid source into pixels.
enum MermaidRenderFormat {
  /// Native PNG raster.
  png,

  /// Native SVG string, drawn with `flutter_svg`. Default for [MermaidDiagram].
  svg,
}
