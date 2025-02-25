# MacMind

MacMind is a Swift package designed for easy and efficient local Large Language Model (LLM) processing and advanced image analysis in macOS applications. It provides a clean and dynamic API optimized for Apple hardware, enabling developers to seamlessly integrate LLM processing and intelligent image analysis into their applications.

# Explainer

https://www.youtube.com/watch?v=_bcgcJChlYE

## Features
- **Local LLM Processing**: Runs efficiently on macOS using locally hosted models.
- **Advanced Image Analysis**: 
  - Object detection and classification using MobileNetV2
  - Intelligent classification consolidation (e.g., recognizing different cat breeds as "cat")
  - Color analysis and detection
  - Text extraction from images
  - Natural language description generation
- **Optimized for Mac Hardware**: Uses Apple's performance-optimized frameworks for smooth execution.
- **Seamless Integration**: Works easily with Swift applications.
- **Supports PDF Extraction**: Extracts text from PDFs and includes it in model prompts.
- **Streaming Mode**: Supports real-time response streaming.
- **HTTP Server Mode**: Run as a server to provide API access from any machine on your network.

## Requirements
- macOS 13.0 or later
- Swift 5+
- [Ollama](https://ollama.ai) installed (for local model inference)
- Homebrew (if Ollama is not installed)

## Installation
### 1. Install Ollama
If you haven't installed Ollama, you can install it using Homebrew:
```sh
brew install ollama
```
Or download it at: https://ollama.com/download/Ollama-darwin.zip

### 2. Integrate MacMind in Xcode
Add MacMind as a dependency in your Xcode project:
```swift
.package(url: "https://github.com/yourrepo/MacMind.git", from: "1.0.0")
```
Also ensure you remove the app sandbox capability on the targets signing and capabilities section.

Import the module where needed:
```swift
import MacMind
```

## Usage

### Image Analysis
```swift
import MacMind

// Create an image classifier
let classifier = ImageClassifier()

// Analyze an image
if let image = NSImage(contentsOf: imageURL) {
    do {
        let result = try await classifier.analyzeImage(image)
        
        // Access the natural language description
        print(result.description)
        
        // Access individual predictions
        for prediction in result.predictions {
            print("\(prediction.label): \(Int(prediction.probability * 100))%")
        }
        
        // Access dominant colors
        print("Dominant colors: \(result.dominantColors.joined(separator: ", "))")
        
        // Access extracted text
        if !result.extractedText.isEmpty {
            print("Extracted text: \(result.extractedText.joined(separator: " "))")
        }
    } catch {
        print("Analysis failed: \(error)")
    }
}
```

Example outputs:
```
// For a cat image:
"This appears to be an orange cat that is clearly visible."

// For a car image:
"This appears to be a blue vehicle with a sedan body style."

// For a flower:
"This image shows a red rose showing its natural beauty."

// For an image with text:
"This image contains text that reads: 'Welcome to MacMind'"
```

### LLM Processing
Check out the [SampleView](https://github.com/Noah-Moller/MacMind/blob/main/Sources/DemoView.swift)

### Checking for Ollama Installation
Before running the model, ensure Ollama is installed:
```swift
if SetupManager.isOllamaInstalled() {
    print("Ollama is installed.")
} else {
    print("Please install Ollama.")
}
```

### Model Setup
Before we can prompt the model, we need to check if it's installed. If the model is not installed, then it will be automatically downloaded through Ollama. We can do this with the below code:
```swift
 if !modelReady {
    Text("Setting up model…")
        .onAppear {
            localModel = LocalModel() { success in
                modelReady = success
            if !success {
                showSetupAlert = true
                        }
                    }
                }
    } else {
    //Your main view
    }
```

### Running a Local Model
```swift
let model = LocalModel()
model.prompt("What is quantum computing?", streaming: false) { response in
    print("Response: \(response)")
}
```

### Extracting Text from PDFs
```swift
let pdfExtractor = PDFExtract()
let extractedText = pdfExtractor.extractAll(DocumentURLs: [URL(fileURLWithPath: "example.pdf")])
print(extractedText)
```

### Running as a Server
MacMind can be run as a server, allowing you to access the LLM capabilities from any machine on your network:

```bash
# Run with default settings (0.0.0.0:3467)
swift run macmind-server

# Run with custom host and port
swift run macmind-server --host 127.0.0.1 --port 8080
```

#### Server Endpoints

1. Health Check:
```bash
curl http://localhost:3467/health
```

2. Status Check:
```bash
curl http://localhost:3467/status
```

3. Send a Prompt (non-streaming):
```bash
curl -X POST http://localhost:3467/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is quantum computing?",
    "stream": false,
    "showThinking": true
  }'
```

4. Send a Prompt (streaming):
```bash
curl -X POST http://localhost:3467/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is quantum computing?",
    "stream": true,
    "showThinking": true
  }'
```

5. Send a Prompt with PDF Context:
```bash
curl -X POST http://localhost:3467/prompt \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Summarize this document",
    "stream": false,
    "showThinking": true,
    "pdfURLs": ["file:///path/to/your/document.pdf"]
  }'
```

To access the server from other machines, replace `localhost` with your Mac's IP address.

### Demo View
MacMind can be integrated into a SwiftUI app with a simple UI:
```swift
import SwiftUI
import MacMind

struct ContentView: View {
    @State private var promptText: String = "Why is the sky blue?"
    @State private var response: String = "No output yet."
    @State private var model = LocalModel()
    
    var body: some View {
        VStack {
            TextField("Enter prompt", text: $promptText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Run Model") {
                model.prompt(promptText) { output in
                    response = output
                }
            }
            Text(response)
                .padding()
        }
    }
}
```

## Model Used
MacMind leverages the **DeepSeek R1 (1.5B parameters)** model through the Ollama API. While the model is compact, it still provides useful and efficient results for local LLM processing.

## License
MacMind is released under the MIT License.

## Contributing
Contributions are welcome! Feel free to submit issues and pull requests.

---

With MacMind, you can harness the power of LLMs and advanced image analysis on macOS efficiently and seamlessly. Happy coding!
