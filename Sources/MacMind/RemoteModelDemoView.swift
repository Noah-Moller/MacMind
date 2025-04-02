import SwiftUI

public struct RemoteModelDemoView: View {
    @State private var serverAddress = "localhost"
    @State private var serverPort = "3467"
    @State private var promptText = ""
    @State private var response = ""
    @State private var isStreaming = false
    @State private var isConnected = false
    @State private var isLoading = false
    
    private let model: RemoteModel
    
    public init(serverAddress: String = "localhost", serverPort: Int = 3467) {
        self.model = RemoteModel(config: RemoteModelConfig(
            host: serverAddress,
            port: serverPort
        ))
        _serverAddress = State(initialValue: serverAddress)
        _serverPort = State(initialValue: String(serverPort))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Server Configuration
            HStack {
                TextField("Server Address", text: $serverAddress)
                    .textFieldStyle(.roundedBorder)
                TextField("Port", text: $serverPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            // Connection Status
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(isConnected ? "Connected" : "Disconnected")
                    .foregroundColor(isConnected ? .green : .red)
                
                Spacer()
                
                Button("Check Connection") {
                    checkConnection()
                }
                .disabled(isLoading)
            }
            
            // Prompt Input
            VStack(alignment: .leading) {
                Text("Prompt")
                    .font(.headline)
                TextEditor(text: $promptText)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.2))
            }
            
            // Controls
            HStack {
                Toggle("Stream Response", isOn: $isStreaming)
                
                Spacer()
                
                Button("Send") {
                    sendPrompt()
                }
                .disabled(promptText.isEmpty || isLoading)
            }
            
            // Response Display
            VStack(alignment: .leading) {
                Text("Response")
                    .font(.headline)
                ScrollView {
                    Text(response)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .border(Color.gray.opacity(0.2))
            }
        }
        .padding()
        .onAppear {
            checkConnection()
        }
    }
    
    private func checkConnection() {
        isLoading = true
        Task {
            do {
                isConnected = try await model.checkHealth()
            } catch {
                isConnected = false
            }
            isLoading = false
        }
    }
    
    private func sendPrompt() {
        isLoading = true
        response = ""
        
        if isStreaming {
            model.prompt(promptText, streaming: true) { chunk in
                response += chunk
            }
        } else {
            Task {
                do {
                    response = try await model.prompt(promptText)
                } catch {
                    response = "Error: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }
} 