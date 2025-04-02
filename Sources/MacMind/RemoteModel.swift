import Foundation

/// Represents errors that can occur when communicating with a MacMind server
public enum RemoteModelError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
}

/// Configuration for a remote MacMind server
public struct RemoteModelConfig {
    public let host: String
    public let port: Int
    
    public init(host: String = "localhost", port: Int = 3467) {
        self.host = host
        self.port = port
    }
}

/// A model that communicates with a remote MacMind server
public class RemoteModel {
    private let config: RemoteModelConfig
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    public init(config: RemoteModelConfig = RemoteModelConfig()) {
        self.config = config
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    /// Base URL for the MacMind server
    private var baseURL: String {
        "http://\(config.host):\(config.port)"
    }
    
    /// Check if the server is healthy
    public func checkHealth() async throws -> Bool {
        let url = URL(string: "\(baseURL)/health")!
        let (_, response) = try await session.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
    
    /// Get server status
    public func getStatus() async throws -> [String: Any] {
        let url = URL(string: "\(baseURL)/status")!
        let (data, _) = try await session.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RemoteModelError.invalidResponse
        }
        return json
    }
    
    /// Send a prompt to the server
    /// - Parameters:
    ///   - prompt: The prompt text to send
    ///   - streaming: Whether to stream the response
    ///   - showThinking: Whether to show thinking indicators
    ///   - pdfURLs: Optional array of PDF URLs to include as context
    ///   - onResponse: Callback for receiving responses (required for streaming)
    public func prompt(
        _ prompt: String,
        streaming: Bool = false,
        showThinking: Bool = true,
        pdfURLs: [URL]? = nil,
        onResponse: @escaping (String) -> Void
    ) {
        Task {
            do {
                if streaming {
                    try await streamingPrompt(
                        prompt,
                        showThinking: showThinking,
                        pdfURLs: pdfURLs,
                        onResponse: onResponse
                    )
                } else {
                    let response = try await nonStreamingPrompt(
                        prompt,
                        showThinking: showThinking,
                        pdfURLs: pdfURLs
                    )
                    onResponse(response)
                }
            } catch {
                onResponse("Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send a prompt and get a response (async/await version)
    /// - Parameters:
    ///   - prompt: The prompt text to send
    ///   - showThinking: Whether to show thinking indicators
    ///   - pdfURLs: Optional array of PDF URLs to include as context
    /// - Returns: The model's response
    public func prompt(
        _ prompt: String,
        showThinking: Bool = true,
        pdfURLs: [URL]? = nil
    ) async throws -> String {
        return try await nonStreamingPrompt(
            prompt,
            showThinking: showThinking,
            pdfURLs: pdfURLs
        )
    }
    
    // MARK: - Private Methods
    
    private func nonStreamingPrompt(
        _ prompt: String,
        showThinking: Bool,
        pdfURLs: [URL]?
    ) async throws -> String {
        let url = URL(string: "\(baseURL)/prompt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "stream": false,
            "showThinking": showThinking,
            "pdfURLs": pdfURLs?.map { $0.absoluteString } ?? []
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteModelError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RemoteModelError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw RemoteModelError.decodingError(NSError(domain: "", code: -1))
        }
        
        return responseString
    }
    
    private func streamingPrompt(
        _ prompt: String,
        showThinking: Bool,
        pdfURLs: [URL]?,
        onResponse: @escaping (String) -> Void
    ) async throws {
        let url = URL(string: "\(baseURL)/prompt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "stream": true,
            "showThinking": showThinking,
            "pdfURLs": pdfURLs?.map { $0.absoluteString } ?? []
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteModelError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RemoteModelError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        for try await line in bytes.lines {
            // Handle SSE format by stripping "data:" prefix and processing content
            if line.hasPrefix("data: ") {
                let content = line.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty {
                    onResponse(String(content))
                }
            }
        }
    }
} 