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
    
    /// Executes a prompt against the local model.
    ///
    /// This method builds a JSON payload combining any extracted PDF text (if provided) with the prompt text,
    /// and sends the request to the Ollama REST API. It supports both streaming and non-streaming modes.
    ///
    /// - Parameters:
    ///   - promptText: The prompt text to send to the model.
    ///   - streaming: If `true`, the completion handler is called repeatedly as new data chunks arrive.
    ///   - showThinking: If `false`, any text between `<think>` and `</think>` is removed from the output.
    ///   - pdfURLs: An optional array of URLs pointing to PDF documents; their content is extracted and
    ///              prepended to the prompt.
    ///   - completion: A closure called with the generated text (or partial updates) as a `String`.
    public func prompt(_ promptText: String,
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
    /// This method first analyzes the image using the ResNet50 model, then combines the image analysis
    /// with the provided prompt text before sending it to the language model.
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
            // Analyze the image
            let predictions = try await imageClassifier.classify(image: image)
            let imageDescription = imageClassifier.getImageDescription(predictions: predictions)
            
            // Combine image analysis with the prompt
            let combinedPrompt = """
                Image Analysis: \(imageDescription)
                
                User Question: \(promptText)
                
                Please provide a response that takes into account both the image content and the user's question.
                """
            
            // Send the combined prompt to the language model
            prompt(combinedPrompt, streaming: streaming, showThinking: showThinking) { response in
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
