import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_mermaid/src/rust/api/simple.dart';
import 'package:flutter_mermaid/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
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
  Uint8List? _currentImage;
  bool _isLoading = false;
  String? _error;
  Duration? _renderTime;

  @override
  void initState() {
    super.initState();
    _loadDiagram();
  }

  Future<void> _loadDiagram() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stopwatch = Stopwatch()..start();
      final pixels = await renderMermaidToPng(diagram: diagramExamples[_selectedIndex].code);
      stopwatch.stop();

      setState(() {
        _currentImage = pixels;
        _renderTime = stopwatch.elapsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                  _loadDiagram();
                }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_renderTime != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Render time: ${_renderTime!.inMilliseconds}ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_currentImage != null) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.memory(_currentImage!, fit: BoxFit.contain),
          ),
        ),
      );
    }

    return const Center(child: Text('No diagram loaded'));
  }
}

class DiagramExample {
  final String name;
  final String code;

  const DiagramExample(this.name, this.code);
}

final diagramExamples = [
  const DiagramExample('Flowchart - Simple', '''
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
    C --> E[End]
'''),

  const DiagramExample('Flowchart - Complex', '''
flowchart TB
    subgraph Frontend
        A[React App] --> B[Redux Store]
        B --> C[Components]
    end
    subgraph Backend
        D[API Gateway] --> E[Auth Service]
        D --> F[User Service]
        D --> G[Data Service]
    end
    subgraph Database
        H[(PostgreSQL)]
        I[(Redis Cache)]
    end
    C --> D
    F --> H
    G --> H
    E --> I
'''),

  const DiagramExample('Sequence Diagram', '''
sequenceDiagram
    participant U as User
    participant C as Client
    participant S as Server
    participant D as Database
    
    U->>C: Click Login
    C->>S: POST /auth/login
    S->>D: Query user
    D-->>S: User data
    S-->>C: JWT Token
    C-->>U: Welcome!
'''),

  const DiagramExample('Class Diagram', '''
classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal <|-- Zebra
    Animal : +int age
    Animal : +String gender
    Animal: +isMammal()
    Animal: +mate()
    class Duck{
        +String beakColor
        +swim()
        +quack()
    }
    class Fish{
        -int sizeInFeet
        -canEat()
    }
    class Zebra{
        +bool is_wild
        +run()
    }
'''),

  const DiagramExample('State Diagram', '''
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Success : Complete
    Processing --> Error : Fail
    Success --> Idle : Reset
    Error --> Idle : Retry
    Error --> [*] : Abort
'''),

  const DiagramExample('ER Diagram', '''
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    CUSTOMER {
        string name
        string email
        string address
    }
    ORDER {
        int orderNumber
        date orderDate
        string status
    }
    LINE-ITEM {
        int quantity
        float price
        string productName
    }
'''),

  const DiagramExample('Pie Chart', '''
pie showData
    title Project Time Distribution
    "Development" : 45
    "Testing" : 25
    "Documentation" : 15
    "Meetings" : 10
    "Other" : 5
'''),

  const DiagramExample('Gantt Chart', '''
gantt
    title Project Schedule
    dateFormat YYYY-MM-DD
    section Planning
        Requirements    :a1, 2024-01-01, 7d
        Design          :a2, after a1, 14d
    section Development
        Frontend        :b1, after a2, 21d
        Backend         :b2, after a2, 28d
        Integration     :b3, after b1, 7d
    section Testing
        QA Testing      :c1, after b3, 14d
        UAT             :c2, after c1, 7d
'''),

  const DiagramExample('Mindmap', '''
mindmap
    root((Project))
        Frontend
            React
            TypeScript
            Tailwind
        Backend
            Rust
            PostgreSQL
            Redis
        DevOps
            Docker
            Kubernetes
            CI/CD
        Testing
            Unit Tests
            Integration
            E2E
'''),

  const DiagramExample('Git Graph', '''
gitGraph
    commit id: "Initial"
    branch develop
    checkout develop
    commit id: "Feature A"
    commit id: "Feature B"
    checkout main
    merge develop id: "Release 1.0"
    branch hotfix
    commit id: "Fix bug"
    checkout main
    merge hotfix id: "Patch 1.0.1"
'''),

  const DiagramExample('Timeline', '''
timeline
    title History of Web Development
    section 1990s
        1991 : First website
        1995 : JavaScript
        1996 : CSS
    section 2000s
        2004 : Web 2.0
        2006 : jQuery
        2008 : Chrome
    section 2010s
        2010 : Node.js
        2013 : React
        2016 : Vue.js
'''),

  const DiagramExample('Journey', '''
journey
    title User Shopping Experience
    section Browse
        Visit website: 5: User
        Search products: 4: User
        View product: 5: User
    section Purchase
        Add to cart: 4: User
        Checkout: 3: User
        Payment: 4: User, System
    section Delivery
        Confirmation: 5: System
        Shipping: 4: System
        Delivery: 5: User
'''),

  const DiagramExample('ZenUML', '''
zenuml
    title Order Service
    @Actor Client #FFEBE6
    @Boundary OrderController #0747A6
    @EC2 <<BFF>> OrderService #E3FCEF
    group BusinessService {
      @Lambda PurchaseService
      @AzureFunction InvoiceService
    }

    @Starter(Client)
    OrderController.post(payload) {
      OrderService.create(payload) {
        order = new Order(payload)
        if(order != null) {
          par {
            PurchaseService.createPO(order)
            InvoiceService.createInvoice(order)      
          }      
        }
      }
    }
'''),
];
