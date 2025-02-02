# MacMind

MacMind is a Swift package designed for easy and efficient local Large Language Model (LLM) processing in macOS applications. It provides a clean and dynamic API optimized for Apple hardware, enabling developers to seamlessly integrate LLM processing into their applications.

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

### 2. Integrate MacMind in Xcode
Add MacMind as a dependency in your Xcode project:
```swift
.package(url: "https://github.com/yourrepo/MacMind.git", from: "1.0.0")
```

Import the module where needed:
```swift
import MacMind
```

## Usage

### Checking for Ollama Installation
Before running the model, ensure Ollama is installed:
```swift
if SetupManager.isOllamaInstalled() {
    print("Ollama is installed.")
} else {
    print("Please install Ollama.")
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
import MacMind  // Import the package

struct ContentView: View {
    @State private var showAlert: Bool = false
    @State private var promptText: String = "Why is the sky blue?"
    @State private var generatedText: String = "No output yet."
    @State private var isProcessing: Bool = false
    @State private var streaming: Bool = false
    @State private var showThinking: Bool = true
    
    // Create an instance of LocalModel.
    // Use an initializer that accepts a completion for setup (optional).
    @State var localModel: LocalModel = LocalModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MacMind Chat Demo")
                .font(.largeTitle)
                .padding(.top)
            
            Toggle("Stream Response", isOn: $streaming)
                .padding([.leading, .trailing])
            
            Toggle("Show Thinking", isOn: $showThinking)
                .padding([.leading, .trailing])
            
            TextField("Enter prompt", text: $promptText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
            
            Button(action: {
                isProcessing = true
                generatedText = ""
                localModel.prompt(promptText, streaming: streaming, showThinking: showThinking) { response in
                    generatedText += response
                    // For streaming, you might want to update isProcessing when finished.
                    isProcessing = false
                }
            }) {
                Text(isProcessing ? "Processing..." : "Prompt AI")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isProcessing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding([.leading, .trailing])
            
            ScrollView {
                Text(generatedText)
                    .padding()
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .onAppear {
            if !SetupManager.isOllamaInstalled() {
                showAlert = true
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Ollama Not Installed"),
                message: Text("""
                            This app requires Ollama to be installed.
                            
                            Please install Homebrew from https://brew.sh and then run:
                            brew install ollama
                            """),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    ContentView()
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
