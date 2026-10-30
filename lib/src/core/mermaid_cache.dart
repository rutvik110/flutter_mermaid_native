import 'package:flutter/foundation.dart';
import 'package:flutter_mermaid_native/src/enums/mermaid_render_format.dart';

/// In-memory cache for rendered Mermaid output.
///
/// PNG bytes and SVG strings are stored separately so the same diagram can be
/// cached in both formats without colliding.
///
/// Example:
/// ```dart
/// MermaidCache.instance.clear();
/// MermaidCache.instance.remove(diagramSource);
/// print('Cached diagrams: ${MermaidCache.instance.size}');
/// ```
final class MermaidCache {
  MermaidCache._();

  static final MermaidCache _instance = MermaidCache._();

  /// The singleton instance of [MermaidCache].
  static MermaidCache get instance => _instance;

  final Map<String, Uint8List> _png = {};
  final Map<String, String> _svg = {};

  /// Returns true if PNG (default) or the given [format] is cached.
  bool contains(String diagram, {MermaidRenderFormat format = MermaidRenderFormat.png}) {
    final key = _normalizeKey(diagram);
    return switch (format) {
      MermaidRenderFormat.png => _png.containsKey(key),
      MermaidRenderFormat.svg => _svg.containsKey(key),
    };
  }

  /// Cached PNG bytes, or null.
  Uint8List? getPng(String diagram) => _png[_normalizeKey(diagram)];

  /// Cached SVG string, or null.
  String? getSvg(String diagram) => _svg[_normalizeKey(diagram)];

  /// Stores PNG bytes. Does not overwrite an existing PNG entry.
  void putPng(String diagram, Uint8List imageData) {
    final key = _normalizeKey(diagram);
    if (!_png.containsKey(key)) {
      _png[key] = imageData;
    }
  }

  /// Stores an SVG document. Does not overwrite an existing SVG entry.
  void putSvg(String diagram, String svg) {
    final key = _normalizeKey(diagram);
    if (!_svg.containsKey(key)) {
      _svg[key] = svg;
    }
  }

  /// Number of cached PNG and SVG entries combined.
  int get size => _png.length + _svg.length;

  /// Removes PNG (default) or the given [format] for one diagram.
  void remove(String diagram, {MermaidRenderFormat format = MermaidRenderFormat.png}) {
    final key = _normalizeKey(diagram);
    switch (format) {
      case MermaidRenderFormat.png:
        _png.remove(key);
      case MermaidRenderFormat.svg:
        _svg.remove(key);
    }
  }

  /// Clears PNG and SVG caches.
  void clear() {
    _png.clear();
    _svg.clear();
  }

  String _normalizeKey(String diagram) => diagram.trim();
}
