//
//  SetupManager.swift
//  MacMind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation
import SwiftUI

/// Represents the current status of the setup process
public enum SetupStatus: Equatable {
    case notStarted
    case installingHomebrew
    case installingOllama
    case installingModel
    case completed
    case failed(String)
    
    public var description: String {
        switch self {
        case .notStarted: return "Setup not started"
        case .installingHomebrew: return "Installing Homebrew..."
        case .installingOllama: return "Installing Ollama..."
        case .installingModel: return "Installing DeepSeek model..."
        case .completed: return "Setup completed successfully"
        case .failed(let error): return "Setup failed: \(error)"
        }
    }
    
    public static func == (lhs: SetupStatus, rhs: SetupStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.installingHomebrew, .installingHomebrew),
             (.installingOllama, .installingOllama),
             (.installingModel, .installingModel),
             (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// A public helper to check for and install prerequisites.
public class SetupManager: ObservableObject {
    /// Published property to track setup status
    @Published public private(set) var status: SetupStatus = .notStarted
    
    /// Singleton instance
    public static let shared = SetupManager()
    
    init() {}
    
    /// Returns true if Homebrew is installed
    private func isHomebrewInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Returns true if Ollama is found in common locations.
    public static func isOllamaInstalled() -> Bool {
        let fileManager = FileManager.default
        let possiblePaths = ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama"]
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    /// Installs Homebrew using the official script
    private func installHomebrew() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "com.macmind", code: 1, userInfo: [NSLocalizedDescriptionKey: "Homebrew installation failed"])
        }
    }
    
    /// Installs Ollama using Homebrew
    private func installOllama() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        process.arguments = ["install", "ollama"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "com.macmind", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ollama installation failed"])
        }
    }
    
    /// Checks if the DeepSeek model is already installed by listing available models.
    /// This function assumes that "ollama list" prints installed models.
    public static func isDeepSeekInstalled() -> Bool {
        // Use one of the common ollama paths.
        let fileManager = FileManager.default
        let possiblePaths = ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama"]
        var ollamaExecutable: String?
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                ollamaExecutable = path
                break
            }
        }
        
        guard let ollama = ollamaExecutable else {
            print("Ollama executable not found when checking for model.")
            return false
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollama)
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error running ollama list: \(error)")
            return false
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        // For debugging, print the output.
        print("Output from 'ollama list':\n\(output)")
        
        // Check if the output contains the model identifier.
        return output.lowercased().contains("deepseek-r1:1.5b")
    }
    
    /// Runs the command "ollama pull deepseek-r1:1.5b" to download the DeepSeek model.
    private func installDeepSeekModel() async throws {
        guard let ollama = ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama"]
            .first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw NSError(domain: "com.macmind", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ollama executable not found"])
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollama)
        process.arguments = ["pull", "deepseek-r1:1.5b"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "com.macmind", code: 4, userInfo: [NSLocalizedDescriptionKey: "Model installation failed"])
        }
    }
    
    /// Runs the complete setup process, installing all required components
    public func setup() async {
        do {
            status = .installingHomebrew
            if !isHomebrewInstalled() {
                try await installHomebrew()
            }
            
            status = .installingOllama
            if !Self.isOllamaInstalled() {
                try await installOllama()
            }
            
            status = .installingModel
            if !Self.isDeepSeekInstalled() {
                try await installDeepSeekModel()
            }
            
            status = .completed
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
}

/// A SwiftUI view that shows the setup progress
public struct SetupLoadingView: View {
    @ObservedObject private var setupManager = SetupManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(setupManager.status.description)
                .font(.headline)
            
            if case .failed(let error) = setupManager.status {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
        }
        .padding()
    }
}
