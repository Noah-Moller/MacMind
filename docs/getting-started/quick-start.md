# Quick Start Guide

This guide will help you get started with MacMind quickly. We'll cover the basic usage patterns for both local and remote LLM processing.

## Prerequisites

Ensure you have:
- Completed the [installation](installation.md)
- Ollama running on your machine (for local processing)
- Xcode and a macOS project ready

## 1. Basic Local LLM Processing

### Initialize the Model

```swift
import MacMind
import SwiftUI

struct ContentView: View {
    @State private var modelReady = false
    @State private var localModel: LocalModel?
    @State private var showSetupAlert = false
    
    var body: some View {
        if !modelReady {
            Text("Setting up model...")
                .onAppear {
                    localModel = LocalModel() { success in
                        modelReady = success
                        if !success {
                            showSetupAlert = true
                        }
                    }
                }
        } else {
            // Your main view here
        }
    }
}
```

### Send a Simple Prompt

```swift
// Non-streaming response
Task {
    do {
        let response = try await localModel?.prompt("What is quantum computing?")
        print(response ?? "No response")
    } catch {
        print("Error: \(error)")
    }
}

// Streaming response
localModel?.prompt("Tell me a story", streaming: true) { chunk in
    print(chunk) // Each chunk as it arrives
}
```

## 2. Remote LLM Processing

### Connect to a Remote Server

```swift
import MacMind

let remoteModel = RemoteModel(config: RemoteModelConfig(
    host: "192.168.1.100",
    port: 3467
))
```

### Check Server Health

```swift
Task {
    do {
        let isHealthy = try await remoteModel.checkHealth()
        print("Server is \(isHealthy ? "healthy" : "unhealthy")")
    } catch {
        print("Connection error: \(error)")
    }
}
```

### Send Remote Prompts

```swift
// Async/await style
Task {
    do {
        let response = try await remoteModel.prompt("Explain neural networks")
        print(response)
    } catch {
        print("Error: \(error)")
    }
}

// Streaming style
remoteModel.prompt("Write a long story", streaming: true) { chunk in
    print(chunk)
}
```

## 3. Image Analysis

```swift
import MacMind

let classifier = ImageClassifier()

if let image = NSImage(contentsOf: imageURL) {
    Task {
        do {
            let result = try await classifier.analyzeImage(image)
            print("Description: \(result.description)")
            print("Dominant colors: \(result.dominantColors)")
            
            if !result.extractedText.isEmpty {
                print("Text found: \(result.extractedText.joined(separator: " "))")
            }
        } catch {
            print("Analysis failed: \(error)")
        }
    }
}
```

## 4. PDF Processing

```swift
import MacMind

let pdfExtractor = PDFExtract()
let text = pdfExtractor.extractAll(DocumentURLs: [pdfURL])

// Use extracted text with LLM
Task {
    do {
        let response = try await localModel?.prompt(
            "Summarize this document: \(text)"
        )
        print(response ?? "No response")
    } catch {
        print("Error: \(error)")
    }
}
```

## 5. Using the SwiftUI Demo View

For quick testing of remote functionality:

```swift
import SwiftUI
import MacMind

struct ContentView: View {
    var body: some View {
        RemoteModelDemoView(
            serverAddress: "192.168.1.100",
            serverPort: 3467
        )
    }
}
```

## Next Steps

- Learn about [Basic Concepts](basic-concepts.md)
- Explore [Advanced Examples](../examples/advanced-usage.md)
- Read the [API Reference](../api/README.md)
- Set up a [MacMind Server](../guides/server-setup.md)

## Common Issues

1. **Model Not Ready**
   - Ensure Ollama is running
   - Check network connectivity
   - Verify model installation

2. **Permission Errors**
   - Check app sandbox settings
   - Verify file system permissions
   - Ensure network permissions

3. **Performance Issues**
   - Use streaming for long responses
   - Consider running heavy processing in background
   - Monitor memory usage

## Getting Help

- Check the [Troubleshooting Guide](../guides/troubleshooting.md)
- Review the [FAQ](faq.md)
- [Open an Issue](https://github.com/Noah-Moller/MacMind/issues) 