# Frequently Asked Questions (FAQ)

## General Questions

### What is MacMind?
MacMind is a Swift package designed for local Large Language Model (LLM) processing and advanced image analysis in macOS applications. It provides a clean API for integrating AI capabilities into your apps.

### What are the system requirements?
- macOS 13.0 or later
- Swift 5+
- Ollama installed
- Xcode 14.0 or later (for development)

### Is MacMind free to use?
Yes, MacMind is open source and released under the MIT License.

## Installation & Setup

### How do I install MacMind?
Add it as a Swift Package dependency in your Xcode project:
```swift
.package(url: "https://github.com/Noah-Moller/MacMind.git", from: "1.0.0")
```

### Why do I need to install Ollama?
Ollama is required for local model inference. It provides the underlying LLM capabilities that MacMind uses.

### How do I install Ollama?
Two options:
1. Using Homebrew: `brew install ollama`
2. Download from [ollama.com/download](https://ollama.com/download)

### Why isn't my app sandbox working with MacMind?
MacMind requires network and file system access. You need to either:
1. Disable app sandbox
2. Configure appropriate entitlements

## Features & Usage

### What model does MacMind use?
MacMind uses the DeepSeek R1 (1.5B parameters) model through Ollama.

### Can I use a different model?
Currently, MacMind is optimized for DeepSeek R1, but future versions may support model customization.

### How do I use streaming responses?
```swift
model.prompt("Your prompt", streaming: true) { chunk in
    print(chunk) // Process each chunk
}
```

### Can I use MacMind with SwiftUI?
Yes! MacMind provides SwiftUI integration and includes ready-to-use views like `RemoteModelDemoView`.

### How do I process PDFs?
Use the `PDFExtract` class:
```swift
let extractor = PDFExtract()
let text = extractor.extractAll(DocumentURLs: [pdfURL])
```

### What image analysis features are available?
- Object detection
- Color analysis
- Text extraction
- Natural language descriptions
- MobileNetV2-based classification

## Performance & Optimization

### How can I improve response times?
1. Use streaming for long responses
2. Reuse model instances
3. Run server locally when possible
4. Use appropriate batch sizes

### Is MacMind thread-safe?
Yes, MacMind uses Swift's modern concurrency features and is thread-safe.

### How much memory does MacMind use?
Memory usage varies based on:
- Model size
- Input length
- Batch processing size
- Image resolution

### Can I run MacMind in the background?
Yes, MacMind supports background processing. Use appropriate task management:
```swift
Task {
    try await model.prompt("Background task")
}
```

## Server & Network

### How do I set up a MacMind server?
Follow the [Server Setup Guide](../guides/server-setup.md) for detailed instructions.

### Can I run multiple servers?
Yes, you can run multiple servers on different ports or machines.

### How do I handle network errors?
Implement proper error handling:
```swift
do {
    let response = try await model.prompt("Hello")
} catch let error as RemoteModelError {
    // Handle network-specific errors
}
```

### Is server communication secure?
By default, MacMind uses HTTP. For production, consider:
- Running behind a secure proxy
- Implementing authentication
- Using VPN for remote access

## Troubleshooting

### Why am I getting "Ollama not found"?
1. Check if Ollama is installed
2. Verify Ollama is running
3. Check PATH settings

### Why are my network requests failing?
1. Check server status
2. Verify network connectivity
3. Check firewall settings
4. Validate host/port configuration

### Why is image analysis not working?
1. Check image format support
2. Verify file permissions
3. Monitor memory usage
4. Check error messages

### How do I debug server issues?
1. Enable verbose logging
2. Check server logs
3. Monitor system resources
4. Use health check endpoint

## Development & Contributing

### How can I contribute to MacMind?
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Follow contribution guidelines

### Where can I report bugs?
Open an issue on the [GitHub repository](https://github.com/Noah-Moller/MacMind/issues).

### Is there a development roadmap?
Check the repository's Issues and Projects tabs for planned features and improvements.

### How do I run tests?
```bash
swift test
```

## Additional Resources

### Where can I find examples?
- Check the [Example Projects](../examples/README.md)
- Review the [Quick Start Guide](quick-start.md)
- Look at the [Demo View](../examples/swiftui-integration.md)

### How do I stay updated?
- Watch the GitHub repository
- Follow release announcements
- Join the community discussions

### Where can I get help?
1. Read the [documentation](../README.md)
2. Check this FAQ
3. Open GitHub issues
4. Join community discussions 