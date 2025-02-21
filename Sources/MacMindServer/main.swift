import Foundation
import ArgumentParser
import Vapor
import MacMind

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
    
    func run() async throws {
        print("Starting MacMind server on \(host):\(port)...")
        
        let app = try await Application.make()
        
        // Configure CORS
        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
        )
        app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
        
        // Create a shared LocalModel instance and modelReady state
        actor ModelState {
            var isReady: Bool = false
            
            func setReady(_ value: Bool) {
                isReady = value
            }
            
            func getReady() -> Bool {
                return isReady
            }
        }
        
        let modelState = ModelState()
        let model = LocalModel { success in
            Task {
                await modelState.setReady(success)
                if success {
                    print("Model initialization successful")
                } else {
                    print("Failed to initialize model")
                }
            }
        }
        
        // Health check endpoint
        app.get("health") { req -> String in
            return "MacMind server is running"
        }
        
        // Model status endpoint
        app.get("status") { req async -> [String: Bool] in
            return [
                "server_running": true,
                "ollama_installed": SetupManager.isOllamaInstalled(),
                "model_ready": await modelState.getReady()
            ]
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
            
            if promptRequest.stream == true {
                // Handle streaming response
                return Response(
                    status: .ok,
                    headers: ["Content-Type": "text/event-stream"],
                    body: .init(stream: { writer in
                        model.prompt(promptRequest.prompt) { response in
                            let data = "data: \(response)\n\n".data(using: .utf8)!
                            _ = writer.write(.buffer(.init(data: data)))
                        }
                        writer.write(.end, promise: nil)
                    })
                )
            } else {
                // Create a promise for the non-streaming response
                let promise = req.eventLoop.makePromise(of: String.self)
                
                // Call prompt with completion handler
                model.prompt(promptRequest.prompt) { response in
                    promise.succeed(response)
                }
                
                // Wait for the promise and return response
                let response = try await promise.futureResult.get()
                return Response(
                    status: .ok,
                    headers: ["Content-Type": "application/json"],
                    body: .init(string: """
                        {"response": "\(response.replacingOccurrences(of: "\"", with: "\\\""))"}
                        """)
                )
            }
        }
        
        // Configure server
        app.http.server.configuration.hostname = host
        app.http.server.configuration.port = port
        
        // Start the server
        try await app.execute()
    }
}

MacMindServer.main() 