import Foundation

class RequestLogger {
    private let fileURL: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.macmind.requestlogger")
    
    init() {
        // Get the documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsPath.appendingPathComponent("macmind_requests.log")
        
        // Setup date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Create the file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
    }
    
    func logRequest(prompt: String, ip: String, timestamp: Date = Date()) {
        let dateString = dateFormatter.string(from: timestamp)
        let logEntry = """
            [\(dateString)]
            IP: \(ip)
            Prompt: \(prompt)
            ----------------------------------------
            
            """
        
        queue.async {
            if let data = logEntry.data(using: .utf8) {
                if let handle = try? FileHandle(forWritingTo: self.fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            }
        }
    }
    
    func getLogContents() -> String {
        if let data = try? Data(contentsOf: fileURL),
           let contents = String(data: data, encoding: .utf8) {
            return contents
        }
        return "No logs available"
    }
} 