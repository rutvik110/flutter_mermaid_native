import 'dart:typed_data';

import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => MermaidCache.instance.clear());

  group('MermaidCache', () {
    final diagram = 'flowchart TD\n    A --> B';
    final imageData = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    test('returns null for uncached diagram', () {
      expect(MermaidCache.instance.getPng(diagram), isNull);
    });

    test('contains returns false for uncached diagram', () {
      expect(MermaidCache.instance.contains(diagram), isFalse);
    });

    test('stores and retrieves diagram', () {
      MermaidCache.instance.putPng(diagram, imageData);

      expect(MermaidCache.instance.getPng(diagram), equals(imageData));
      expect(MermaidCache.instance.contains(diagram), isTrue);
    });

    test('does not overwrite existing entry', () {
      final firstData = Uint8List.fromList([1, 2, 3]);
      final secondData = Uint8List.fromList([4, 5, 6]);

      MermaidCache.instance.putPng(diagram, firstData);
      MermaidCache.instance.putPng(diagram, secondData);

      expect(MermaidCache.instance.getPng(diagram), equals(firstData));
    });

    test('normalizes keys by trimming whitespace', () {
      MermaidCache.instance.putPng('  $diagram  ', imageData);

      expect(MermaidCache.instance.getPng(diagram), equals(imageData));
      expect(MermaidCache.instance.getPng('  $diagram  '), equals(imageData));
      expect(MermaidCache.instance.getPng('\n$diagram\n'), equals(imageData));
    });

    test('treats different diagrams as separate entries', () {
      final diagramA = 'flowchart TD\n    A --> B';
      final diagramB = 'flowchart TD\n    C --> D';
      final dataA = Uint8List.fromList([1, 2]);
      final dataB = Uint8List.fromList([3, 4]);

      MermaidCache.instance.putPng(diagramA, dataA);
      MermaidCache.instance.putPng(diagramB, dataB);

      expect(MermaidCache.instance.getPng(diagramA), equals(dataA));
      expect(MermaidCache.instance.getPng(diagramB), equals(dataB));
    });

    test('clear removes all entries', () {
      MermaidCache.instance.putPng(diagram, imageData);
      expect(MermaidCache.instance.contains(diagram), isTrue);

      MermaidCache.instance.clear();
      expect(MermaidCache.instance.contains(diagram), isFalse);
      expect(MermaidCache.instance.getPng(diagram), isNull);
    });

    test('clear on empty cache does not throw', () {
      expect(() => MermaidCache.instance.clear(), returnsNormally);
    });

    test('size tracks entries and remove deletes one key', () {
      expect(MermaidCache.instance.size, 0);
      MermaidCache.instance.putPng(diagram, imageData);
      expect(MermaidCache.instance.size, 1);

      MermaidCache.instance.remove(diagram);
      expect(MermaidCache.instance.size, 0);
      expect(MermaidCache.instance.contains(diagram), isFalse);
    });

    test('stores png and svg for the same diagram independently', () {
      const svg = '<svg></svg>';
      MermaidCache.instance.putPng(diagram, imageData);
      MermaidCache.instance.putSvg(diagram, svg);

      expect(MermaidCache.instance.getPng(diagram), equals(imageData));
      expect(MermaidCache.instance.getSvg(diagram), equals(svg));
      expect(MermaidCache.instance.contains(diagram), isTrue);
      expect(MermaidCache.instance.contains(diagram, format: MermaidRenderFormat.svg), isTrue);
      expect(MermaidCache.instance.size, 2);

      MermaidCache.instance.remove(diagram);
      expect(MermaidCache.instance.getPng(diagram), isNull);
      expect(MermaidCache.instance.getSvg(diagram), equals(svg));

      MermaidCache.instance.remove(diagram, format: MermaidRenderFormat.svg);
      expect(MermaidCache.instance.getSvg(diagram), isNull);
    });
  });
}
