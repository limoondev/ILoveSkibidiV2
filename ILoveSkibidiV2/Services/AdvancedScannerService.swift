import Foundation
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation
import Vision
import Quartz

class AdvancedScannerService: ObservableObject {
    @Published var isScanning = false
    @Published var isProcessingOCR = false
    @Published var scannedImage: NSImage? = nil
    @Published var processedImage: NSImage? = nil
    @Published var detectedText: String = ""
    @Published var detectedDocumentRegions: [CGRect] = []
    @Published var brightness: Double = 0.0
    @Published var contrast: Double = 1.0
    @Published var saturation: Double = 1.0
    @Published var sharpness: Double = 0.0
    @Published var autoEnhance: Bool = true
    @Published var autoDetectDocument: Bool = true
    @Published var enableOCR: Bool = true
    @Published var documentMode: DocumentMode = .color
    @Published var scanHistory: [AdvancedScanRecord] = []
    @Published var pageCount: Int = 1
    
    static let shared = AdvancedScannerService()
    
    private let ciContext = CIContext()
    private let ocrRequest = VNRecognizeTextRequest()
    
    enum DocumentMode: String, CaseIterable {
        case color = "Couleur"
        case grayscale = "Niveaux de gris"
        case blackWhite = "Noir et blanc"
        case auto = "Auto"
        case photo = "Photo"
        
        var icon: String {
            switch self {
            case .color: return "paintpalette.fill"
            case .grayscale: return "circle.lefthalf.filled"
            case .blackWhite: return "circle.fill"
            case .auto: return "wand.and.stars"
            case .photo: return "camera.aperture"
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case png = "PNG"
        case jpeg = "JPEG"
        case tiff = "TIFF"
        case txt = "Texte (OCR)"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .png: return "photo"
            case .jpeg: return "doc"
            case .tiff: return "doc.on.doc"
            case .txt: return "text.bubble"
            }
        }
    }
    
    struct AdvancedScanRecord: Identifiable {
        let id = UUID()
        let image: NSImage
        let date: Date
        let mode: DocumentMode
        let enhanced: Bool
        let ocrText: String?
        let pageCount: Int
    }
    
    init() {
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["fr-FR", "en-US", "de-DE", "es-ES", "it-IT"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    func openImageForScanning() -> NSImage? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .pdf]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let response = panel.runModal()
        if response == .OK, let url = panel.urls.first {
            let image = NSImage(contentsOf: url)
            if let img = image {
                scannedImage = img
                if autoDetectDocument {
                    detectDocumentBoundaries(img)
                }
                if enableOCR {
                    performOCR(on: img)
                }
            }
            return image
        }
        return nil
    }
    
    func processImage(_ image: NSImage) -> NSImage? {
        guard let ciImage = image.toCIImage() else { return image }
        
        var processed = ciImage
        
        if autoEnhance {
            processed = applyAutoEnhance(processed)
        }
        
        processed = applyBrightness(processed, value: Float(brightness))
        processed = applyContrast(processed, value: Float(contrast))
        processed = applySaturation(processed, value: Float(saturation))
        processed = applySharpness(processed, value: Float(sharpness))
        
        switch documentMode {
        case .grayscale:
            processed = applyGrayscale(processed)
        case .blackWhite:
            processed = applyBlackAndWhite(processed)
        case .auto:
            processed = applyAutoDocumentMode(processed)
        case .color, .photo:
            break
        }
        
        return processed.toNSImage(context: ciContext)
    }
    
    private func detectDocumentBoundaries(_ image: NSImage) {
        // Rectangle detection is not available on macOS Vision API
        // Set empty regions as placeholder
        detectedDocumentRegions = []
    }
    
    func performOCR(on image: NSImage) {
        isProcessingOCR = true
        detectedText = ""
        
        guard let ciImage = image.toCIImage() else {
            isProcessingOCR = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self?.isProcessingOCR = false
                }
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self?.detectedText = text
                self?.isProcessingOCR = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["fr-FR", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    private func applyAutoEnhance(_ image: CIImage) -> CIImage {
        var result = image
        
        let filters = CIFilter.filterNames(inCategory: kCICategoryColorAdjustment)
        
        if filters.contains("CIAutoEnhance") {
            let filter = CIFilter(name: "CIAutoEnhance")
            filter?.setValue(result, forKey: kCIInputImageKey)
            if let output = filter?.outputImage {
                result = output
            }
        } else {
            result = applyContrast(result, value: 1.2)
            result = applyBrightness(result, value: 0.08)
            result = applySharpness(result, value: 0.4)
            result = applyExposure(result, value: 0.1)
        }
        
        return result
    }
    
    private func applyExposure(_ image: CIImage, value: Float) -> CIImage {
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = value
        return filter.outputImage ?? image
    }
    
    private func applyAutoDocumentMode(_ image: CIImage) -> CIImage {
        var result = image
        result = applyGrayscale(result)
        result = applyContrast(result, value: 1.5)
        result = applyBrightness(result, value: 0.15)
        result = applySharpness(result, value: 0.5)
        return result
    }
    
    private func applyBrightness(_ image: CIImage, value: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = value
        return filter.outputImage ?? image
    }
    
    private func applyContrast(_ image: CIImage, value: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = value
        return filter.outputImage ?? image
    }
    
    private func applySaturation(_ image: CIImage, value: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = value
        return filter.outputImage ?? image
    }
    
    private func applySharpness(_ image: CIImage, value: Float) -> CIImage {
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = image
        filter.sharpness = value
        return filter.outputImage ?? image
    }
    
    private func applyGrayscale(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 0
        return filter.outputImage ?? image
    }
    
    private func applyBlackAndWhite(_ image: CIImage) -> CIImage {
        let gray = applyGrayscale(image)
        let filter = CIFilter.colorControls()
        filter.inputImage = gray
        filter.contrast = 2.0
        filter.brightness = 0.15
        return filter.outputImage ?? gray
    }
    
    func resetAdjustments() {
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        sharpness = 0.0
        documentMode = .auto
    }
    
    func saveScannedImage(_ image: NSImage) {
        let record = AdvancedScanRecord(
            image: image,
            date: Date(),
            mode: documentMode,
            enhanced: autoEnhance,
            ocrText: detectedText.isEmpty ? nil : detectedText,
            pageCount: pageCount
        )
        scanHistory.insert(record, at: 0)
    }
    
    func exportImage(_ image: NSImage, format: ExportFormat = .pdf) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970))"
        
        switch format {
        case .pdf:
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970)).pdf"
        case .png:
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970)).png"
        case .jpeg:
            panel.allowedContentTypes = [.jpeg]
            panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970)).jpg"
        case .tiff:
            panel.allowedContentTypes = [.tiff]
            panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970)).tiff"
        case .txt:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "OCR_\(Int(Date().timeIntervalSince1970)).txt"
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            switch format {
            case .txt:
                if !detectedText.isEmpty {
                    try? detectedText.write(to: url, atomically: true, encoding: .utf8)
                }
            default:
                if let tiffData = image.tiffRepresentation {
                    let bitmap = NSBitmapImageRep(data: tiffData)
                    let fileExtension = url.pathExtension.lowercased()
                    
                    if fileExtension == "pdf" {
                        createPDF(from: image, to: url)
                    } else if let data = bitmap?.representation(using: fileExtension == "jpg" ? .jpeg : .png, properties: fileExtension == "jpg" ? [.compressionFactor: 0.9] : [:]) {
                        try? data.write(to: url)
                    }
                }
            }
        }
    }
    
    private func createPDF(from image: NSImage, to url: URL) {
        let pdfData = NSMutableData()
        
        guard let pdfPage = PDFPage(image: image) else { return }
        
        if let consumer = CGDataConsumer(data: pdfData as CFMutableData),
           let context = CGContext(consumer: consumer, mediaBox: nil, nil) {
            let mediaBox = pdfPage.bounds(for: .cropBox)
            context.beginPDFPage(mediaBox as CFDictionary)
            context.endPDFPage()
        }
        
        try? pdfData.write(to: url)
    }
    
    private func saveAsPDF(_ image: NSImage, to url: URL) {
        let pdfData = NSMutableData()
        
        guard let pdfPage = PDFPage(image: image) else { return }
        let pdfDocument = PDFDocument()
        pdfDocument.insert(pdfPage, at: 0)
        
        if let data = pdfDocument.dataRepresentation() {
            try? data.write(to: url)
        }
    }
    
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(image.tiffRepresentation, forType: .tiff)
    }
    
    func batchProcessImages(_ images: [NSImage]) -> [NSImage] {
        return images.map { processImage($0) ?? $0 }
    }
    
    func createMultiPagePDF(from images: [NSImage], to url: URL) {
        let pdfDocument = PDFDocument()
        
        for image in images {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
            }
        }
        
        if let data = pdfDocument.dataRepresentation() {
            try? data.write(to: url)
        }
    }
}
