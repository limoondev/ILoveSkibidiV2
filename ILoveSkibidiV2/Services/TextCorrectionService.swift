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
        setupGlobalHotkey()
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
    
    private func setupGlobalHotkey() {
        // Setup global hotkey for quick correction (Cmd+Shift+C)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }
    
    private func handleGlobalKeyEvent(_ event: NSEvent) {
        // Check for Cmd+Shift+C for quick correction
        if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 8 { // C key
            correctSelectedText()
        }
        // Check for Cmd+Shift+V for paste and correct
        if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 { // V key
            pasteAndCorrect()
        }
    }
    
    func correctSelectedText() {
        // Get selected text from current application
        let pasteboard = NSPasteboard.general
        let originalContent = pasteboard.string(forType: .string) ?? ""
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait a bit for copy to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if let selectedText = pasteboard.string(forType: .string), !selectedText.isEmpty {
                let corrected = self.correctText(selectedText)
                if corrected != selectedText {
                    pasteboard.clearContents()
                    pasteboard.setString(corrected, forType: .string)
                    
                    // Simulate Cmd+V to paste corrected text
                    let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                    let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                    
                    vDown?.flags = .maskCommand
                    vUp?.flags = .maskCommand
                    
                    vDown?.post(tap: .cghidEventTap)
                    vUp?.post(tap: .cghidEventTap)
                    
                    self.registerCorrection(original: selectedText, corrected: corrected, type: .spelling)
                }
            }
        }
    }
    
    func pasteAndCorrect() {
        let pasteboard = NSPasteboard.general
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }
        
        let corrected = correctText(content)
        if corrected != content {
            pasteboard.clearContents()
            pasteboard.setString(corrected, forType: .string)
            registerCorrection(original: content, corrected: corrected, type: .spelling)
        }
        
        // Simulate Cmd+V to paste
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
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
        
        // Simple spell check using NSSpellChecker
        let words = result.components(separatedBy: .whitespacesAndNewlines)
        var correctedWords: [String] = []
        
        for word in words {
            let misspelledRange = spellChecker.checkSpelling(of: word, startingAt: 0)
            if misspelledRange.location == NSNotFound {
                // Word is spelled correctly
                correctedWords.append(word)
            } else {
                // Try to get suggestions
                if let range = result.range(of: word) {
                    let nsRange = NSRange(range, in: result)
                    if let suggestions = spellChecker.guesses(forWordRange: nsRange, in: result, language: correctionLanguage, inSpellDocumentWithTag: 0), let firstSuggestion = suggestions.first {
                        correctedWords.append(firstSuggestion)
                    } else {
                        correctedWords.append(word)
                    }
                } else {
                    correctedWords.append(word)
                }
            }
        }
        
        result = correctedWords.joined(separator: " ")
        
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
                        return String(part).replacingCharacters(
                            in: String(part).rangeOfCharacter(from: .letters)!,
                            with: String(first).uppercased()
                        )
                    }
                    return String(part)
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
        return spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.utf16.count), in: word, language: correctionLanguage, inSpellDocumentWithTag: 0) ?? []
    }
    
    func checkGrammar(_ text: String) -> [NSRange] {
        // Grammar check is simplified - just return empty for now
        return []
    }
}
