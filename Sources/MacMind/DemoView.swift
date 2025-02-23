import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct DemoView: View {
    @StateObject private var setupManager = SetupManager.shared
    @State private var promptText: String = ""
    @State private var response: String = "No output yet."
    @State private var selectedImage: NSImage?
    @State private var isProcessing: Bool = false
    @State private var showImagePicker = false
    @State private var localModel: LocalModel?
    
    public init() {}
    
    private var isSetupComplete: Bool {
        setupManager.status == .completed
    }
    
    public var body: some View {
        VStack {
            if !isSetupComplete {
                SetupLoadingView()
                    .task {
                        await setupManager.setup()
                        if isSetupComplete {
                            localModel = await LocalModel()
                        }
                    }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if let selectedImage {
                            Image(nsImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        }
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Label("Select Image", systemImage: "photo")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .fileImporter(
                            isPresented: $showImagePicker,
                            allowedContentTypes: [.image],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first,
                                   let image = NSImage(contentsOf: url) {
                                    selectedImage = image
                                }
                            case .failure(let error):
                                print("Error selecting image: \(error.localizedDescription)")
                            }
                        }
                        
                        TextField("Enter your prompt...", text: $promptText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button(action: {
                            Task {
                                guard let model = localModel else { return }
                                isProcessing = true
                                if let image = selectedImage {
                                    await model.promptWithImage(promptText, image: image) { result in
                                        response = result
                                        isProcessing = false
                                    }
                                } else {
                                    model.prompt(promptText) { result in
                                        response = result
                                        isProcessing = false
                                    }
                                }
                            }
                        }) {
                            Text("Run Model")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(promptText.isEmpty || isProcessing)
                        
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                        }
                        
                        Text(response)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
        }
        .alert("Setup Failed",
               isPresented: .init(
                get: { setupManager.status.isFailed },
                set: { _ in }
               )) {
            Button("Retry", action: {
                Task {
                    await setupManager.setup()
                }
            })
            Button("Cancel", role: .cancel) { }
        } message: {
            if case .failed(let error) = setupManager.status {
                Text(error)
            }
        }
    }
}

private extension SetupStatus {
    var isFailed: Bool {
        if case .failed(_) = self {
            return true
        }
        return false
    }
}
