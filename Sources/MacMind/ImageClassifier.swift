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
        let fileManager = FileManager.default
        
        // First, try to find the model in the app's Application Support directory
        if let appSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            let modelDirectory = appSupportURL.appendingPathComponent("MacMind/Models")
            let modelURL = modelDirectory.appendingPathComponent("\(modelName).mlpackage")
            
            // If the model doesn't exist in Application Support, try to copy it from the bundle
            if !fileManager.fileExists(atPath: modelURL.path) {
                print("Model not found in Application Support, attempting to copy from bundle...")
                
                // Try to find the model in various bundle locations
                let possibleSourceURLs = [
                    Bundle.main.url(forResource: modelName, withExtension: "mlpackage"),
                    Bundle(for: type(of: self)).url(forResource: modelName, withExtension: "mlpackage"),
                    Bundle.main.resourceURL?.appendingPathComponent("Resources/\(modelName).mlpackage"),
                    Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(modelName).mlpackage")
                ]
                
                if let sourceURL = possibleSourceURLs.first(where: { url in
                    url != nil && fileManager.fileExists(atPath: url!.path)
                }) {
                    do {
                        try fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
                        try fileManager.copyItem(at: sourceURL!, to: modelURL)
                        print("Successfully copied model to: \(modelURL.path)")
                        return modelURL
                    } catch {
                        print("Failed to copy model: \(error)")
                    }
                }
                
                // If we couldn't find the model in the bundle, try the source directory
                let sourceDirectory = Bundle.main.bundleURL
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("Sources/MacMind/Resources/\(modelName).mlpackage")
                
                if fileManager.fileExists(atPath: sourceDirectory.path) {
                    do {
                        try fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
                        try fileManager.copyItem(at: sourceDirectory, to: modelURL)
                        print("Successfully copied model from source directory to: \(modelURL.path)")
                        return modelURL
                    } catch {
                        print("Failed to copy model from source directory: \(error)")
                    }
                }
            } else {
                print("Found model in Application Support: \(modelURL.path)")
                return modelURL
            }
        }
        
        print("\nSearched locations:")
        print("1. Application Support directory")
        print("2. Main bundle: \(Bundle.main.bundlePath)")
        print("3. Code bundle: \(Bundle(for: type(of: self)).bundlePath)")
        if let resourcePath = Bundle.main.resourcePath {
            print("4. Resource path: \(resourcePath)")
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