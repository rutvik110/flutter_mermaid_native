import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const diagram = 'flowchart TD\n    A --> B';
  final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
  const svgMarkup = '<svg xmlns="http://www.w3.org/2000/svg"></svg>';

  setUp(() => MermaidCache.instance.clear());

  testWidgets('uses imageDiagramBuilder instead of Image.memory', (tester) async {
    MermaidCache.instance.putPng(diagram, pngBytes);

    await tester.pumpWidget(
      MaterialApp(
        home: MermaidDiagram(
          diagram: diagram,
          imageDiagramBuilder: (context, png, fit) {
            expect(png, equals(pngBytes));
            expect(fit, BoxFit.contain);
            return Text('custom-png-${png.length}');
          },
        ),
      ),
    );

    expect(find.text('custom-png-4'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uses svgDiagramBuilder instead of SvgPicture', (tester) async {
    MermaidCache.instance.putSvg(diagram, svgMarkup);

    await tester.pumpWidget(
      MaterialApp(
        home: MermaidDiagram(
          diagram: diagram,
          format: MermaidRenderFormat.svg,
          fit: BoxFit.cover,
          svgDiagramBuilder: (context, svg, fit) {
            expect(svg, svgMarkup);
            expect(fit, BoxFit.cover);
            return Text('custom-svg-${svg.length}');
          },
        ),
      ),
    );

    expect(find.text('custom-svg-${svgMarkup.length}'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('ignores imageDiagramBuilder when format is svg', (tester) async {
    MermaidCache.instance.putSvg(diagram, svgMarkup);

    await tester.pumpWidget(
      MaterialApp(
        home: MermaidDiagram(
          diagram: diagram,
          format: MermaidRenderFormat.svg,
          imageDiagramBuilder: (_, _, _) => const Text('png-builder'),
        ),
      ),
    );

    expect(find.text('png-builder'), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('skips cache when enableCache is false', (tester) async {
    MermaidCache.instance.putPng(diagram, pngBytes);

    await tester.pumpWidget(
      MaterialApp(
        home: MermaidDiagram(
          diagram: diagram,
          enableCache: false,
          loadingBuilder: (_) => const Text('loading'),
          diagramSourceProcessingErrorBuilder: (_, _, _) => const Text('error'),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == 'loading' || widget.data == 'error'),
      ),
      findsOneWidget,
    );
  });
}
