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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mermaid Diagrams'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<int>(
              initialValue: _selectedIndex,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: diagramExamples.asMap().entries.map((entry) {
                return DropdownMenuItem(value: entry.key, child: Text(entry.value.name));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedIndex = value);
                }
              },
            ),
          ),
        ),
      ),
      body: MermaidDiagram(diagram: diagramExamples[_selectedIndex].code),
    );
  }
}
