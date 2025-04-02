# RemoteModel API Reference

The `RemoteModel` class provides a client interface for communicating with MacMind servers. It supports both streaming and non-streaming responses, making it easy to interact with remote LLM processing capabilities.

## Overview

```swift
public class RemoteModel {
    public init(config: RemoteModelConfig = RemoteModelConfig())
}
```

The `RemoteModel` class is designed to be easy to use while providing powerful features for remote LLM processing.

## Configuration

### RemoteModelConfig

```swift
public struct RemoteModelConfig {
    public let host: String
    public let port: Int
    
    public init(host: String = "localhost", port: Int = 3467)
}
```

Configuration options for connecting to a MacMind server:
- `host`: The hostname or IP address of the server (default: "localhost")
- `port`: The port number the server is running on (default: 3467)

## Error Handling

```swift
public enum RemoteModelError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
}
```

The `RemoteModelError` enum provides detailed error information for various failure scenarios.

## Core Methods

### Check Server Health

```swift
public func checkHealth() async throws -> Bool
```

Checks if the MacMind server is running and healthy.

**Returns:**
- `true` if the server is healthy
- `false` otherwise

**Throws:**
- `RemoteModelError.networkError` if the network request fails
- `RemoteModelError.invalidResponse` if the response is invalid

**Example:**
```swift
let model = RemoteModel(config: RemoteModelConfig(host: "192.168.1.100"))
do {
    let isHealthy = try await model.checkHealth()
    print("Server is \(isHealthy ? "healthy" : "unhealthy")")
} catch {
    print("Error checking server health: \(error)")
}
```

### Get Server Status

```swift
public func getStatus() async throws -> [String: Any]
```

Retrieves the current status of the MacMind server.

**Returns:**
- A dictionary containing server status information

**Throws:**
- `RemoteModelError.networkError` if the network request fails
- `RemoteModelError.invalidResponse` if the response is invalid
- `RemoteModelError.decodingError` if the response cannot be decoded

**Example:**
```swift
let model = RemoteModel()
do {
    let status = try await model.getStatus()
    print("Server status: \(status)")
} catch {
    print("Error getting status: \(error)")
}
```

### Send Prompt (Callback Style)

```swift
public func prompt(
    _ prompt: String,
    streaming: Bool = false,
    showThinking: Bool = true,
    pdfURLs: [URL]? = nil,
    onResponse: @escaping (String) -> Void
)
```

Sends a prompt to the server and receives responses through a callback.

**Parameters:**
- `prompt`: The text prompt to send to the model
- `streaming`: Whether to stream the response (default: false)
- `showThinking`: Whether to show thinking indicators (default: true)
- `pdfURLs`: Optional array of PDF URLs to include as context
- `onResponse`: Callback function that receives response chunks

**Example:**
```swift
let model = RemoteModel()
model.prompt("What is quantum computing?", streaming: true) { chunk in
    print("Received: \(chunk)")
}
```

### Send Prompt (Async/Await Style)

```swift
public func prompt(
    _ prompt: String,
    showThinking: Bool = true,
    pdfURLs: [URL]? = nil
) async throws -> String
```

Sends a prompt to the server and returns the complete response.

**Parameters:**
- `prompt`: The text prompt to send to the model
- `showThinking`: Whether to show thinking indicators (default: true)
- `pdfURLs`: Optional array of PDF URLs to include as context

**Returns:**
- The complete response from the model

**Throws:**
- `RemoteModelError.networkError` if the network request fails
- `RemoteModelError.invalidResponse` if the response is invalid
- `RemoteModelError.serverError` if the server returns an error
- `RemoteModelError.decodingError` if the response cannot be decoded

**Example:**
```swift
let model = RemoteModel()
do {
    let response = try await model.prompt("Explain neural networks")
    print("Response: \(response)")
} catch {
    print("Error: \(error)")
}
```

## SwiftUI Integration

MacMind provides a ready-to-use SwiftUI view for interacting with remote models:

```swift
public struct RemoteModelDemoView: View {
    public init(serverAddress: String = "localhost", serverPort: Int = 3467)
}
```

**Example:**
```swift
struct ContentView: View {
    var body: some View {
        RemoteModelDemoView(
            serverAddress: "192.168.1.100",
            serverPort: 3467
        )
    }
}
```

## Best Practices

1. **Error Handling**
   - Always handle potential errors using try-catch
   - Provide meaningful error messages to users
   - Implement retry logic for transient network issues

2. **Configuration**
   - Use appropriate timeouts for your use case
   - Consider network conditions when choosing streaming vs. non-streaming
   - Store server configuration in a central location

3. **Performance**
   - Reuse RemoteModel instances when possible
   - Use streaming for long responses
   - Consider implementing caching for frequently used prompts

4. **Security**
   - Use secure connections when possible
   - Validate server certificates
   - Don't expose sensitive information in prompts

## See Also

- [Server Setup Guide](../guides/server-setup.md)
- [Remote Communication Guide](../guides/remote-communication.md)
- [SwiftUI Integration](../examples/swiftui-integration.md)
- [Troubleshooting](../guides/troubleshooting.md) 