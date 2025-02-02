//
//  SetupManager.swift
//  MacMind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation

/// Provides setup-related utilities for the application.
public class SetupManager {
    /// Checks if the Ollama executable is installed on the system.
    ///
    /// This method searches common installation paths for the Ollama binary.
    ///
    /// - Returns: `true` if Ollama is found at any of the expected locations, otherwise `false`.
    public static func isOllamaInstalled() -> Bool {
        let fileManager = FileManager.default
        // List of common install locations for Ollama.
        let possiblePaths = ["/usr/local/bin/ollama", "/opt/homebrew/bin/ollama"]
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
}
