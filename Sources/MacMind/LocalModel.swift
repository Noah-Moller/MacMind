//
//  LocalModel.swift
//  Mac Mind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation

/// Public API for prompting the local DeepSeek R1 model.
public class LocalModel {
    private let pythonManager = PythonManager()
    
    public init() {
        _ = pythonManager.runPythonScript(scriptName: "ai_worker", arguments: ["download"])
    }
    
    /// Executes a prompt against the local model and returns the generated text.
    public func prompt(_ promptText: String) -> String? {
        return pythonManager.runPythonScript(scriptName: "ai_worker", arguments: ["mlx", promptText])
    }
}
