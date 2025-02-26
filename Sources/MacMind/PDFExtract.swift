//
//  PDFExtract.swift
//  MacMind
//
//  Created by Noah Moller on 2/2/2025.
//

import Foundation
import PDFKit

/// A helper class to extract text content from PDF documents.
public class PDFExtract {
    /// Extracts and concatenates text content from multiple PDF documents.
    ///
    /// - Parameter DocumentURLs: An array of `URL` objects pointing to PDF files.
    /// - Returns: A single string containing the text from all PDFs, with simple headers separating each document.
    public func extractAll(Documents: [PDFDocument]) -> String {
        var content: String = ""
        var index: Int = 1
        content += "Uploaded Pdfs:\n\n"
        // Iterate through each provided URL, extract its content, and append it.
        for Document in Documents {
            content += "PDF \(index):\n"
            content += extract(Document: Document)
            content += "\n\n"
            index += 1
        }
        print(content)
        return content
    }
    
    /// Extracts text content from a single PDF document.
    ///
    /// - Parameter DocumentURL: The URL of the PDF file.
    /// - Returns: The extracted text content as a `String`. If the document cannot be opened, an empty string is returned.
    private func extract(Document: PDFDocument) -> String {
         let pdf = Document
            let pageCount = pdf.pageCount
            let documentContent = NSMutableAttributedString()
            
            // Iterate over each page of the PDF to extract text.
            for i in 0 ..< pageCount {
                guard let page = pdf.page(at: i) else { continue }
                guard let pageContent = page.attributedString else { continue }
                documentContent.append(pageContent)
            }
            return documentContent.string
    }
}
