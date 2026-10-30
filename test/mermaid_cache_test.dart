import 'dart:typed_data';

import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => MermaidCache.instance.clear());

  group('MermaidCache', () {
    final diagram = 'flowchart TD\n    A --> B';
    final imageData = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    test('returns null for uncached diagram', () {
      expect(MermaidCache.instance.get(diagram), isNull);
    });

    test('contains returns false for uncached diagram', () {
      expect(MermaidCache.instance.contains(diagram), isFalse);
    });

    test('stores and retrieves diagram', () {
      MermaidCache.instance.put(diagram, imageData);

      expect(MermaidCache.instance.get(diagram), equals(imageData));
      expect(MermaidCache.instance.contains(diagram), isTrue);
    });

    test('does not overwrite existing entry', () {
      final firstData = Uint8List.fromList([1, 2, 3]);
      final secondData = Uint8List.fromList([4, 5, 6]);

      MermaidCache.instance.put(diagram, firstData);
      MermaidCache.instance.put(diagram, secondData);

      expect(MermaidCache.instance.get(diagram), equals(firstData));
    });

    test('normalizes keys by trimming whitespace', () {
      MermaidCache.instance.put('  $diagram  ', imageData);

      expect(MermaidCache.instance.get(diagram), equals(imageData));
      expect(MermaidCache.instance.get('  $diagram  '), equals(imageData));
      expect(MermaidCache.instance.get('\n$diagram\n'), equals(imageData));
    });

    test('treats different diagrams as separate entries', () {
      final diagramA = 'flowchart TD\n    A --> B';
      final diagramB = 'flowchart TD\n    C --> D';
      final dataA = Uint8List.fromList([1, 2]);
      final dataB = Uint8List.fromList([3, 4]);

      MermaidCache.instance.put(diagramA, dataA);
      MermaidCache.instance.put(diagramB, dataB);

      expect(MermaidCache.instance.get(diagramA), equals(dataA));
      expect(MermaidCache.instance.get(diagramB), equals(dataB));
    });

    test('clear removes all entries', () {
      MermaidCache.instance.put(diagram, imageData);
      expect(MermaidCache.instance.contains(diagram), isTrue);

      MermaidCache.instance.clear();
      expect(MermaidCache.instance.contains(diagram), isFalse);
      expect(MermaidCache.instance.get(diagram), isNull);
    });

    test('clear on empty cache does not throw', () {
      expect(() => MermaidCache.instance.clear(), returnsNormally);
    });

    test('size tracks entries and remove deletes one key', () {
      expect(MermaidCache.instance.size, 0);
      MermaidCache.instance.put(diagram, imageData);
      expect(MermaidCache.instance.size, 1);

      MermaidCache.instance.remove(diagram);
      expect(MermaidCache.instance.size, 0);
      expect(MermaidCache.instance.contains(diagram), isFalse);
    });
  });
}
