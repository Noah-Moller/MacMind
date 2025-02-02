//
//  SetupManager.swift
//  MacMind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation

/// A public helper to check for and install prerequisites.
public class SetupManager {
    
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
    ///
    /// - Parameter completion: A closure that is called with `true` if the command succeeded,
    ///   or `false` otherwise.
    public static func pullDeepSeekModel(completion: @escaping (Bool) -> Void) {
        // First, check if the model is already installed.
        if isDeepSeekInstalled() {
            print("DeepSeek model is already installed.")
            completion(true)
            return
        }
        
        // If not, attempt to pull the model.
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
            print("Ollama executable not found.")
            completion(false)
            return
        }
        
        print("DeepSeek model not found. Pulling model using Ollama...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ollama)
        process.arguments = ["pull", "deepseek-r1:1.5b"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                process.waitUntilExit()
                let success = process.terminationStatus == 0
                if success {
                    print("DeepSeek model downloaded successfully.")
                } else {
                    print("Failed to download DeepSeek model. Termination status: \(process.terminationStatus)")
                }
                // After pull completes, check again whether the model is installed.
                let installed = isDeepSeekInstalled()
                DispatchQueue.main.async {
                    completion(installed)
                }
            } catch {
                print("Error running ollama pull command: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Runs the setup process:
    /// - If Homebrew is not installed, instructs the user to install Homebrew.
    /// - Then, if Ollama is not installed, instructs the user to install Ollama.
    /// - Finally, if the DeepSeek model is not installed, automatically pulls it.
    public static func setupOllamaIfNeeded(completion: @escaping (Bool) -> Void) {
        if !isOllamaInstalled() {
            print("Ollama is not installed. Please install Ollama (e.g., via Homebrew: brew install ollama).")
            completion(false)
        } else {
            print("Ollama is installed.")
            pullDeepSeekModel { success in
                if success {
                    print("Ollama and DeepSeek model are ready.")
                } else {
                    print("Ollama setup failed (model not downloaded).")
                }
                completion(success)
            }
        }
    }
}
