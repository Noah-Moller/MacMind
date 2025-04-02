# PDF Processing Guide

MacMind provides powerful PDF processing capabilities through its `PDFExtract` class. This guide will help you understand how to effectively extract and process text from PDF documents.

## Overview

The PDF processing system provides:
- Text extraction from PDF files
- Batch processing of multiple PDFs
- Integration with LLM processing
- Support for various PDF formats

## Basic Usage

### Initialize the Extractor

```swift
import MacMind

let extractor = PDFExtract()
```

### Extract Text from a Single PDF

```swift
let pdfURL = URL(fileURLWithPath: "/path/to/document.pdf")
let text = extractor.extractAll(DocumentURLs: [pdfURL])
print("Extracted text: \(text)")
```

### Process Multiple PDFs

```swift
let pdfURLs = [
    URL(fileURLWithPath: "/path/to/doc1.pdf"),
    URL(fileURLWithPath: "/path/to/doc2.pdf")
]

let combinedText = extractor.extractAll(DocumentURLs: pdfURLs)
```

## Integration with LLM

### Summarize PDF Content

```swift
let model = LocalModel()
let extractor = PDFExtract()

// Extract and summarize
Task {
    do {
        let text = extractor.extractAll(DocumentURLs: [pdfURL])
        let prompt = "Summarize this document: \(text)"
        
        let summary = try await model.prompt(prompt)
        print("Summary: \(summary)")
    } catch {
        print("Error: \(error)")
    }
}
```

### Answer Questions About PDFs

```swift
func askAboutDocument(
    question: String,
    pdfURL: URL
) async throws -> String {
    let extractor = PDFExtract()
    let model = LocalModel()
    
    let text = extractor.extractAll(DocumentURLs: [pdfURL])
    let prompt = """
    Based on this document content:
    \(text)
    
    Answer this question: \(question)
    """
    
    return try await model.prompt(prompt)
}

// Usage
Task {
    do {
        let answer = try await askAboutDocument(
            question: "What are the main points?",
            pdfURL: documentURL
        )
        print("Answer: \(answer)")
    } catch {
        print("Error: \(error)")
    }
}
```

## Advanced Usage

### 1. Batch Processing with Progress

```swift
class PDFProcessor {
    private let extractor = PDFExtract()
    private let model = LocalModel()
    
    func processBatch(
        urls: [URL],
        progressHandler: (Double) -> Void
    ) async throws -> [String: String] {
        var results: [String: String] = [:]
        let total = Double(urls.count)
        
        for (index, url) in urls.enumerated() {
            let text = extractor.extractAll(DocumentURLs: [url])
            let summary = try await model.prompt("Summarize: \(text)")
            results[url.lastPathComponent] = summary
            
            let progress = Double(index + 1) / total
            progressHandler(progress)
        }
        
        return results
    }
}
```

### 2. Error Handling

```swift
enum PDFProcessingError: Error {
    case fileNotFound
    case extractionFailed
    case invalidFormat
}

func safeExtract(from url: URL) throws -> String {
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw PDFProcessingError.fileNotFound
    }
    
    let extractor = PDFExtract()
    let text = extractor.extractAll(DocumentURLs: [url])
    
    guard !text.isEmpty else {
        throw PDFProcessingError.extractionFailed
    }
    
    return text
}
```

### 3. Memory Management

```swift
func processLargeDocument(
    url: URL,
    chunkSize: Int = 1000
) async throws -> [String] {
    let text = PDFExtract().extractAll(DocumentURLs: [url])
    let words = text.split(separator: " ")
    var summaries: [String] = []
    
    // Process in chunks to manage memory
    for chunk in words.chunked(into: chunkSize) {
        let chunkText = chunk.joined(separator: " ")
        let summary = try await LocalModel().prompt(
            "Summarize this section: \(chunkText)"
        )
        summaries.append(summary)
    }
    
    return summaries
}
```

## Integration Examples

### 1. SwiftUI Integration

```swift
struct PDFProcessorView: View {
    @State private var documents: [URL] = []
    @State private var results: [String] = []
    @State private var isProcessing = false
    
    private let extractor = PDFExtract()
    private let model = LocalModel()
    
    var body: some View {
        VStack {
            List(documents, id: \.self) { url in
                Text(url.lastPathComponent)
            }
            
            Button(isProcessing ? "Processing..." : "Process PDFs") {
                processPDFs()
            }
            .disabled(isProcessing)
            
            List(results, id: \.self) { result in
                Text(result)
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleSelectedFiles(result)
        }
    }
    
    private func processPDFs() {
        guard !documents.isEmpty else { return }
        
        isProcessing = true
        Task {
            do {
                for url in documents {
                    let text = extractor.extractAll(DocumentURLs: [url])
                    let summary = try await model.prompt(
                        "Summarize this document: \(text)"
                    )
                    results.append(summary)
                }
            } catch {
                print("Processing failed: \(error)")
            }
            isProcessing = false
        }
    }
}
```

### 2. Document Processing Service

```swift
class DocumentProcessingService {
    private let extractor = PDFExtract()
    private let model = LocalModel()
    
    // Process and analyze documents
    func analyzeDocuments(
        urls: [URL]
    ) async throws -> DocumentAnalysis {
        let text = extractor.extractAll(DocumentURLs: urls)
        
        async let summary = model.prompt("Summarize: \(text)")
        async let keywords = model.prompt("Extract keywords: \(text)")
        async let topics = model.prompt("Identify main topics: \(text)")
        
        return try await DocumentAnalysis(
            summary: summary,
            keywords: keywords,
            topics: topics
        )
    }
}

struct DocumentAnalysis {
    let summary: String
    let keywords: String
    let topics: String
}
```

## Best Practices

1. **Memory Management**
   - Process large PDFs in chunks
   - Release resources when done
   - Monitor memory usage

2. **Error Handling**
   - Check file existence
   - Validate PDF format
   - Handle extraction failures
   - Implement retry logic

3. **Performance**
   - Reuse extractor instances
   - Batch process when possible
   - Consider background processing
   - Monitor system resources

## Common Issues

### 1. File Access

- Ensure proper permissions
- Check file existence
- Verify PDF format
- Handle file system errors

### 2. Memory Usage

- Monitor memory consumption
- Process large files in chunks
- Implement cleanup routines
- Use appropriate batch sizes

### 3. Text Quality

- Check text encoding
- Handle special characters
- Validate extracted content
- Consider OCR for scanned PDFs

## See Also

- [API Reference](../api/pdf-extract.md)
- [Example Projects](../examples/README.md)
- [Performance Guide](performance.md)
- [Troubleshooting](troubleshooting.md) 