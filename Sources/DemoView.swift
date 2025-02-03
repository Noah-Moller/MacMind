//
//  DemoView.swift
//  MacMind
//
//  Created by Noah Moller on 4/2/2025.
//

import SwiftUI
import MacMind  // Import the package

struct ContentView: View {
    @State private var promptText: String = "Why is the sky blue?"
    @State private var generatedText: String = "No output yet."
    @State private var isProcessing: Bool = false
    @State private var streaming: Bool = false
    @State private var showThinking: Bool = false
    @State private var modelReady: Bool = false
    @State private var showSetupAlert: Bool = false
    
    @State var localModel: LocalModel? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MacMind Chat Demo")
                .font(.largeTitle)
                .padding(.top)
            
            if !modelReady {
                Text("Setting up DeepSeek model…")
                    .onAppear {
                        localModel = LocalModel() { success in
                            modelReady = success
                            if !success {
                                showSetupAlert = true
                            }
                        }
                    }
            } else {
                Toggle("Stream Response", isOn: $streaming)
                    .padding([.leading, .trailing])
                
                Toggle("Show Thinking", isOn: $showThinking)
                    .padding([.leading, .trailing])
                
                TextField("Enter prompt", text: $promptText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.leading, .trailing])
                
                Button(action: {
                    guard let localModel = localModel else { return }
                    isProcessing = true
                    generatedText = ""
                    localModel.prompt(promptText, streaming: streaming, showThinking: showThinking) { response in
                        generatedText = response
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
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showSetupAlert) {
            Alert(
                title: Text("Setup Failed"),
                message: Text("Ollama and the DeepSeek model could not be set up. Please install Ollama manually via Homebrew (brew install ollama) and ensure you have network access."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    ContentView()
}
