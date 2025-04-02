# Basic Concepts

This guide explains the core concepts and components of MacMind, helping you understand how the library works and how to use it effectively.

## Core Components

### 1. Local Model Processing

MacMind's `LocalModel` class provides local LLM (Large Language Model) processing using Ollama:

```swift
let model = LocalModel()
```

Key concepts:
- Uses DeepSeek R1 (1.5B parameters) model
- Runs entirely on your Mac
- Supports both streaming and non-streaming responses
- Handles model initialization and management

### 2. Remote Model Processing

The `RemoteModel` class enables communication with MacMind servers:

```swift
let model = RemoteModel(config: RemoteModelConfig(host: "192.168.1.100"))
```

Key concepts:
- Client-server architecture
- Supports distributed processing
- Same API as local model
- Network-aware error handling

### 3. Image Analysis

The `ImageClassifier` provides advanced image analysis capabilities:

```swift
let classifier = ImageClassifier()
```

Features:
- Object detection and classification
- Color analysis
- Text extraction
- Natural language descriptions
- Uses MobileNetV2 for efficient processing

### 4. PDF Processing

The `PDFExtract` class handles PDF document processing:

```swift
let extractor = PDFExtract()
```

Capabilities:
- Text extraction
- Document analysis
- Integration with LLM processing
- Batch processing support

## Architecture Overview

### Processing Flow

1. **Input Processing**
   - Text prompts
   - Images
   - PDF documents
   - Network requests

2. **Core Processing**
   - Local model inference
   - Remote server communication
   - Image analysis
   - PDF text extraction

3. **Output Generation**
   - Text responses
   - Streaming responses
   - Analysis results
   - Error handling

### Data Flow

```
Input → Preprocessing → Model Processing → Post-processing → Output
```

## Key Patterns

### 1. Async/Await

MacMind uses modern Swift concurrency:

```swift
// Async/await pattern
let response = try await model.prompt("Hello")

// Callback pattern
model.prompt("Hello") { response in
    print(response)
}
```

### 2. Error Handling

Comprehensive error handling system:

```swift
do {
    let response = try await model.prompt("Hello")
} catch let error as LocalModelError {
    // Handle specific error
} catch {
    // Handle general error
}
```

### 3. Configuration

Flexible configuration options:

```swift
// Local model configuration
let localModel = LocalModel(modelName: "custom-model")

// Remote model configuration
let config = RemoteModelConfig(
    host: "192.168.1.100",
    port: 3467
)
let remoteModel = RemoteModel(config: config)
```

## Best Practices

### 1. Model Lifecycle

```swift
// Initialize once and reuse
class MyService {
    private let model: LocalModel
    
    init() {
        model = LocalModel()
    }
}
```

### 2. Resource Management

```swift
// Use streaming for long responses
model.prompt("Write a long story", streaming: true) { chunk in
    // Process each chunk as it arrives
}
```

### 3. Error Recovery

```swift
func retryPrompt(attempts: Int = 3) async throws -> String {
    var lastError: Error?
    
    for _ in 0..<attempts {
        do {
            return try await model.prompt("Hello")
        } catch {
            lastError = error
            continue
        }
    }
    throw lastError!
}
```

## Integration Patterns

### 1. SwiftUI Integration

```swift
struct ModelView: View {
    @StateObject private var model = LocalModel()
    @State private var response = ""
    
    var body: some View {
        Text(response)
            .onAppear {
                model.prompt("Hello") { text in
                    response = text
                }
            }
    }
}
```

### 2. Combine Integration

```swift
import Combine

class ModelService {
    private let model: LocalModel
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        model = LocalModel()
    }
    
    func processPrompt() -> AnyPublisher<String, Error> {
        Future { promise in
            Task {
                do {
                    let response = try await self.model.prompt("Hello")
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
```

## Memory Management

### 1. Model Instances

- Create model instances at app startup
- Reuse instances when possible
- Properly handle cleanup

### 2. Resource Cleanup

```swift
class MyViewController {
    private var model: LocalModel?
    
    func setup() {
        model = LocalModel()
    }
    
    func cleanup() {
        model = nil // Release resources
    }
}
```

## Next Steps

- Try the [Quick Start Guide](quick-start.md)
- Explore [API Reference](../api/README.md)
- Check [Example Projects](../examples/README.md)
- Read about [Advanced Features](../features/README.md) 