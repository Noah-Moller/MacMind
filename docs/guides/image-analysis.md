# Image Analysis Guide

MacMind provides powerful image analysis capabilities through its `ImageClassifier` class. This guide will help you understand and use these features effectively.

## Overview

The image analysis system provides:
- Object detection and classification
- Color analysis
- Text extraction
- Natural language descriptions
- MobileNetV2-based classification

## Basic Usage

### Initialize the Classifier

```swift
import MacMind

let classifier = ImageClassifier()
```

### Analyze an Image

```swift
if let image = NSImage(contentsOf: imageURL) {
    Task {
        do {
            let result = try await classifier.analyzeImage(image)
            
            // Access the natural language description
            print(result.description)
            
            // Access predictions
            for prediction in result.predictions {
                print("\(prediction.label): \(Int(prediction.probability * 100))%")
            }
            
            // Access dominant colors
            print("Colors: \(result.dominantColors)")
            
            // Access extracted text
            print("Text: \(result.extractedText.joined(separator: " "))")
        } catch {
            print("Analysis failed: \(error)")
        }
    }
}
```

## Features in Detail

### 1. Object Detection

The classifier can identify multiple objects in an image:

```swift
// Example output for a photo of a cat playing with a toy
let result = try await classifier.analyzeImage(image)
for prediction in result.predictions {
    print("\(prediction.label): \(prediction.probability)")
}

// Output:
// cat: 0.95
// toy: 0.85
// carpet: 0.70
```

### 2. Color Analysis

Extract dominant colors from images:

```swift
let result = try await classifier.analyzeImage(image)
print("Dominant colors: \(result.dominantColors)")

// Example output:
// Dominant colors: ["Deep Blue", "Soft Gray", "Warm White"]
```

### 3. Text Extraction

Extract text from images:

```swift
let result = try await classifier.analyzeImage(image)
if !result.extractedText.isEmpty {
    print("Found text: \(result.extractedText.joined(separator: " "))")
}

// Example output:
// Found text: Welcome to MacMind
```

### 4. Natural Language Descriptions

Get human-readable descriptions:

```swift
let result = try await classifier.analyzeImage(image)
print(result.description)

// Example outputs:
// "A orange tabby cat playing with a red toy on a beige carpet"
// "A modern office desk with a laptop and coffee mug"
```

## Advanced Usage

### 1. Custom Classification

```swift
let options = ClassificationOptions(
    minimumConfidence: 0.8,
    maximumResults: 5
)

let result = try await classifier.analyzeImage(
    image,
    options: options
)
```

### 2. Batch Processing

```swift
let images = [image1, image2, image3]
let results = try await withThrowingTaskGroup(
    of: ImageAnalysisResult.self
) { group in
    for image in images {
        group.addTask {
            return try await classifier.analyzeImage(image)
        }
    }
    
    var results: [ImageAnalysisResult] = []
    for try await result in group {
        results.append(result)
    }
    return results
}
```

### 3. Integration with LLM

Combine image analysis with LLM processing:

```swift
let model = LocalModel()
let classifier = ImageClassifier()

// Analyze image and use results with LLM
if let image = NSImage(contentsOf: imageURL) {
    do {
        let analysis = try await classifier.analyzeImage(image)
        let prompt = """
        Describe this image in detail:
        Objects: \(analysis.predictions.map { $0.label })
        Colors: \(analysis.dominantColors)
        Text: \(analysis.extractedText)
        """
        
        let description = try await model.prompt(prompt)
        print("Enhanced description: \(description)")
    } catch {
        print("Error: \(error)")
    }
}
```

## Best Practices

### 1. Performance Optimization

```swift
// Reuse classifier instance
class ImageService {
    private let classifier = ImageClassifier()
    
    func analyzeImages(_ images: [NSImage]) async throws -> [ImageAnalysisResult] {
        // Reuse the same classifier for multiple images
    }
}
```

### 2. Error Handling

```swift
do {
    let result = try await classifier.analyzeImage(image)
} catch let error as ImageClassifierError {
    switch error {
    case .invalidImage:
        print("Image format not supported")
    case .analysisFailure:
        print("Analysis failed")
    default:
        print("Unknown error: \(error)")
    }
}
```

### 3. Memory Management

```swift
// Process large images in batches
func processBatch(
    _ images: [NSImage],
    batchSize: Int = 10
) async throws -> [ImageAnalysisResult] {
    var results: [ImageAnalysisResult] = []
    
    for batch in images.chunked(into: batchSize) {
        let batchResults = try await withThrowingTaskGroup(
            of: ImageAnalysisResult.self
        ) { group in
            // Process batch
        }
        results.append(contentsOf: batchResults)
    }
    
    return results
}
```

## Common Issues

### 1. Image Format Support

Supported formats:
- JPEG
- PNG
- HEIC
- TIFF
- RAW (some formats)

### 2. Performance Considerations

- Image size affects processing time
- Batch processing for multiple images
- Memory usage with large images
- CPU/GPU utilization

### 3. Accuracy Factors

Factors affecting accuracy:
- Image quality
- Lighting conditions
- Object clarity
- Image resolution
- Background complexity

## Integration Examples

### 1. SwiftUI Integration

```swift
struct ImageAnalysisView: View {
    @State private var image: NSImage?
    @State private var analysis: ImageAnalysisResult?
    private let classifier = ImageClassifier()
    
    var body: some View {
        VStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            if let analysis = analysis {
                Text("Description: \(analysis.description)")
                Text("Colors: \(analysis.dominantColors.joined(separator: ", "))")
            }
            
            Button("Analyze") {
                analyzeCurrentImage()
            }
        }
    }
    
    private func analyzeCurrentImage() {
        guard let image = image else { return }
        
        Task {
            do {
                analysis = try await classifier.analyzeImage(image)
            } catch {
                print("Analysis failed: \(error)")
            }
        }
    }
}
```

### 2. Drag and Drop Support

```swift
extension ImageAnalysisView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.image]).first else {
            return false
        }
        
        item.loadItem(forTypeIdentifier: UTType.image.identifier) { data, error in
            if let imageData = data as? Data,
               let image = NSImage(data: imageData) {
                DispatchQueue.main.async {
                    self.image = image
                    self.analyzeCurrentImage()
                }
            }
        }
        
        return true
    }
}
```

## See Also

- [API Reference](../api/image-classifier.md)
- [Example Projects](../examples/README.md)
- [Performance Guide](performance.md)
- [Troubleshooting](troubleshooting.md) 