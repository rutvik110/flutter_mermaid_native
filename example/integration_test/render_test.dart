import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';
import 'package:flutter_mermaid_native/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Integration tests for the Mermaid Rust rendering engine.
///
/// These tests run against the real `merman` Rust library via FFI and verify
/// which diagram types and syntax features are supported.
///
/// Run with:
///   cd frontend/flutter_mermaid/example
///   flutter test integration_test/render_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlutterMermaidHelper.initialize();
  });

  setUp(() => MermaidCache.instance.clear());

  // ---------------------------------------------------------------------------
  // PNG output validation
  // ---------------------------------------------------------------------------

  group('PNG output', () {
    testWidgets('produces valid PNG bytes', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'flowchart TD\n    A[Start] --> B[End]',
      );
      expect(png.length, greaterThan(0));
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });
  });

  // ---------------------------------------------------------------------------
  // SVG output validation
  // ---------------------------------------------------------------------------

  group('SVG output', () {
    testWidgets('produces valid SVG string', (tester) async {
      final svg = await renderMermaidToSvg(
        diagram: 'flowchart TD\n    A[Start] --> B[End]',
      );
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    });
  });

  // ---------------------------------------------------------------------------
  // Diagram type compatibility matrix
  // ---------------------------------------------------------------------------

  group('diagram types', () {
    final diagrams = {
      'flowchart': 'flowchart TD\n    A[Start] --> B[End]',
      'flowchart with decision': 'flowchart TD\n    A{Decision} -->|Yes| B[OK]\n    A -->|No| C[Fail]',
      'flowchart LR': 'flowchart LR\n    A --> B --> C',
      'sequence': 'sequenceDiagram\n    Alice->>Bob: Hello\n    Bob-->>Alice: Hi',
      'class': 'classDiagram\n    Animal <|-- Duck\n    Animal : +int age\n    Animal : +String gender',
      'state': 'stateDiagram-v2\n    [*] --> Active\n    Active --> Inactive\n    Inactive --> [*]',
      'er': 'erDiagram\n    CUSTOMER ||--o{ ORDER : places\n    ORDER ||--|{ LINE-ITEM : contains',
      'gantt': 'gantt\n    title Schedule\n    dateFormat YYYY-MM-DD\n    section A\n    Task 1: a1, 2024-01-01, 30d',
      'pie': 'pie title Pets\n    "Dogs" : 386\n    "Cats" : 85',
      'git': 'gitGraph\n    commit\n    branch develop\n    commit\n    checkout main\n    commit',
    };

    for (final entry in diagrams.entries) {
      testWidgets('renders ${entry.key}', (tester) async {
        final png = await renderMermaidToPng(diagram: entry.value);
        expect(png.length, greaterThan(100), reason: '${entry.key} should produce non-trivial PNG data');
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Flowchart node shapes
  // ---------------------------------------------------------------------------

  group('flowchart node shapes', () {
    final shapes = {
      'rectangle []': 'flowchart TD\n    A[Rectangle]',
      'rounded ()': 'flowchart TD\n    A(Rounded)',
      'stadium ([])': 'flowchart TD\n    A([Stadium])',
      'subroutine [[]]': 'flowchart TD\n    A[[Subroutine]]',
      'cylinder [()]': 'flowchart TD\n    A[(Cylinder)]',
      'circle (())': 'flowchart TD\n    A((Circle))',
      'diamond {}': 'flowchart TD\n    A{Diamond}',
      'hexagon {{}}': 'flowchart TD\n    A{{Hexagon}}',
      'parallelogram [/ /]': 'flowchart TD\n    A[/Parallelogram/]',
      'trapezoid [/ \\]': 'flowchart TD\n    A[/Trapezoid\\]',
    };

    for (final entry in shapes.entries) {
      testWidgets('renders ${entry.key}', (tester) async {
        final png = await renderMermaidToPng(diagram: entry.value);
        expect(png.length, greaterThan(0), reason: '${entry.key} should render');
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Edge types
  // ---------------------------------------------------------------------------

  group('flowchart edge types', () {
    final edges = {
      'arrow -->': 'flowchart TD\n    A --> B',
      'open ---': 'flowchart TD\n    A --- B',
      'dotted -.->': 'flowchart TD\n    A -.-> B',
      'thick ==>': 'flowchart TD\n    A ==> B',
      'labeled -->|text|': 'flowchart TD\n    A -->|label| B',
    };

    for (final entry in edges.entries) {
      testWidgets('renders ${entry.key}', (tester) async {
        final png = await renderMermaidToPng(diagram: entry.value);
        expect(png.length, greaterThan(0));
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Complex multi-feature flowcharts
  // ---------------------------------------------------------------------------

  group('complex flowcharts', () {
    testWidgets('renders streaming parse decision tree', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'flowchart TD\n'
            '    A[Stream Token Arrives] --> B{Open Fence Found?}\n'
            '    B -- No --> C[Parse as Markdown]\n'
            '    B -- Yes --> D[Collect lines for Mermaid Body]\n'
            '    D --> E{Line starts with backticks?}\n'
            '    E -- Yes --> F{Is line JUST backticks?}\n'
            '    F -- No --> G[Add to body: treat as nested/invalid info string]\n'
            '    G --> D\n'
            '    F -- Yes --> H[Close Mermaid Block]\n'
            '    H --> I[Send to Rust FFI for PNG Render]\n'
            '    E -- No --> D',
      );
      expect(png.length, greaterThan(100));
    });

    testWidgets('renders flowchart with mixed node shapes and edge types', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'flowchart TD\n'
            '    A[Start] --> B{Decision}\n'
            '    B -->|Yes| C((Circle))\n'
            '    B -->|No| D[(Database)]\n'
            '    C -.-> E[/Output/]\n'
            '    D ==> E\n'
            '    E --> F([End])',
      );
      expect(png.length, greaterThan(100));
    });

    testWidgets('renders flowchart with subgraphs', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'flowchart TD\n'
            '    subgraph Frontend\n'
            '        A[UI] --> B[State]\n'
            '    end\n'
            '    subgraph Backend\n'
            '        C[API] --> D[DB]\n'
            '    end\n'
            '    B --> C',
      );
      expect(png.length, greaterThan(100));
    });
  });

  // ---------------------------------------------------------------------------
  // State diagrams (rendering pipeline visualization)
  // ---------------------------------------------------------------------------

  group('state diagrams', () {
    testWidgets('renders mermaid rendering pipeline state machine (indented)', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'stateDiagram-v2\n'
            '    [*] --> RawCode: Streaming (isLastNode: true)\n'
            '    RawCode --> PulsingPlaceholder: Closing Fence Found\n'
            '    PulsingPlaceholder --> FinalDiagram: Rust FFI Render Complete\n'
            '    FinalDiagram --> [*]\n'
            '\n'
            '    note right of PulsingPlaceholder\n'
            '        Replaced SyncedShimmer with\n'
            '        Subtle Opacity Pulse (1.2s cycle)\n'
            '    end note',
      );
      expect(png.length, greaterThan(100));
    });

    testWidgets('renders mermaid rendering pipeline state machine (no indent)', (tester) async {
      final png = await renderMermaidToPng(
        diagram: 'stateDiagram-v2\n'
            '[*] --> RawCode: Streaming (isLastNode: true)\n'
            'RawCode --> PulsingPlaceholder: Closing Fence Found\n'
            'PulsingPlaceholder --> FinalDiagram: Rust FFI Render Complete\n'
            'FinalDiagram --> [*]\n'
            '\n'
            'note right of PulsingPlaceholder\n'
            '  Replaced SyncedShimmer with\n'
            '  Subtle Opacity Pulse (1.2s cycle)\n'
            'end note',
      );
      expect(png.length, greaterThan(100));
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------

  group('error handling', () {
    testWidgets('throws on completely invalid input', (tester) async {
      expect(
        () => renderMermaidToPng(diagram: 'this is not a diagram at all'),
        throwsA(anything),
      );
    });

    testWidgets('throws on empty input', (tester) async {
      expect(
        () => renderMermaidToPng(diagram: ''),
        throwsA(anything),
      );
    });

    testWidgets('throws on unterminated node label', (tester) async {
      expect(
        () => renderMermaidToPng(diagram: 'flowchart TD\n    A{Unclosed'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Cache integration
  // ---------------------------------------------------------------------------

  group('cache integration', () {
    const diagram = 'flowchart TD\n    A --> B';

    testWidgets('same diagram renders identical bytes', (tester) async {
      final first = await renderMermaidToPng(diagram: diagram);
      final second = await renderMermaidToPng(diagram: diagram);
      expect(first, equals(second));
    });
  });
}
