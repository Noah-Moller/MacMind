import Foundation
import ArgumentParser
import Vapor
import MacMind
import PDFKit

@preconcurrency import MacMind

struct MacMindServer: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "macmind",
        abstract: "Run the MacMind server for API access"
    )
    
    @ArgumentParser.Option(name: .long, help: "The port to run the server on")
    var port: Int = 3467
    
    @ArgumentParser.Option(name: .long, help: "The host address to bind to")
    var host: String = "0.0.0.0"
    
    mutating func run() throws {
        print("Starting MacMind server on \(host):\(port)...")
        
        // First check if Ollama is installed
        guard SetupManager.isOllamaInstalled() else {
            print("Error: Ollama is not installed. Please install it first.")
            throw Abort(.serviceUnavailable, reason: "Ollama is not installed")
        }
        
        print("Checking DeepSeek model installation...")
        if !SetupManager.isDeepSeekInstalled() {
            print("DeepSeek model not found. Pulling model (this may take a while)...")
        }
        
        // Capture configuration values
        let serverPort = self.port
        let serverHost = self.host
        
        // Run the async server in a Task
        _ = Task {
            do {
                // Create Vapor application
                let app = try await Application.make()
                
                // Configure CORS
                let corsConfiguration = CORSMiddleware.Configuration(
                    allowedOrigin: .all,
                    allowedMethods: [.GET, .POST, .OPTIONS],
                    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
                )
                app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
                
                // Create a shared LocalModel instance
                let model = LocalModel()
                
                // Create request logger
                let logger = RequestLogger()
                
                // Health check endpoint
                app.get("health") { req -> String in
                    return "MacMind server is running"
                }
                
                // Model status endpoint
                app.get("status") { req -> [String: Bool] in
                    return [
                        "server_running": true,
                        "ollama_installed": SetupManager.isOllamaInstalled(),
                        "model_ready": true
                    ]
                }
                
                // Logs endpoint
                app.get("logs") { req -> String in
                    return logger.getLogContents()
                }
                
                // Prompt endpoint
                app.post("prompt") { req async throws -> Response in
                    struct PromptRequest: Content {
                        let prompt: String
                        let stream: Bool?
                        let showThinking: Bool?
                        let pdfURLs: [URL]?
                    }
                    
                    let promptRequest = try req.content.decode(PromptRequest.self)
                    
                    // Log the request
                    let clientIP = req.remoteAddress?.hostname ?? "unknown"
                    logger.logRequest(prompt: promptRequest.prompt, ip: clientIP)
                    
                    // Convert URLs to PDFDocuments if provided
                    let pdfDocuments: [PDFDocument]? = promptRequest.pdfURLs?.compactMap { url in
                        guard let document = PDFDocument(url: url) else { return nil }
                        return document
                    }
                    
                    if promptRequest.stream == true {
                        // Handle streaming response
                        return Response(
                            status: .ok,
                            headers: ["Content-Type": "text/event-stream",
                                     "Cache-Control": "no-cache",
                                     "Connection": "keep-alive"],
                            body: .init(stream: { writer in
                                model.prompt(
                                    promptRequest.prompt,
                                    streaming: true,
                                    showThinking: promptRequest.showThinking ?? true,
                                    pdfs: pdfDocuments,
                                    webAccess: false
                                ) { response in
                                    let data = "data: \(response)\n\n".data(using: .utf8)!
                                    _ = writer.write(.buffer(.init(data: data)))
                                }
                            })
                        )
                    } else {
                        return try await withCheckedThrowingContinuation { continuation in
                            model.prompt(
                                promptRequest.prompt,
                                streaming: false,
                                showThinking: promptRequest.showThinking ?? true,
                                pdfs: pdfDocuments,
                                webAccess: false
                            ) { response in
                                let jsonResponse = Response(
                                    status: .ok,
                                    headers: ["Content-Type": "application/json"],
                                    body: .init(string: """
                                        {"response": "\(response.replacingOccurrences(of: "\"", with: "\\\""))"}
                                        """)
                                )
                                continuation.resume(returning: jsonResponse)
                            }
                        }
                    }
                }
                
                // Configure server
                app.http.server.configuration.hostname = serverHost
                app.http.server.configuration.port = serverPort
                
                // Start the server
                print("Server starting on http://\(serverHost):\(serverPort)")
                try await app.execute()
            } catch {
                print("Server error: \(error)")
            }
        }
        
        // Keep the main thread running
        RunLoop.current.run()
    }
}

MacMindServer.main() 