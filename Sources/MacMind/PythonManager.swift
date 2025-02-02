//
//  PythonManager.swift
//  Mac Mind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation

/// Manages launching a Python process using the bundled interpreter and running a Python script.
class PythonManager {
    
    /// Returns the URL of the Python executable from the bundled environment, if available.
    /// Otherwise, falls back to the system Python interpreter.
    func pythonExecutableURL() -> URL {
        // Use the bundle for LocalModel as the reference bundle.
        let bundle = Bundle(for: LocalModel.self)
        if let path = bundle.path(forResource: "bundled_env/bin/python3", ofType: nil) {
            return URL(fileURLWithPath: path)
        }
        // Fallback to system Python.
        return URL(fileURLWithPath: "/usr/bin/python3")
    }
    
    /// Runs a Python script (bundled with the package) with specified arguments and returns its output.
    func runPythonScript(scriptName: String, arguments: [String] = []) -> String? {
        let bundle = Bundle(for: LocalModel.self)
        guard let scriptPath = bundle.path(forResource: scriptName, ofType: "py") else {
            print("Script \(scriptName).py not found in bundle.")
            return nil
        }
        
        let process = Process()
        process.executableURL = pythonExecutableURL()
        process.arguments = [scriptPath] + arguments
        
        // Set environment variables for the bundled Python interpreter.
        var env = ProcessInfo.processInfo.environment
        if let bundledPythonHome = bundle.path(forResource: "bundled_env", ofType: nil) {
            env["PYTHONHOME"] = bundledPythonHome
            env["DYLD_LIBRARY_PATH"] = bundledPythonHome + "/lib"
        }
        process.environment = env
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
        } catch {
            print("Error running python script: \(error)")
            return nil
        }
        
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
