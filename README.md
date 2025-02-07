# MacMind

MacMind is a Swift package designed for easy and efficient local Large Language Model (LLM) processing in macOS applications. It provides a clean and dynamic API optimized for Apple hardware, enabling developers to seamlessly integrate LLM processing into their applications.

# Explainer

https://www.youtube.com/watch?v=_bcgcJChlYE

## Features
- **Local LLM Processing**: Runs efficiently on macOS using locally hosted models.
- **Optimized for Mac Hardware**: Uses Apple’s performance-optimized frameworks for smooth execution.
- **Seamless Integration**: Works easily with Swift applications.
- **Supports PDF Extraction**: Extracts text from PDFs and includes it in model prompts.
- **Streaming Mode**: Supports real-time response streaming.

## Requirements
- macOS 13.0 or later
- Swift 5+
- [Ollama](https://ollama.ai) installed (for local model inference)
- Homebrew (if Ollama is not installed)

## Installation
### 1. Install Ollama
If you haven’t installed Ollama, you can install it using Homebrew:
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

With MacMind, you can harness the power of LLMs on macOS efficiently and seamlessly. Happy coding!
