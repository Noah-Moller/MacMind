//
//  LocalModel.swift
//  Mac Mind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation
import PDFKit

/// Provides a public API to interact with the local DeepSeek R1 model via the Ollama REST API.
public class LocalModel {
    
    /// Base URL for the local Ollama REST API.
    private let baseURL = URL(string: "http://localhost:11434/api/")!
    /// Identifier for the model to be used.
    private let model = "deepseek-r1:1.5b"
    /// Shared URL session for non-streaming requests.
    private let session: URLSession = URLSession.shared
    
    private let imageClassifier = ImageClassifier()
    
    /// Initializes a new instance of LocalModel.
    public init(completion: @Sendable @escaping (Bool) -> Void = { _ in }) async {
        // Optionally, pull the model if not already downloaded.
        // (You might want to check some cached flag or status in a production app.)
        await SetupManager().setup()
    }
    
    /// Executes a prompt against the local model with optional images and PDFs (async version).
    ///
    /// - Parameters:
    ///   - prompt: The prompt text to send to the model.
    ///   - images: Optional array of images to analyze and include in the context.
    ///   - streaming: If `true`, the completion handler is called repeatedly as new data chunks arrive.
    ///   - showThinking: If `false`, any text between `<think>` and `</think>` is removed from the output.
    ///   - pdfs: Optional array of PDF documents to include in the context.
    ///   - webAccess: Whether to allow web access and scrape URLs found in the prompt.
    ///   - completion: A closure called with the generated text as a `String`.
    public func prompt(_ prompt: String,
                      images: [NSImage]? = nil,
                      streaming: Bool = false,
                      showThinking: Bool = true,
                      pdfs: [PDFDocument]? = nil,
                      webAccess: Bool = false,
                      completion: @escaping (String) -> Void) async {
        do {
            var fullPrompt = prompt
            var webContext = ""
            
            // If web access is enabled, try to extract and scrape URLs from the prompt
            if webAccess {
                let urlPattern = try NSRegularExpression(pattern: "https?://[^\\s]+")
                let range = NSRange(prompt.startIndex..., in: prompt)
                let matches = urlPattern.matches(in: prompt, range: range)
                
                for match in matches {
                    if let range = Range(match.range, in: prompt) {
                        let url = String(prompt[range])
                        do {
                            let scrapedContent = try await WebScraper.scrapeWebsite(url: url)
                            webContext += """
                            
                            Content from \(url):
                            \(scrapedContent)
                            
                            """
                        } catch {
                            print("Failed to scrape URL \(url): \(error)")
                        }
                    }
                }
            }
            
            // If images are provided, analyze them first
            if let images = images, !images.isEmpty {
                var imageAnalyses: [String] = []
                
                for (index, image) in images.enumerated() {
                    let analysis = try await imageClassifier.analyzeImage(image)
                    let imageContext = """
                    
                    Image \(index + 1) Analysis:
                    - Description: \(analysis.description)
                    - Detected Objects: \(analysis.predictions.map { "\($0.label) (\(Int($0.probability * 100))%)" }.joined(separator: ", "))
                    - Dominant Colors: \(analysis.dominantColors.joined(separator: ", "))
                    \(analysis.extractedText.isEmpty ? "" : "- Extracted Text: \"\(analysis.extractedText.joined(separator: " "))\"")
                    """
                    imageAnalyses.append(imageContext)
                }
                
                fullPrompt = """
                Context from Images:
                \(imageAnalyses.joined(separator: "\n"))
                \(webContext.isEmpty ? "" : "\nWeb Context:\n\(webContext)")
                
                User Question: \(prompt)
                
                Please provide a response that takes into account all aspects of the image analyses, web content, and the user's question.
                """
            } else if !webContext.isEmpty {
                // If we only have web context
                fullPrompt = """
                Web Context:
                \(webContext)
                
                User Question: \(prompt)
                
                Please provide a response that takes into account the web content and the user's question.
                """
            }
            
            // Send the prompt to the language model
            sendPrompt(fullPrompt, streaming: streaming, showThinking: showThinking, pdfs: pdfs, webAccess: webAccess) { response in
                completion(response)
            }
        } catch {
            completion("Error processing request: \(error.localizedDescription)")
        }
    }
    
    /// Non-async version of prompt that automatically handles async calls
    ///
    /// - Parameters:
    ///   - prompt: The prompt text to send to the model.
    ///   - streaming: If `true`, the completion handler is called repeatedly as new data chunks arrive.
    ///   - showThinking: If `false`, any text between `<think>` and `</think>` is removed from the output.
    ///   - pdfs: Optional array of PDF documents to include in the context.
    ///   - webAccess: Whether to allow web access (currently not implemented).
    ///   - completion: A closure called with the generated text as a `String`.
    public func sendPromptSync(_ prompt: String,
                             streaming: Bool = false,
                             showThinking: Bool = true,
                             pdfs: [PDFDocument]? = nil,
                             webAccess: Bool = false,
                             completion: @escaping (String) -> Void) {
        // Create a Task to handle the async call
        Task {
            await self.prompt(
                prompt,
                streaming: streaming,
                showThinking: showThinking,
                pdfs: pdfs,
                webAccess: webAccess,
                completion: completion
            )
        }
    }
    
    /// Internal method to send a prompt to the Ollama API
    private func sendPrompt(_ promptText: String,
                       streaming: Bool = false,
                       showThinking: Bool = true,
                       pdfs: [PDFDocument]? = nil,
                       webAccess: Bool? = false,
                       completion: @Sendable @escaping (String) -> Void) {
        // Extract text from provided PDF documents if any.
        var pdfContent: String = ""
        if let PDFs = pdfs {
            pdfContent = PDFExtract().extractAll(Documents: PDFs)
        }
        
        // Create the URL for the chat endpoint.
        let url = baseURL.appendingPathComponent("chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Build the JSON payload with model identifier and user message.
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": pdfContent + promptText]
            ]
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON payload: \(error)")
            completion("")
            return
        }
        
        // Helper function to remove text between <think> and </think>.
        func filterThinking(from text: String) -> String {
            let pattern = "<think>.*?(</think>|$)"
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
                let range = NSRange(text.startIndex..., in: text)
                return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            } catch {
                print("Regex creation failed with error: \(error.localizedDescription)")
                return text
            }
        }
        
        if streaming {
            // Create a stateful delegate to handle streaming data.
            let streamingDelegate = StreamingDelegate(showThinking: showThinking, filter: filterThinking) { newText in
                DispatchQueue.main.async {
                    completion(newText)
                }
            }
            let config = URLSessionConfiguration.default
            let streamingSession = URLSession(configuration: config, delegate: streamingDelegate, delegateQueue: nil)
            
            // Start the streaming data task.
            let task = streamingSession.dataTask(with: request)
            task.resume()
        } else {
            // Non-streaming mode: use a standard data task.
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error calling Ollama REST API: \(error)")
                    DispatchQueue.main.async { completion("") }
                    return
                }
                guard let data = data, let rawOutput = String(data: data, encoding: .utf8) else {
                    print("No data received from Ollama REST API.")
                    DispatchQueue.main.async { completion("") }
                    return
                }
                
                // Process the response by splitting it into individual lines.
                let lines = rawOutput.components(separatedBy: "\n")
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                var fullResponse = ""
                // For each line, parse the JSON to extract the message content.
                for line in lines {
                    if let jsonData = line.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                               let messageDict = json["message"] as? [String: Any],
                               let content = messageDict["content"] as? String {
                                fullResponse += content
                            }
                        } catch {
                            print("Error parsing JSON line: \(error)")
                        }
                    }
                }
                
                // Conditionally filter out text marked as thinking.
                let finalResponse = showThinking ? fullResponse : filterThinking(from: fullResponse)
                DispatchQueue.main.async {
                    completion(finalResponse)
                }
            }
            task.resume()
        }
    }
    
    /// Executes a prompt against the local model with image analysis.
    ///
    /// This method first analyzes the image using the MobileNetV2 model, then combines the image analysis
    /// with the provided prompt text before sending it to the language model. The analysis includes object
    /// detection, color analysis, and text extraction.
    ///
    /// - Parameters:
    ///   - promptText: The prompt text to send to the model.
    ///   - image: The image to analyze.
    ///   - streaming: If `true`, the completion handler is called repeatedly as new data chunks arrive.
    ///   - showThinking: If `false`, any text between `<think>` and `</think>` is removed from the output.
    ///   - completion: A closure called with the generated text (or partial updates) as a `String`.
    public func promptWithImage(_ promptText: String,
                              image: NSImage,
                              streaming: Bool = false,
                              showThinking: Bool = true,
                              completion: @escaping (String) -> Void) async {
        do {
            // Analyze the image using the enhanced image classifier
            let analysisResult = try await imageClassifier.analyzeImage(image)
            
            // Build a comprehensive prompt that includes all analysis results
            let combinedPrompt = """
                Image Analysis:
                - Description: \(analysisResult.description)
                - Detected Objects: \(analysisResult.predictions.map { "\($0.label) (\(Int($0.probability * 100))%)" }.joined(separator: ", "))
                - Dominant Colors: \(analysisResult.dominantColors.joined(separator: ", "))
                \(analysisResult.extractedText.isEmpty ? "" : "- Extracted Text: \"\(analysisResult.extractedText.joined(separator: " "))\"")
                
                User Question: \(promptText)
                
                Please provide a response that takes into account all aspects of the image analysis (objects, colors, text if present) and the user's question.
                """
            
            // Send the combined prompt to the language model
            sendPrompt(combinedPrompt, streaming: streaming, showThinking: showThinking) { response in
                completion(response)
            }
        } catch {
            completion("Error analyzing image: \(error.localizedDescription)")
        }
    }
}

/// A delegate class to handle streaming responses from the Ollama REST API.
///
/// This delegate processes incoming data chunks, optionally filtering out thinking text,
/// and passes the new content to the provided callback.
private final class StreamingDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    /// Closure invoked with new text content.
    private let onDataReceived: @Sendable (String) -> Void
    /// Indicates whether to include thinking text in the output.
    private let showThinking: Bool
    /// Closure to filter the accumulated text (e.g., to remove thinking text).
    private let filter: (String) -> String
    
    /// Buffer to hold accumulated streaming text.
    private var buffer: String = ""
    /// Tracks the count of characters already sent to the caller.
    private var lastSentCount: Int = 0
    
    /// Initializes the streaming delegate.
    ///
    /// - Parameters:
    ///   - showThinking: If `true`, thinking text is not filtered out.
    ///   - filter: A closure that filters the accumulated text.
    ///   - onDataReceived: Closure called with new text content as it is received.
    init(showThinking: Bool,
         filter: @escaping (String) -> String,
         onDataReceived: @Sendable @escaping (String) -> Void) {
        self.showThinking = showThinking
        self.filter = filter
        self.onDataReceived = onDataReceived
    }
    
    /// Called by the URL session when data is received.
    ///
    /// Processes incoming data chunks, splits them into lines,
    /// extracts JSON message content, and then applies filtering if needed.
    ///
    /// - Parameters:
    ///   - session: The URL session.
    ///   - dataTask: The data task.
    ///   - data: The incoming data chunk.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        
        // Split the chunk into lines and extract JSON message content.
        let lines = chunk.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var newContent = ""
        for line in lines {
            if let jsonData = line.data(using: .utf8) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let messageDict = json["message"] as? [String: Any],
                       let content = messageDict["content"] as? String {
                        newContent += content
                    }
                } catch {
                    print("Error parsing JSON chunk: \(error)")
                }
            }
        }
        
        if showThinking {
            // If no filtering is requested, send the new content immediately.
            onDataReceived(newContent)
        } else {
            // Append new content to the buffer.
            buffer += newContent
            // Filter the full accumulated text.
            let processed = filter(buffer)
            // Determine the new text that hasn't been sent yet.
            let newText = String(processed.dropFirst(lastSentCount))
            lastSentCount = processed.count
            onDataReceived(newText)
        }
    }
}
