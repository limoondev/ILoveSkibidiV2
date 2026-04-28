import Foundation
import AppKit
import Quartz

class PDFMergerService: ObservableObject {
    @Published var pdfFiles: [URL] = []
    @Published var isProcessing = false
    
    static let shared = PDFMergerService()
    
    func selectPDFs() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        
        let response = panel.runModal()
        if response == .OK {
            pdfFiles = panel.urls
        }
    }
    
    func mergePDFs(to destinationURL: URL) -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        guard !pdfFiles.isEmpty else { return false }
        
        let mergedDocument = PDFDocument()
        
        for pdfURL in pdfFiles {
            if let pdfDocument = PDFDocument(url: pdfURL) {
                for pageIndex in 0..<pdfDocument.pageCount {
                    if let page = pdfDocument.page(at: pageIndex) {
                        mergedDocument.insert(page, at: mergedDocument.pageCount)
                    }
                }
            }
        }
        
        if let data = mergedDocument.dataRepresentation {
            do {
                try data.write(to: destinationURL)
                return true
            } catch {
                print("Error writing merged PDF: \(error)")
                return false
            }
        }
        
        return false
    }
    
    func reorderPDFs(from source: IndexSet, to destination: Int) {
        pdfFiles.move(fromOffsets: source, toOffset: destination)
    }
    
    func removePDF(at offsets: IndexSet) {
        pdfFiles.remove(atOffsets: offsets)
    }
    
    func clearPDFs() {
        pdfFiles.removeAll()
    }
}
