import Foundation
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation

class ScannerService: ObservableObject {
    @Published var isScanning = false
    @Published var scannedImage: NSImage? = nil
    @Published var processedImage: NSImage? = nil
    @Published var brightness: Double = 0.0
    @Published var contrast: Double = 1.0
    @Published var saturation: Double = 1.0
    @Published var sharpness: Double = 0.0
    @Published var autoEnhance: Bool = true
    @Published var documentMode: DocumentMode = .color
    @Published var scanHistory: [ScanRecord] = []
    
    static let shared = ScannerService()
    
    private let ciContext = CIContext()
    
    enum DocumentMode: String, CaseIterable {
        case color = "Couleur"
        case grayscale = "Niveaux de gris"
        case blackWhite = "Noir et blanc"
        
        var icon: String {
            switch self {
            case .color: return "paintpalette.fill"
            case .grayscale: return "circle.lefthalf.filled"
            case .blackWhite: return "circle.fill"
            }
        }
    }
    
    struct ScanRecord: Identifiable {
        let id = UUID()
        let image: NSImage
        let date: Date
        let mode: DocumentMode
        let enhanced: Bool
    }
    
    func captureFromCamera() -> NSImage? {
        // On macOS, open system camera app via Photo Booth or Continuity Camera
        // This is the most reliable approach for macOS
        if let url = URL(string: "photobooth://") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.osx.photo-booth") {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
    
    func openImageForScanning() -> NSImage? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .pdf]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let response = panel.runModal()
        if response == .OK, let url = panel.urls.first {
            return NSImage(contentsOf: url)
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
        case .color:
            break
        }
        
        return processed.toNSImage(context: ciContext)
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
            // Manual auto-enhance
            result = applyContrast(result, value: 1.15)
            result = applyBrightness(result, value: 0.05)
            result = applySharpness(result, value: 0.3)
        }
        
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
        filter.contrast = 1.8
        filter.brightness = 0.1
        return filter.outputImage ?? gray
    }
    
    func resetAdjustments() {
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        sharpness = 0.0
        documentMode = .color
    }
    
    func saveScannedImage(_ image: NSImage) {
        let record = ScanRecord(
            image: image,
            date: Date(),
            mode: documentMode,
            enhanced: autoEnhance
        )
        scanHistory.insert(record, at: 0)
    }
    
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    func exportImage(_ image: NSImage) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .pdf]
        panel.nameFieldStringValue = "Scan_\(Int(Date().timeIntervalSince1970))"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let tiffData = image.tiffRepresentation {
                let bitmap = NSBitmapImageRep(data: tiffData)
                switch url.pathExtension {
                case "png":
                    if let data = bitmap?.representation(using: .png, properties: [:]) {
                        try? data.write(to: url)
                    }
                case "jpg", "jpeg":
                    if let data = bitmap?.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
                        try? data.write(to: url)
                    }
                case "tiff":
                    if let data = bitmap?.representation(using: .tiff, properties: [:]) {
                        try? data.write(to: url)
                    }
                default:
                    if let data = bitmap?.representation(using: .png, properties: [:]) {
                        try? data.write(to: url)
                    }
                }
            }
        }
    }
}

extension NSImage {
    func toCIImage() -> CIImage? {
        guard let tiffData = self.tiffRepresentation else { return nil }
        return CIImage(data: tiffData)
    }
}

extension CIImage {
    func toNSImage(context: CIContext) -> NSImage? {
        guard let cgImage = context.createCGImage(self, from: self.extent) else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: self.extent.width, height: self.extent.height))
        return nsImage
    }
}
