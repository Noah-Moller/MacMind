import Foundation
import CoreML
import Vision
import AppKit

public struct ImagePrediction: Identifiable, Codable {
    public let id = UUID()
    public let label: String
    public let probability: Double
    
    public var description: String {
        return "\(label) (\(Int(probability * 100))%)"
    }
}

public class ImageClassifier {
    private var model: VNCoreMLModel?
    
    public init() {
        do {
            // Try multiple approaches to find the model
            let modelURL = findModelURL()
            guard let url = modelURL else {
                print("Failed to find the model file. Searched in bundle and file system.")
                return
            }
            
            print("Found model at: \(url.path)")
            
            // Create the model
            model = try VNCoreMLModel(for: MLModel(contentsOf: url))
        } catch {
            print("Failed to create the model: \(error)")
        }
    }
    
    private func findModelURL() -> URL? {
        let modelName = "Resnet50"
        
        // Get the bundle containing this code
        let codeBundle = Bundle(for: ImageClassifier.self)
        print("Code bundle path: \(codeBundle.bundlePath)")
        
        // Try finding the compiled model
        if let url = codeBundle.url(forResource: modelName, withExtension: "mlmodelc") {
            print("Found compiled model in code bundle")
            return url
        }
        
        // Try finding the model package
        if let url = codeBundle.url(forResource: modelName, withExtension: "mlpackage") {
            print("Found model package in code bundle")
            return url
        }
        
        // Try finding in the main bundle
        if let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
            print("Found compiled model in main bundle")
            return url
        }
        
        // Try finding in the main bundle resources
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Resources/\(modelName).mlpackage") {
            if FileManager.default.fileExists(atPath: url.path) {
                print("Found model package in main bundle resources")
                return url
            }
        }
        
        // Try finding relative to the executable path
        if let executableURL = Bundle.main.executableURL {
            let baseURL = executableURL.deletingLastPathComponent()
            let possibleLocations = [
                baseURL.appendingPathComponent("Resources/\(modelName).mlpackage"),
                baseURL.appendingPathComponent("\(modelName).mlpackage"),
                baseURL.appendingPathComponent("MacMind_MacMind.bundle/Contents/Resources/\(modelName).mlpackage")
            ]
            
            for url in possibleLocations {
                if FileManager.default.fileExists(atPath: url.path) {
                    print("Found model at: \(url.path)")
                    return url
                }
            }
        }
        
        print("\nSearched locations:")
        print("1. Code bundle: \(codeBundle.bundlePath)")
        print("2. Main bundle: \(Bundle.main.bundlePath)")
        if let resourcePath = Bundle.main.resourcePath {
            print("3. Main bundle resources: \(resourcePath)")
        }
        if let executablePath = Bundle.main.executablePath {
            print("4. Executable path: \(executablePath)")
        }
        
        return nil
    }
    
    public func classify(image: NSImage, topK: Int = 3) async throws -> [ImagePrediction] {
        guard let model = model else {
            throw NSError(domain: "ImageClassifier", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "ImageClassifier", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"])
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Vision ML Request Error: \(error)")
                return
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])
        
        guard let results = request.results as? [VNClassificationObservation] else {
            throw NSError(domain: "ImageClassifier", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to process results"])
        }
        
        return results.prefix(topK).map { observation in
            ImagePrediction(label: observation.identifier, probability: Double(observation.confidence))
        }
    }
    
    public func getImageDescription(predictions: [ImagePrediction]) -> String {
        let topPredictions = predictions.prefix(3)
        let description = topPredictions.map { "'\($0.label)' (\(Int($0.probability * 100))% confidence)" }.joined(separator: ", ")
        return "The image appears to contain: \(description)"
    }
} 