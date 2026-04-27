import Foundation
import AppKit
import InputMethodKit

class TextCorrectionService: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var autoReplace: Bool = true
    @Published var smartQuotes: Bool = true
    @Published var smartDashes: Bool = true
    @Published var autoCapitalize: Bool = true
    @Published var correctSpelling: Bool = true
    @Published var grammarCheck: Bool = true
    @Published var correctionLanguage: String = "fr"
    @Published var correctionsCount: Int = 0
    @Published var lastCorrection: String = ""
    
    private let spellChecker = NSSpellChecker.shared
    private var globalMonitor: Any?
    private var clipboardMonitor: Timer?
    
    static let shared = TextCorrectionService()
    
    struct Correction {
        let original: String
        let corrected: String
        let type: CorrectionType
        let timestamp: Date
    }
    
    enum CorrectionType: String {
        case spelling = "Orthographe"
        case grammar = "Grammaire"
        case capitalization = "Capitalisation"
        case punctuation = "Ponctuation"
        case smartQuote = "Guillemets intelligents"
        case smartDash = "Tirets intelligents"
    }
    
    @Published var correctionHistory: [Correction] = []
    
    func startGlobalCorrection() {
        setupSpellChecker()
        setupClipboardMonitoring()
    }
    
    func stopGlobalCorrection() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        clipboardMonitor?.invalidate()
        clipboardMonitor = nil
    }
    
    private func setupSpellChecker() {
        spellChecker.setLanguage(correctionLanguage)
    }
    
    private func setupClipboardMonitoring() {
        clipboardMonitor = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard isEnabled, autoReplace else { return }
        
        let pasteboard = NSPasteboard.general
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }
        
        let corrected = correctText(content)
        if corrected != content {
            pasteboard.clearContents()
            pasteboard.setString(corrected, forType: .string)
            registerCorrection(original: content, corrected: corrected, type: .spelling)
        }
    }
    
    func correctText(_ text: String) -> String {
        guard isEnabled else { return text }
        
        var result = text
        let tag = spellChecker.checkString(
            result,
            range: NSRange(location: 0, length: result.utf16.count),
            types: NSTextCheckingResult.CheckingType([.spelling, .grammar]),
            options: [.languageKey: correctionLanguage],
            orthography: nil,
            wordCount: nil
        )
        
        if !tag.isEmpty {
            for checkingResult in tag.reversed() {
                if let suggestion = spellChecker.corrections(forWordRange: checkingResult.range, in: result, language: correctionLanguage, options: [:]), let firstSuggestion = suggestion.first {
                    if let nsRange = Range(checkingResult.range, in: result) {
                        result.replaceSubrange(nsRange, with: firstSuggestion)
                    }
                }
            }
        }
        
        if smartQuotes {
            result = applySmartQuotes(result)
        }
        
        if smartDashes {
            result = applySmartDashes(result)
        }
        
        if autoCapitalize {
            result = applyAutoCapitalize(result)
        }
        
        return result
    }
    
    private func applySmartQuotes(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "\"", with: "\u{201C}", options: .literal, range: nil)
        var isOpening = true
        var output = ""
        for char in result {
            if char == "\u{201C}" {
                output.append(isOpening ? "\u{201C}" : "\u{201D}")
                isOpening = !isOpening
            } else {
                output.append(char)
            }
        }
        return output
    }
    
    private func applySmartDashes(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "--", with: "\u{2014}")
        result = result.replacingOccurrences(of: " - ", with: " \u{2013} ")
        return result
    }
    
    private func applyAutoCapitalize(_ text: String) -> String {
        var result = text
        if let first = result.first, first.isLetter {
            result.replaceSubrange(result.startIndex...result.startIndex, with: String(first).uppercased())
        }
        
        let sentenceEnders: [Character] = [".", "!", "?"]
        for ender in sentenceEnders {
            let parts = result.split(separator: ender, omittingEmptySubsequences: false)
            if parts.count > 1 {
                result = parts.enumerated().map { index, part in
                    let trimmed = part.trimmingCharacters(in: .whitespaces)
                    if index > 0, let first = trimmed.first, first.isLetter {
                        return part.replacingCharacters(
                            in: part.rangeOfCharacter(from: .letters)!,
                            with: String(first).uppercased()
                        )
                    }
                    return part
                }.joined(separator: String(ender))
            }
        }
        
        return result
    }
    
    private func registerCorrection(original: String, corrected: String, type: CorrectionType) {
        let correction = Correction(
            original: original,
            corrected: corrected,
            type: type,
            timestamp: Date()
        )
        DispatchQueue.main.async {
            self.correctionHistory.insert(correction, at: 0)
            if self.correctionHistory.count > 50 {
                self.correctionHistory.removeLast()
            }
            self.correctionsCount += 1
            self.lastCorrection = "\(original) → \(corrected)"
        }
    }
    
    func getSuggestions(for word: String) -> [String] {
        return spellChecker.completions(forPartialWordRange: NSRange(location: 0, length: word.utf16.count), in: word, language: correctionLanguage, options: [:]) ?? []
    }
    
    func checkGrammar(_ text: String) -> [NSRange] {
        let results = spellChecker.checkString(
            text,
            range: NSRange(location: 0, length: text.utf16.count),
            types: .grammar,
            options: [.languageKey: correctionLanguage],
            orthography: nil,
            wordCount: nil
        )
        return results.map { $0.range }
    }
}
