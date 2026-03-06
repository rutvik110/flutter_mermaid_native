import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../rust/api/simple.dart';

/// A widget that renders Mermaid diagram code as a PNG image.
///
/// Call [RustLib.init] in your app's main before using this widget.
///
/// Example:
/// ```dart
/// MermaidDiagram(
///   diagram: '''
/// flowchart TD
///     A[Start] --> B[End]
/// ''',
/// )
/// ```
class MermaidDiagram extends StatefulWidget {
  /// The Mermaid diagram source code.
  final String diagram;

  /// Minimum scale for pinch-to-zoom. Defaults to 0.5.
  final double minScale;

  /// Maximum scale for pinch-to-zoom. Defaults to 4.0.
  final double maxScale;

  /// How the image should be inscribed into the available space.
  final BoxFit fit;

  /// Padding around the diagram.
  final EdgeInsets padding;

  const MermaidDiagram({
    super.key,
    required this.diagram,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  Uint8List? _image;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagram != widget.diagram) {
      _render();
    }
  }

  Future<void> _render() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pixels = await renderMermaidToPng(diagram: widget.diagram);
      if (mounted) {
        setState(() {
          _image = pixels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_image != null) {
      return InteractiveViewer(
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: Center(
          child: Padding(
            padding: widget.padding,
            child: Image.memory(_image!, fit: widget.fit),
          ),
        ),
      );
    }

    return const Center(child: Text('No diagram loaded'));
  }
}
