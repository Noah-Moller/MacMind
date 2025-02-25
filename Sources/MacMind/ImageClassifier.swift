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

public struct ImageAnalysisResult: Codable {
    public let description: String
    public let predictions: [ImagePrediction]
    public let dominantColors: [String]
    public let extractedText: [String]
}

public class ImageClassifier {
    private var model: VNCoreMLModel?
    
    public init() {
        do {
            let modelURL = findModelURL()
            guard let url = modelURL else {
                print("Failed to find the model file. Searched in bundle and file system.")
                return
            }
            
            print("Found model at: \(url.path)")
            
            // Create and compile the model
            print("Compiling model...")
            let compiledModelURL = try MLModel.compileModel(at: url)
            let model = try MLModel(contentsOf: compiledModelURL)
            self.model = try VNCoreMLModel(for: model)
            
        } catch {
            print("Failed to create the model: \(error)")
        }
    }
    
    private func findModelURL() -> URL? {
        let modelName = "MobileNetV2"
        let fileManager = FileManager.default
        
        // First, try to find the model in the bundle
        let codeBundle = Bundle(for: ImageClassifier.self)
        print("Looking for model in bundle: \(codeBundle.bundlePath)")
        
        // Try the package's Models directory first
        if let modelURL = codeBundle.url(forResource: modelName, withExtension: "mlmodel") {
            print("Found model in bundle resources")
            return modelURL
        }
        
        // If not found in bundle, try the Application Support directory
        if let appSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            let modelDirectory = appSupportURL.appendingPathComponent("MacMind/Models")
            let modelURL = modelDirectory.appendingPathComponent("\(modelName).mlmodel")
            
            // If the model doesn't exist in Application Support, try to copy it
            if !fileManager.fileExists(atPath: modelURL.path) {
                print("Model not found in Application Support, attempting to copy...")
                
                // Try to find the model in the package directory
                let packageRoot = Bundle.main.bundleURL
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                
                let possibleLocations = [
                    packageRoot.appendingPathComponent("Models/\(modelName).mlmodel"),
                    packageRoot.appendingPathComponent("MacMind/Models/\(modelName).mlmodel"),
                    Bundle.main.resourceURL?.appendingPathComponent("Models/\(modelName).mlmodel")
                ]
                
                print("\nSearching in possible locations:")
                for location in possibleLocations {
                    print("Checking: \(location?.path)")
                    if let location = location, fileManager.fileExists(atPath: location.path) {
                        do {
                            try fileManager.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
                            try fileManager.copyItem(at: location, to: modelURL)
                            print("Successfully copied model to: \(modelURL.path)")
                            return modelURL
                        } catch {
                            print("Failed to copy model: \(error)")
                        }
                    }
                }
            } else {
                print("Found model in Application Support: \(modelURL.path)")
                return modelURL
            }
        }
        
        return nil
    }
    
    public func analyzeImage(_ image: NSImage) async throws -> ImageAnalysisResult {
        guard let model = model else {
            throw NSError(domain: "ImageClassifier", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "ImageClassifier", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"])
        }
        
        // Perform text recognition first
        let extractedText = try await performTextRecognition(cgImage)
        
        // Perform image classification
        let classificationRequest = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([classificationRequest])
        
        guard let results = classificationRequest.results as? [VNClassificationObservation] else {
            throw NSError(domain: "ImageClassifier", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to process results"])
        }
        
        // Get top 5 classifications
        let predictions = results.prefix(5).map { observation in
            ImagePrediction(label: formatLabel(observation.identifier), probability: Double(observation.confidence))
        }
        
        // Analyze dominant colors
        let dominantColors = analyzeDominantColors(in: cgImage)
        
        // Generate description
        let description = generateDescription(predictions: predictions, dominantColors: dominantColors, extractedText: extractedText)
        
        return ImageAnalysisResult(
            description: description,
            predictions: Array(predictions),
            dominantColors: dominantColors,
            extractedText: extractedText
        )
    }
    
    private func performTextRecognition(_ image: CGImage) async throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }
        
        return observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }
    
    private func analyzeDominantColors(in image: CGImage) -> [String] {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let sampleCount = 100
        let xStep = width / sampleCount
        let yStep = height / sampleCount
        
        var colorCounts: [String: Int] = [:]
        
        for y in stride(from: 0, to: height, by: yStep) {
            for x in stride(from: 0, to: width, by: xStep) {
                let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                
                let r = CGFloat(rawData[pixelIndex]) / 255.0
                let g = CGFloat(rawData[pixelIndex + 1]) / 255.0
                let b = CGFloat(rawData[pixelIndex + 2]) / 255.0
                
                let colorName = identifyColor(r: r, g: g, b: b)
                colorCounts[colorName, default: 0] += 1
            }
        }
        
        return Array(colorCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key })
    }
    
    private func identifyColor(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        if abs(r - g) < 0.1 && abs(g - b) < 0.1 && abs(r - b) < 0.1 {
            if r < 0.2 { return "black" }
            if r < 0.5 { return "gray" }
            if r < 0.9 { return "silver" }
            return "white"
        }
        
        if r > 0.6 && g < 0.4 && b < 0.4 { return "red" }
        if r < 0.4 && g > 0.6 && b < 0.4 { return "green" }
        if r < 0.4 && g < 0.4 && b > 0.6 { return "blue" }
        if r > 0.6 && g > 0.6 && b < 0.3 { return "yellow" }
        if r > 0.6 && g < 0.4 && b > 0.6 { return "purple" }
        if r < 0.4 && g > 0.6 && b > 0.6 { return "cyan" }
        if r > 0.6 && g > 0.3 && g < 0.6 && b < 0.3 { return "orange" }
        if r > 0.6 && g < 0.3 && b > 0.3 && b < 0.6 { return "pink" }
        
        let maxChannel = max(r, g, b)
        if maxChannel == r { return "red" }
        if maxChannel == g { return "green" }
        return "blue"
    }
    
    private func formatLabel(_ label: String) -> String {
        let cleanedLabel = label.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ",", with: "")
        
        let words = cleanedLabel.split(separator: " ")
        return words.map { $0.lowercased() }.joined(separator: " ")
    }
    
    private func generateDescription(predictions: [ImagePrediction], dominantColors: [String], extractedText: [String]) -> String {
        guard let topPrediction = predictions.first else {
            return "Could not identify any objects in this image."
        }
        
        // Consolidate similar classifications
        let consolidated = consolidateSimilarClassifications(predictions)
        let subject = getSubject(from: consolidated.label)
        
        // Build the description
        var description = ""
        
        // Handle text-heavy images differently
        if isTextHeavyImage(extractedText) {
            if extractedText.count == 1 {
                return "This image contains text that reads: \"\(extractedText[0])\""
            } else {
                return "This image contains multiple text elements including: \"\(extractedText[0])\""
            }
        }
        
        // Add color information if available
        let colorInfo = !dominantColors.isEmpty ? dominantColors[0] : ""
        
        if !colorInfo.isEmpty {
            description = "This appears to be a \(colorInfo) \(subject)"
        } else {
            description = "This appears to be a \(subject)"
        }
        
        // Add additional details based on the type of object
        if isVehicle(subject) {
            description += " with \(getVehicleDetails(predictions))"
        } else if isAnimal(subject) {
            description += " that is clearly visible"
        } else if isFlower(subject) {
            description += " showing its natural beauty"
        }
        
        // Add text information if available
        if !extractedText.isEmpty {
            description += " with text that reads: \"\(extractedText[0])\""
        }
        
        return description + "."
    }
    
    // Helper functions for classification
    private func isVehicle(_ label: String) -> Bool {
        let vehicleKeywords = ["car", "truck", "bus", "motorcycle", "bicycle", "train", "boat", "airplane"]
        return vehicleKeywords.contains { label.contains($0) }
    }
    
    private func isAnimal(_ label: String) -> Bool {
        let animalKeywords = ["cat", "dog", "bird", "horse", "cow", "sheep", "lion", "tiger"]
        return animalKeywords.contains { label.contains($0) }
    }
    
    private func isFlower(_ label: String) -> Bool {
        let flowerKeywords = ["flower", "daisy", "rose", "tulip", "sunflower"]
        return flowerKeywords.contains { label.contains($0) }
    }
    
    private func isTextHeavyImage(_ text: [String]) -> Bool {
        return text.count > 5 || text.contains { $0.count > 50 }
    }
    
    private func consolidateSimilarClassifications(_ predictions: [ImagePrediction]) -> ImagePrediction {
        let firstPred = predictions[0]
        let label = firstPred.label.lowercased()
        
        // Check for similar classifications
        if predictions.count > 1 {
            if predictions.filter({ isCatBreed($0.label) }).count > 1 {
                return ImagePrediction(label: "cat", probability: firstPred.probability)
            }
            if predictions.filter({ isDogBreed($0.label) }).count > 1 {
                return ImagePrediction(label: "dog", probability: firstPred.probability)
            }
            if predictions.filter({ isVehicle($0.label) }).count > 1 {
                return ImagePrediction(label: "vehicle", probability: firstPred.probability)
            }
        }
        
        return firstPred
    }
    
    private func isCatBreed(_ label: String) -> Bool {
        let catBreeds = ["cat", "tiger cat", "tabby", "persian cat", "siamese"]
        return catBreeds.contains { label.contains($0) }
    }
    
    private func isDogBreed(_ label: String) -> Bool {
        let dogBreeds = ["dog", "puppy", "retriever", "poodle", "terrier", "husky"]
        return dogBreeds.contains { label.contains($0) }
    }
    
    private func getVehicleDetails(_ predictions: [ImagePrediction]) -> String {
        for prediction in predictions {
            let label = prediction.label.lowercased()
            if label.contains("convertible") { return "a convertible top" }
            if label.contains("sedan") { return "a sedan body style" }
            if label.contains("suv") { return "an SUV body style" }
        }
        return "a standard body style"
    }
    
    private func getSubject(from label: String) -> String {
        let label = label.lowercased()
        
        // Check for common categories
        if label.contains("cat") { return "cat" }
        if label.contains("dog") { return "dog" }
        if label.contains("car") || label.contains("vehicle") { return "vehicle" }
        if label.contains("flower") { return "flower" }
        if label.contains("bird") { return "bird" }
        
        return label
    }
} 
