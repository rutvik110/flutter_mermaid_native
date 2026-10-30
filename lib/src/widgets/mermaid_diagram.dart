import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/flutter_mermaid_helper.dart';
import '../core/mermaid_cache.dart';
import '../enums/mermaid_render_format.dart';

export '../enums/mermaid_render_format.dart';

/// Builds an error widget when diagram rendering fails.
typedef MermaidErrorWidgetBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

/// Builds a widget from native PNG bytes produced by the Mermaid renderer.
typedef MermaidImageDiagramBuilder = Widget Function(BuildContext context, Uint8List png, BoxFit fit);

/// Builds a widget from native SVG markup produced by the Mermaid renderer.
typedef MermaidSvgDiagramBuilder = Widget Function(BuildContext context, String svg, BoxFit fit);

/// A widget that renders Mermaid diagram code as PNG or SVG.
///
/// Call [FlutterMermaidHelper.initialize] before using this widget.
///
/// [format] decides the rendering format, SVG/PNG. Default is [MermaidRenderFormat.png].
///
/// Override [imageDiagramBuilder] or [svgDiagramBuilder] to draw the generated picture with a
/// custom widget instead of [Image.memory] / [SvgPicture.string].
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

  /// Rendering format: SVG **or** PNG.
  final MermaidRenderFormat format;

  /// How the rendered diagram fits its parent.
  final BoxFit fit;

  /// Diagram padding.
  final EdgeInsets padding;

  /// Loading indicator builder.
  final WidgetBuilder? loadingBuilder;

  /// Shown when native SVG/PNG generation fails.
  final MermaidErrorWidgetBuilder? diagramSourceProcessingErrorBuilder;

  /// Shown when [Image.memory] or [SvgPicture] fails to load the generated diagram.
  ///
  /// Not used when a custom [imageDiagramBuilder] or [svgDiagramBuilder] is provided.
  final MermaidErrorWidgetBuilder? diagramWidgetRenderingErrorBuilder;

  /// Custom image diagram widget. Used to render the generated diagram image bytes.
  final MermaidImageDiagramBuilder? imageDiagramBuilder;

  /// Custom SVG diagram widget. Used to render the generated diagram SVG string.
  final MermaidSvgDiagramBuilder? svgDiagramBuilder;

  /// When false, skips [MermaidCache] caching for processed mermaid diagrams image-bytes/svg.
  ///
  /// Default is true.
  final bool enableCache;

  const MermaidDiagram({
    super.key,
    required this.diagram,
    this.format = MermaidRenderFormat.png,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(16.0),
    this.loadingBuilder,
    this.diagramSourceProcessingErrorBuilder,
    this.diagramWidgetRenderingErrorBuilder,
    this.imageDiagramBuilder,
    this.svgDiagramBuilder,
    this.enableCache = true,
  });

  @override
  State<MermaidDiagram> createState() => _MermaidDiagramState();
}

class _MermaidDiagramState extends State<MermaidDiagram> {
  Uint8List? _png;
  String? _svg;

  // Diagram processing loading flag.
  bool _isLoading = true;

  // Error capturing during diagram processing flow.
  Object? _error;

  // Error stack trace.
  StackTrace? _stackTrace;

  bool get _hasProcessedDiagram => switch (widget.format) {
    MermaidRenderFormat.png => _png != null,
    MermaidRenderFormat.svg => _svg != null,
  };

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
    if (oldWidget.diagram != widget.diagram ||
        oldWidget.format != widget.format ||
        oldWidget.enableCache != widget.enableCache) {
      if (!_applyCache()) {
        _render();
      }
    }
  }

  bool _applyCache() {
    if (!widget.enableCache) return false;
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
    _stackTrace = null;
    return true;
  }

  Future<void> _render() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _stackTrace = null;
      _png = null;
      _svg = null;
    });

    try {
      switch (widget.format) {
        case MermaidRenderFormat.png:
          final pixels = await FlutterMermaidHelper.renderMermaidToPng(
            diagram: widget.diagram,
          );
          if (!mounted) return;
          if (widget.enableCache) {
            MermaidCache.instance.putPng(widget.diagram, pixels);
          }
          setState(() {
            _png = pixels;
            _isLoading = false;
          });
        case MermaidRenderFormat.svg:
          final svg = await FlutterMermaidHelper.renderMermaidToSvg(
            diagram: widget.diagram,
          );
          if (!mounted) return;
          if (widget.enableCache) {
            MermaidCache.instance.putSvg(widget.diagram, svg);
          }
          setState(() {
            _svg = svg;
            _isLoading = false;
          });
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = e;
        _stackTrace = stackTrace;
        _isLoading = false;
      });
    }
  }

  Widget _defaultSourceProcessingError(BuildContext context) {
    return Stack(
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
              message: _error.toString(),
              child: Icon(
                Icons.error_outline,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _widgetRenderingError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return widget.diagramWidgetRenderingErrorBuilder?.call(
          context,
          error,
          stackTrace,
        ) ??
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_isLoading) {
      child = widget.loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator());
    } else if (_error != null || !_hasProcessedDiagram) {
      child =
          widget.diagramSourceProcessingErrorBuilder?.call(
            context,
            _error ?? StateError('Diagram produced no picture'),
            _stackTrace,
          ) ??
          _defaultSourceProcessingError(context);
    } else {
      child = Padding(
        padding: widget.padding,
        child: switch (widget.format) {
          MermaidRenderFormat.png =>
            widget.imageDiagramBuilder?.call(context, _png!, widget.fit) ??
                Image.memory(
                  _png!,
                  fit: widget.fit,
                  errorBuilder: _widgetRenderingError,
                ),
          MermaidRenderFormat.svg =>
            widget.svgDiagramBuilder?.call(context, _svg!, widget.fit) ??
                SvgPicture.string(
                  _svg!,
                  fit: widget.fit,
                  errorBuilder: _widgetRenderingError,
                ),
        },
      );
    }

    return AnimatedSize(
      duration: kThemeAnimationDuration,
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
