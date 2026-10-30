import 'package:flutter/material.dart';
import 'package:flutter_mermaid_example/mermaid_diagram_examples.dart';
import 'package:flutter_mermaid_native/flutter_mermaid_native.dart';

Future<void> main() async {
  await FlutterMermaidHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mermaid Diagrams',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      showPerformanceOverlay: true,
      home: const DiagramViewer(),
    );
  }
}

class DiagramViewer extends StatefulWidget {
  const DiagramViewer({super.key});

  @override
  State<DiagramViewer> createState() => _DiagramViewerState();
}

class _DiagramViewerState extends State<DiagramViewer> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mermaid Diagrams'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preview'),
              Tab(text: 'All diagrams'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PreviewTab(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            const _AllDiagramsTab(),
          ],
        ),
      ),
    );
  }
}

class _PreviewTab extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PreviewTab({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<int>(
            initialValue: selectedIndex,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: diagramExamples.asMap().entries.map((entry) {
              return DropdownMenuItem(value: entry.key, child: Text(entry.value.name));
            }).toList(),
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
          ),
        ),
        Expanded(child: MermaidDiagram(diagram: diagramExamples[selectedIndex].code)),
      ],
    );
  }
}

class _AllDiagramsTab extends StatelessWidget {
  const _AllDiagramsTab();

  void _openDiagramDialog(BuildContext context, DiagramExample example) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width * 0.9, maxHeight: size.height * 0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(example.name, style: Theme.of(dialogContext).textTheme.titleLarge)),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: MermaidDiagram(diagram: example.code, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 1100
        ? 3
        : width >= 700
        ? 2
        : 1;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: diagramExamples.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final example = diagramExamples[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDiagramDialog(context, example),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(example.name, style: titleStyle),
                ),
                Expanded(
                  child: SizedBox.expand(
                    child: MermaidDiagram(
                      diagram: example.code,
                      padding: const EdgeInsets.all(8),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
