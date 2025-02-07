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
        let modelExtension = "mlmodelc"
        
        // Try the bundle that contains this class
        let currentBundle = Bundle(for: type(of: self))
        if let url = currentBundle.url(forResource: modelName, withExtension: modelExtension) {
            return url
        }
        
        // Try the main bundle
        if let url = Bundle.main.url(forResource: modelName, withExtension: modelExtension) {
            return url
        }
        
        // Try the package's Resources directory
        let resourcesPath = currentBundle.bundlePath + "/Contents/Resources"
        let resourcesURL = URL(fileURLWithPath: resourcesPath)
        let modelURL = resourcesURL.appendingPathComponent(modelName).appendingPathExtension(modelExtension)
        if FileManager.default.fileExists(atPath: modelURL.path) {
            return modelURL
        }
        
        // Try the compiled model package
        if let url = currentBundle.url(forResource: modelName, withExtension: "mlpackage") {
            return url
        }
        
        print("Searched locations:")
        print("1. Current bundle: \(currentBundle.bundlePath)")
        print("2. Main bundle: \(Bundle.main.bundlePath)")
        print("3. Resources path: \(resourcesPath)")
        
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