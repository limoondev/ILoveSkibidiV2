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
        
        guard let writeContext = CGContext(destinationURL as CFURL, mediaBox: nil, nil) else {
            return false
        }
        
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        writeContext.beginPDF(mediaBox: &mediaBox)
        
        for pdfURL in pdfFiles {
            if let pdfDocument = PDFDocument(url: pdfURL) {
                for pageIndex in 0..<pdfDocument.pageCount {
                    if let page = pdfDocument.page(at: pageIndex) {
                        let pageBounds = page.bounds(for: .cropBox)
                        
                        writeContext.beginPDFPage(&pageBounds)
                        
                        if let cgImage = generateCGImage(from: page) {
                            writeContext.draw(cgImage, in: pageBounds)
                        }
                        
                        writeContext.endPDFPage()
                    }
                }
            }
        }
        
        writeContext.closePDF()
        return true
    }
    
    private func generateCGImage(from page: PDFPage) -> CGImage? {
        let bounds = page.bounds(for: .cropBox)
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        page.draw(with: .cropBox, to: .zero)
        image.unlockFocus()
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
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
