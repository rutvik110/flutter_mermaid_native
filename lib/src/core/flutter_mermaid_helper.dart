import 'package:flutter_mermaid/src/rust/frb_generated.dart';

class FlutterMermaidHelper {
  final FlutterMermaidHelper _instance = FlutterMermaidHelper._();

  FlutterMermaidHelper._();

  FlutterMermaidHelper get instance => _instance;

  static bool _mermaidInitialized = false;

  /// Initialize the flutter_mermaid library for native Mermaid diagram rendering.
  ///
  /// This must be called before using [MermaidDiagram] widgets. It is safe to call
  /// multiple times - subsequent calls are no-ops.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await initMermaid();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initMermaid() async {
    if (_mermaidInitialized) return;
    await RustLib.init();
    _mermaidInitialized = true;
  }
}
