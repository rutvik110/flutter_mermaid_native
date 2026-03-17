import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/mermaid_cache.dart';
import '../rust/api/simple.dart';

/// A widget that renders Mermaid diagram code as a PNG image.
///
/// Call [RustLib.init] in your app's main before using this widget.
///
/// This widget automatically caches rendered diagrams using [MermaidCache],
/// so diagrams are only rendered once and subsequent displays load instantly
/// from cache without animation.
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

  /// How the image should be inscribed into the available space.
  final BoxFit fit;

  /// Padding around the diagram.
  final EdgeInsets padding;

  const MermaidDiagram({
    super.key,
    required this.diagram,
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

    final cached = getDiagramFromCache();

    if (cached != null) {
      return;
    } else {
      _render();
    }
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagram != widget.diagram) {
      final cached = getDiagramFromCache();
      if (cached != null) {
        return;
      } else {
        _render();
      }
    }
  }

  Uint8List? getDiagramFromCache() {
    final cache = MermaidCache.instance;
    final cached = cache.get(widget.diagram);
    if (cached != null) {
      _image = cached;
      _isLoading = false;
      _error = null;
    }
    return null;
  }

  Future<void> _render() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pixels = await renderMermaidToPng(diagram: widget.diagram);
      if (mounted) {
        // Store in cache
        MermaidCache.instance.put(widget.diagram, pixels);
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

    if (_error != null && _image != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                'Failed to render diagram',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.diagram.trim(),
              style: TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w300, height: 1.6),
            ),
          ),
        ],
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Center(
        child: Padding(
          padding: widget.padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 400),
            child: Image.memory(_image!, fit: widget.fit),
          ),
        ),
      ),
    );
  }
}
