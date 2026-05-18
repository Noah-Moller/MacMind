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
        case .installingModel: return "Installing language model..."
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

    /// Smallest locally-runnable Gemma model. Used as a fallback when no
    /// model is already installed in Ollama. Gemma 4 currently only ships as
    /// a cloud variant (`gemma4:31b-cloud`) which is not suitable as a local
    /// fallback, so we install the smallest local Gemma family model.
    public static let fallbackModel = "gemma3:1b"

    /// The model identifier that should be used by `LocalModel`. Resolved at
    /// setup time based on what is already available in Ollama. Defaults to
    /// the fallback model so the package is usable before setup runs.
    public static private(set) var selectedModel: String = SetupManager.fallbackModel

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

    /// Locate the ollama binary, if installed.
    private static func ollamaPath() -> String? {
        let fileManager = FileManager.default
        for path in ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama"] {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        return nil
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

    /// Returns the list of model identifiers reported by `ollama list`.
    public static func installedModels() -> [String] {
        guard let ollama = ollamaPath() else { return [] }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollama)
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error running ollama list: \(error)")
            return []
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // Output format:
        // NAME                ID              SIZE    MODIFIED
        // gemma3:1b           abc123          815 MB  2 days ago
        let lines = output.split(separator: "\n").map(String.init)
        var models: [String] = []
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip header
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if let name = trimmed.split(separator: " ").first {
                models.append(String(name))
            }
        }
        return models
    }

    /// Picks the best already-installed model to use, preferring Gemma family.
    /// Returns `nil` if Ollama has no models installed.
    public static func preferredInstalledModel() -> String? {
        let models = installedModels()
        if models.isEmpty { return nil }
        if let gemma = models.first(where: { $0.lowercased().hasPrefix("gemma") }) {
            return gemma
        }
        return models.first
    }

    /// Pulls the fallback Gemma model.
    private func installFallbackModel() async throws {
        guard let ollama = Self.ollamaPath() else {
            throw NSError(domain: "com.macmind", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ollama executable not found"])
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollama)
        process.arguments = ["pull", Self.fallbackModel]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "com.macmind", code: 4, userInfo: [NSLocalizedDescriptionKey: "Model installation failed"])
        }
    }

    /// Runs the complete setup process. Resolves `selectedModel` to a
    /// pre-existing Ollama model when possible, otherwise pulls the fallback
    /// Gemma model.
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

            if let existing = Self.preferredInstalledModel() {
                Self.selectedModel = existing
            } else {
                status = .installingModel
                try await installFallbackModel()
                Self.selectedModel = Self.fallbackModel
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
