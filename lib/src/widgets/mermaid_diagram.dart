import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/flutter_mermaid_helper.dart';
import '../core/mermaid_cache.dart';
import '../enums/mermaid_render_format.dart';

export '../enums/mermaid_render_format.dart';

/// A widget that renders Mermaid diagram code as PNG or SVG.
///
/// Call [FlutterMermaidHelper.initialize] before using this widget.
///
/// [format] chooses a **single** render path. It does not run PNG and SVG as
/// one pipeline. Default is [MermaidRenderFormat.svg].
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

  /// Native method used to produce the picture. Independent of the other format.
  final MermaidRenderFormat format;

  /// How the picture should be inscribed into the available space.
  final BoxFit fit;

  /// Padding around the diagram.
  final EdgeInsets padding;

  /// Optional builder for the loading state. Defaults to a centered progress indicator.
  final WidgetBuilder? loadingBuilder;

  const MermaidDiagram({
    super.key,
    required this.diagram,
    this.format = MermaidRenderFormat.svg,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(16.0),
    this.loadingBuilder,
  });

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  Uint8List? _png;
  String? _svg;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_applyCache()) {
      _render();
    }
  }

  @override
  void didUpdateWidget(MermaidDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagram != widget.diagram || oldWidget.format != widget.format) {
      if (!_applyCache()) {
        _render();
      } else {
        setState(() {});
      }
    }
  }

  bool _applyCache() {
    final cache = MermaidCache.instance;
    switch (widget.format) {
      case MermaidRenderFormat.png:
        final cached = cache.getPng(widget.diagram);
        if (cached == null) return false;
        _png = cached;
        _svg = null;
      case MermaidRenderFormat.svg:
        final cached = cache.getSvg(widget.diagram);
        if (cached == null) return false;
        _svg = cached;
        _png = null;
    }
    _isLoading = false;
    _error = null;
    return true;
  }

  Future<void> _render() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _png = null;
      _svg = null;
    });

    try {
      switch (widget.format) {
        case MermaidRenderFormat.png:
          final pixels = await FlutterMermaidHelper.renderMermaidToPng(diagram: widget.diagram);
          if (!mounted) return;
          MermaidCache.instance.putPng(widget.diagram, pixels);
          setState(() {
            _png = pixels;
            _isLoading = false;
          });
        case MermaidRenderFormat.svg:
          final svg = await FlutterMermaidHelper.renderMermaidToSvg(diagram: widget.diagram);
          if (!mounted) return;
          MermaidCache.instance.putSvg(widget.diagram, svg);
          setState(() {
            _svg = svg;
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

  bool get _hasPicture => switch (widget.format) {
        MermaidRenderFormat.png => _png != null,
        MermaidRenderFormat.svg => _svg != null,
      };

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_isLoading) {
      child = widget.loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
    } else if (_error != null || !_hasPicture) {
      child = Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.diagram.trim(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Tooltip(
                message: _error!,
                child: Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    } else {
      child = Padding(
        padding: widget.padding,
        child: switch (widget.format) {
          MermaidRenderFormat.png => Image.memory(_png!, fit: widget.fit),
          MermaidRenderFormat.svg => SvgPicture.string(_svg!, fit: widget.fit),
        },
      );
    }

    return AnimatedSize(duration: kThemeAnimationDuration, curve: Curves.easeInOut, child: child);
  }
}
