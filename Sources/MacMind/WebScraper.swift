//
//  WebScraper.swift
//  MacMind
//
//  Created by Noah Moller on 7/2/2025.
//

import Foundation
import SwiftSoup

class WebScraper {
    static func scrapeWebsite(url: String) async throws -> String {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        ] as [AnyHashable: Any]
        
        let session = URLSession(configuration: config)
        
        guard let webURL = URL(string: url) else {
            throw NSError(domain: "WebScraper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Create and configure the request
        var request = URLRequest(url: webURL)
        request.httpMethod = "GET"
        
        // Fetch the webpage
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "WebScraper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "WebScraper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to convert data to string"])
        }
        
        // Parse HTML using SwiftSoup
        let document = try SwiftSoup.parse(htmlString)
        
        // Remove script and style elements
        try document.select("script, style").remove()
        
        // Get text content
        var text = try document.text()
        
        // Clean up the text
        text = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        return text
    }
}

