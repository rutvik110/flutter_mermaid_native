import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_mermaid_native/src/core/mermaid_cache.dart';
import 'package:flutter_mermaid_native/src/rust/frb_generated.dart';

/// Static entry point for initializing the native renderer and rendering
/// Mermaid source to SVG or PNG without a widget.
abstract final class FlutterMermaidHelper {
  static bool _mermaidInitialized = false;

  /// Initialize the native Mermaid renderer.
  ///
  /// Call this once before using [MermaidDiagram] or the render methods.
  /// Subsequent calls are no-ops.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   await FlutterMermaidHelper.initialize();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    if (_mermaidInitialized) return;
    WidgetsFlutterBinding.ensureInitialized();
    await RustLib.init();
    _mermaidInitialized = true;
  }

  /// Removes every diagram currently stored in [MermaidCache].
  static void clearMermaidCache() {
    MermaidCache.instance.clear();
  }

  /// Renders [diagram] to an SVG document string.
  ///
  /// [initialize] must have completed successfully before calling this.
  static Future<String> renderMermaidToSvg({required String diagram}) =>
      // ignore: invalid_use_of_internal_member
      RustLib.instance.api.crateApiSimpleRenderMermaidToSvg(diagram: diagram);

  /// Renders [diagram] to PNG bytes at 2x scale.
  ///
  /// [initialize] must have completed successfully before calling this.
  static Future<Uint8List> renderMermaidToPng({required String diagram}) =>
      // ignore: invalid_use_of_internal_member
      RustLib.instance.api.crateApiSimpleRenderMermaidToPng(diagram: diagram);
}
