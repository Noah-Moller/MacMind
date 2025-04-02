# Troubleshooting Guide

This guide helps you diagnose and resolve common issues you might encounter while using MacMind.

## Installation Issues

### Ollama Not Found

**Symptoms:**
- "Ollama not found" error
- Model initialization fails
- SetupManager reports Ollama not installed

**Solutions:**
1. Verify Ollama installation:
   ```bash
   which ollama
   ```

2. Install Ollama if missing:
   ```bash
   brew install ollama
   ```

3. Check PATH settings:
   ```bash
   echo $PATH
   ```

4. Restart Ollama:
   ```bash
   killall ollama
   open -a Ollama
   ```

### Package Resolution Fails

**Symptoms:**
- Package resolution errors in Xcode
- Build failures
- Missing dependencies

**Solutions:**
1. Clean build folder:
   - Xcode → Product → Clean Build Folder
   - Or `Cmd + Shift + K`

2. Reset package cache:
   ```bash
   rm -rf ~/Library/Caches/org.swift.swiftpm/
   ```

3. Update package references:
   ```swift
   // Package.swift
   .package(url: "https://github.com/Noah-Moller/MacMind.git", from: "1.0.0")
   ```

4. Force Xcode to resolve packages:
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions

## Model Issues

### Model Initialization Fails

**Symptoms:**
- LocalModel initialization fails
- Timeout during model setup
- Model not ready errors

**Solutions:**
1. Check Ollama status:
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. Verify model availability:
   ```swift
   if SetupManager.isOllamaInstalled() {
       print("Ollama is available")
   }
   ```

3. Increase initialization timeout:
   ```swift
   let model = LocalModel(timeout: 60) // Increase timeout to 60 seconds
   ```

### Slow Response Times

**Symptoms:**
- Long processing times
- Timeouts
- Memory pressure

**Solutions:**
1. Use streaming for long responses:
   ```swift
   model.prompt("Long prompt", streaming: true) { chunk in
       print(chunk)
   }
   ```

2. Monitor system resources:
   ```swift
   // Check available memory before processing
   let memoryAvailable = ProcessInfo.processInfo.physicalMemory
   ```

3. Implement timeout handling:
   ```swift
   func promptWithTimeout(
       _ prompt: String,
       timeout: TimeInterval
   ) async throws -> String {
       try await withTimeout(timeout) {
           return try await model.prompt(prompt)
       }
   }
   ```

## Network Issues

### Server Connection Fails

**Symptoms:**
- Connection refused errors
- Timeout errors
- Network unreachable

**Solutions:**
1. Check server status:
   ```swift
   let model = RemoteModel()
   if try await model.checkHealth() {
       print("Server is healthy")
   }
   ```

2. Verify network configuration:
   ```swift
   let config = RemoteModelConfig(
       host: "192.168.1.100",
       port: 3467
   )
   ```

3. Implement retry logic:
   ```swift
   func retryPrompt(
       attempts: Int = 3,
       delay: TimeInterval = 1.0
   ) async throws -> String {
       var lastError: Error?
       
       for attempt in 1...attempts {
           do {
               return try await model.prompt("Hello")
           } catch {
               lastError = error
               if attempt < attempts {
                   try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
               }
           }
       }
       
       throw lastError!
   }
   ```

### SSL/TLS Issues

**Symptoms:**
- Certificate validation errors
- SSL handshake failures
- Security errors

**Solutions:**
1. Verify certificates:
   ```swift
   let session = URLSession(configuration: .default)
   session.configuration.tlsMinimumSupportedProtocol = .tlsProtocol12
   ```

2. Configure trust settings:
   ```swift
   // Add custom certificate handling if needed
   class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
       func urlSession(
           _ session: URLSession,
           didReceive challenge: URLAuthenticationChallenge,
           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
       ) {
           // Handle certificate validation
       }
   }
   ```

## Image Analysis Issues

### Classification Fails

**Symptoms:**
- Low confidence scores
- Incorrect classifications
- Processing errors

**Solutions:**
1. Check image quality:
   ```swift
   func validateImage(_ image: NSImage) -> Bool {
       guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
           return false
       }
       
       let minSize = 224 // Minimum size for MobileNetV2
       return cgImage.width >= minSize && cgImage.height >= minSize
   }
   ```

2. Adjust confidence threshold:
   ```swift
   let options = ClassificationOptions(
       minimumConfidence: 0.8,
       maximumResults: 5
   )
   ```

3. Preprocess images:
   ```swift
   func preprocessImage(_ image: NSImage) -> NSImage {
       // Implement image preprocessing
       return processedImage
   }
   ```

## PDF Processing Issues

### Text Extraction Fails

**Symptoms:**
- Empty text output
- Corrupted text
- Processing errors

**Solutions:**
1. Validate PDF files:
   ```swift
   func validatePDF(_ url: URL) throws -> Bool {
       guard FileManager.default.fileExists(atPath: url.path) else {
           throw PDFProcessingError.fileNotFound
       }
       
       // Check if file is readable
       guard FileManager.default.isReadableFile(atPath: url.path) else {
           throw PDFProcessingError.accessDenied
       }
       
       return true
   }
   ```

2. Handle large files:
   ```swift
   func processLargePDF(
       _ url: URL,
       chunkSize: Int = 1000
   ) async throws -> [String] {
       // Process in chunks
   }
   ```

## Memory Management

### High Memory Usage

**Symptoms:**
- App becomes unresponsive
- Memory warnings
- Crashes

**Solutions:**
1. Implement cleanup:
   ```swift
   class ResourceManager {
       func cleanup() {
           // Release unused resources
       }
       
       func handleMemoryWarning() {
           // Handle low memory condition
       }
   }
   ```

2. Monitor memory usage:
   ```swift
   extension ProcessInfo {
       var memoryUsage: UInt64 {
           var info = mach_task_basic_info()
           var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
           
           let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
               $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                   task_info(
                       mach_task_self_,
                       task_flavor_t(MACH_TASK_BASIC_INFO),
                       $0,
                       &count
                   )
               }
           }
           
           return kerr == KERN_SUCCESS ? info.resident_size : 0
       }
   }
   ```

## Getting Help

If you're still experiencing issues:

1. Check the [FAQ](../getting-started/faq.md)
2. Review [API Documentation](../api/README.md)
3. [Open an Issue](https://github.com/Noah-Moller/MacMind/issues)
4. Join community discussions

## Debugging Tools

### 1. Debug Logging

```swift
class DebugLogger {
    static func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level)] \(file):\(line) - \(message)")
    }
}

enum LogLevel: String {
    case debug, info, warning, error
}
```

### 2. Network Debugging

```swift
class NetworkDebugger {
    static func logRequest(_ request: URLRequest) {
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
    }
    
    static func logResponse(_ response: URLResponse?, data: Data?) {
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
        }
        if let data = data, let str = String(data: data, encoding: .utf8) {
            print("Response: \(str)")
        }
    }
}
```

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Basic Concepts](../getting-started/basic-concepts.md)
- [API Reference](../api/README.md)
- [Example Projects](../examples/README.md) 