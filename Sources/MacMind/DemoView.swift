import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct DemoView: View {
    @State private var promptText: String = ""
    @State private var response: String = "No output yet."
    @State private var modelReady: Bool = false
    @State private var showSetupAlert: Bool = false
    @State private var selectedImage: NSImage?
    @State private var isProcessing: Bool = false
    @State private var showImagePicker = false
    @State private var localModel: LocalModel? = nil
    
    public init() {}
    
    public var body: some View {
        VStack {
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
               isPresented: $showSetupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to setup the model. Please ensure Ollama is installed and running.")
        }
    }
}
