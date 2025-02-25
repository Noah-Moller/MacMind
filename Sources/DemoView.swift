import MacMind

/// A demonstration view showcasing MacMind's capabilities.
/// This view allows users to:
/// - Select images for analysis
/// - Ask questions about images
/// - Interact with the LLM
/// - See real-time streaming responses
/// - Analyze web content from URLs
public struct DemoView: View {
    @State private var promptText: String = ""
    @State private var response: String = ""
    @State private var selectedImage: NSImage?
    @State private var isProcessing: Bool = false
    @State private var showImagePicker = false
    @State private var localModel: LocalModel?
    @State private var modelReady: Bool = false
    @State private var showSetupAlert: Bool = false
    @State private var webAccessEnabled: Bool = false
    @State private var isWebProcessing: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            if !modelReady {
                setupView
            } else {
                mainView
            }
        }
        .alert("Setup Error", isPresented: $showSetupAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to initialize the model. Please ensure Ollama is installed and running.")
        }
    }
    
    private var setupView: some View {
        VStack {
            .task {
                localModel = await LocalModel { success in
                    modelReady = success
                    if !success {
                        showSetupAlert = true
                    }
                }
            }
        }
    }
    
    private var mainView: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = selectedImage {
                        imageSection(image)
                    }
                    
                    if !response.isEmpty {
                        responseSection
                    }
                }
                .padding()
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: $webAccessEnabled) {
                    Text("Enable Web Access")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
                if webAccessEnabled {
                    Text("You can include URLs in your prompt to analyze web content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                inputSection
            }
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
    }
    
    // ... existing imageSection and responseSection ...
    
    private var inputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: { showImagePicker = true }) {
                    Label("Add Image", systemImage: "photo")
                        .labelStyle(.iconOnly)
                }
                .help("Select an image to analyze")
                
                TextField(webAccessEnabled ? "Ask a question or paste a URL..." : "Ask a question or type a prompt...",
                          text: $promptText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit(sendPrompt)
                
                Button(action: sendPrompt) {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                }
                .disabled(isProcessing || (promptText.isEmpty && selectedImage == nil))
                .help("Send prompt")
            }
            
            if isWebProcessing {
                Text("Processing web content...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result,
           let url = urls.first,
           let image = NSImage(contentsOf: url) {
            selectedImage = image
            
            // Automatically analyze the image when selected
            promptText = "What's in this image?"
            sendPrompt()
        }
    }
    
    private func sendPrompt() {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Check if the prompt contains URLs when web access is enabled
        if webAccessEnabled && promptText.range(of: "https?://[^\\s]+", options: .regularExpression) != nil {
            isWebProcessing = true
        }
        
        Task {
            await localModel?.prompt(
                promptText,
                images: selectedImage.map { [$0] },
                streaming: true,
                webAccess: webAccessEnabled
            ) { result in
                response = result
                isProcessing = false
                isWebProcessing = false
            }
            promptText = ""
        }
    }
}
