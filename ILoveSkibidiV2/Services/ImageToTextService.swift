import Foundation
import AppKit
import Vision

class ImageToTextService: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isProcessing = false
    @Published var confidence: Float = 0.0
    
    static let shared = ImageToTextService()
    
    private let ocrRequest = VNRecognizeTextRequest()
    
    init() {
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["fr-FR", "en-US", "de-DE", "es-ES", "it-IT", "zh-CN", "ja-JP"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    func extractText(from image: NSImage) {
        isProcessing = true
        extractedText = ""
        
        guard let ciImage = image.toCIImage() else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                }
                return
            }
            
            var text = ""
            var totalConfidence: Float = 0
            var count = 0
            
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    text += candidate.string + "\n"
                    totalConfidence += candidate.confidence
                    count += 1
                }
            }
            
            DispatchQueue.main.async {
                self?.extractedText = text
                self?.confidence = count > 0 ? totalConfidence / Float(count) : 0
                self?.isProcessing = false
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
    
    func extractTextFromFile(at url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        extractText(from: image)
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(extractedText, forType: .string)
    }
    
    func saveToFile(to url: URL) {
        try? extractedText.write(to: url, atomically: true, encoding: .utf8)
    }
}
