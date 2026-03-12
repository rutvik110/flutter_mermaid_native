# flutter_mermaid

A Flutter plugin for rendering [Mermaid](https://mermaid.js.org/) diagrams natively using Rust.

This package uses [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) to bridge Rust code that renders Mermaid diagrams to SVG/PNG, providing fast and efficient diagram rendering across all platforms.

## Supported Diagram Types

- Flowcharts
- Sequence Diagrams
- Class Diagrams
- State Diagrams
- Entity Relationship Diagrams
- Pie Charts
- Gantt Charts
- Mindmaps
- Git Graphs
- Timelines
- User Journey Diagrams

Not supported yet or lacks 100% coverage through the rust layer:

- ZenUML (Rust layer fails to parse this type) 

## Getting Started

### Prerequisites

- Flutter SDK ^3.3.0
- Rust toolchain (for building the native library)

### Installation

Add `flutter_mermaid` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mermaid:
    git:
      url: https://github.com/your-username/flutter_mermaid.git
```

### Initialize the Library

Before using any Mermaid widgets, initialize the library in your `main()` function:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mermaid/flutter_mermaid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterMermaidHelper.initialize();
  runApp(MyApp());
}
```

## Usage

### Using the MermaidDiagram Widget

The simplest way to render a Mermaid diagram:

```dart
import 'package:flutter_mermaid/flutter_mermaid.dart';

MermaidDiagram(
  diagram: '''
flowchart TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
    C --> E[End]
''',
)
```

### Widget Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `diagram` | `String` | required | The Mermaid diagram source code |
| `fit` | `BoxFit` | `BoxFit.contain` | How the image should fit in the available space |
| `padding` | `EdgeInsets` | `EdgeInsets.all(16.0)` | Padding around the diagram |

## Examples

### Flowchart

```dart
MermaidDiagram(
  diagram: '''
flowchart TB
    subgraph Frontend
        A[React App] --> B[Redux Store]
        B --> C[Components]
    end
    subgraph Backend
        D[API Gateway] --> E[Auth Service]
        D --> F[User Service]
    end
    C --> D
''',
)
```

### Sequence Diagram

```dart
MermaidDiagram(
  diagram: '''
sequenceDiagram
    participant U as User
    participant C as Client
    participant S as Server
    
    U->>C: Click Login
    C->>S: POST /auth/login
    S-->>C: JWT Token
    C-->>U: Welcome!
''',
)
```

### Class Diagram

```dart
MermaidDiagram(
  diagram: '''
classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal : +int age
    Animal: +isMammal()
    class Duck{
        +String beakColor
        +swim()
    }
''',
)
```

## Development

### Project Structure

```
flutter_mermaid/
├── lib/
│   ├── flutter_mermaid.dart      # Main library exports
│   └── src/
│       ├── core/                  # Core utilities
│       ├── rust/                  # Generated Rust bridge code
│       └── widgets/               # Flutter widgets
├── rust/
│   ├── Cargo.toml                 # Rust dependencies
│   └── src/
│       ├── api/
│       │   └── simple.rs          # Rust API implementation
│       ├── frb_generated.rs       # Generated bridge code
│       └── lib.rs                 # Rust library entry
├── example/                       # Example Flutter app
└── cargokit/                      # Build tooling for Rust
```

### Updating Rust Code

When you modify the Rust code in `rust/src/`, you need to regenerate the Dart bindings using `flutter_rust_bridge`.

#### 1. Install flutter_rust_bridge_codegen

```bash
cargo install flutter_rust_bridge_codegen
```

#### 2. Make Your Changes

Edit the Rust code in `rust/src/api/simple.rs`:

```rust
// rust/src/api/simple.rs
use merman::render::HeadlessRenderer;

pub fn render_mermaid_to_svg(diagram: String) -> String {
    let renderer = HeadlessRenderer::new();
    renderer
        .render_svg_readable_sync(&diagram)
        .expect("Failed to render diagram")
        .expect("No SVG output")
}

pub fn render_mermaid_to_png(diagram: String) -> Vec<u8> {
    let svg = render_mermaid_to_svg(diagram);
    svg_to_png(&svg)
}

// Add your new functions here...
```

#### 3. Regenerate Dart Bindings

Run the code generator from the project root:

```bash
flutter_rust_bridge_codegen generate
```

This will update the following files:
- `lib/src/rust/api/simple.dart`
- `lib/src/rust/frb_generated.dart`
- `lib/src/rust/frb_generated.io.dart`
- `lib/src/rust/frb_generated.web.dart`
- `rust/src/frb_generated.rs`

#### 4. Update Rust Dependencies

To add or update Rust dependencies, edit `rust/Cargo.toml`:

```toml
[dependencies]
flutter_rust_bridge = "=2.11.1"
merman = { version = "0.3", features = ["raster"] }
merman-core = "0.3"
resvg = "0.46"
usvg = "0.46"
# Add new dependencies here
```

Then run:

```bash
cd rust
cargo update
```

#### 5. Build and Test

```bash
# Run the example app
cd example
flutter run
```

### Adding New API Functions

1. Add your function to `rust/src/api/simple.rs`:

```rust
pub fn my_new_function(input: String) -> String {
    // Your implementation
    format!("Result: {}", input)
}
```

2. Regenerate bindings:

```bash
flutter_rust_bridge_codegen generate
```

3. Use in Dart:

```dart
import 'package:flutter_mermaid/flutter_mermaid.dart';

final result = await myNewFunction(input: "test");
```

### Troubleshooting

#### Build Errors

If you encounter build errors related to Rust:

1. Ensure Rust is installed: `rustup --version`
2. Update Rust: `rustup update`
3. Clean and rebuild:

```bash
cd rust
cargo clean
cd ../example
flutter clean
flutter pub get
flutter run
```

#### Code Generation Issues

If `flutter_rust_bridge_codegen generate` fails:

1. Ensure the codegen version matches the dependency:

```bash
cargo install flutter_rust_bridge_codegen --version 2.11.1
```

2. Check for syntax errors in your Rust code:

```bash
cd rust
cargo check
```

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| macOS    | ✅        |
| Windows  | ✅        |
| Linux    | ✅        |
| Web      | ⚠️ (requires wasm build) |
