class DiagramExample {
  final String name;
  final String code;

  const DiagramExample(this.name, this.code);
}

const diagramExamples = [
  DiagramExample('Flowchart', '''
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
    C --> E[End]
'''),
  DiagramExample('Flowchart with subgraphs', '''
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
  DiagramExample('Sequence', '''
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
  DiagramExample('Class', '''
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
  DiagramExample('State', '''
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : Start
    Processing --> Success : Complete
    Processing --> Error : Fail
    Success --> Idle : Reset
    Error --> Idle : Retry
    Error --> [*] : Abort
'''),
  DiagramExample('Entity relationship', '''
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
  DiagramExample('Pie chart', '''
pie showData
    title Project Time Distribution
    "Development" : 45
    "Testing" : 25
    "Documentation" : 15
    "Meetings" : 10
    "Other" : 5
'''),
  DiagramExample('Gantt', '''
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
  DiagramExample('Mindmap', '''
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
  DiagramExample('Git graph', '''
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
  DiagramExample('Timeline', '''
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
  DiagramExample('User journey', '''
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
];
