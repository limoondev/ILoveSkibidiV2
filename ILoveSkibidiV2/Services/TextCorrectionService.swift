import Foundation
import AppKit

class TextCorrectionService: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var correctionsCount: Int = 0
    @Published var lastCorrection: String = ""
    
    private let spellChecker = NSSpellChecker.shared
    private var eventTap: CFMachPort?
    private var currentWord: String = ""
    
    static let shared = TextCorrectionService()
    
    struct Correction {
        let original: String
        let corrected: String
        let timestamp: Date
    }
    
    @Published var correctionHistory: [Correction] = []
    
    init() {
        setupSpellChecker()
    }
    
    func startGlobalCorrection() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        let userData = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                
                let service = Unmanaged<TextCorrectionService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleKeyEvent(event: event)
            },
            userInfo: userData
        )
        
        if let tap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
    }
    
    func stopGlobalCorrection() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    
    private func handleKeyEvent(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passRetained(event) }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Ignore if modifier keys are pressed (Cmd, Ctrl, Option)
        if flags.contains([.maskCommand, .maskControl, .maskAlternate]) {
            return Unmanaged.passRetained(event)
        }
        
        // Get the character
        let characters = event.characters
        let charactersIgnoringModifiers = event.charactersIgnoringModifiers
        
        guard let char = charactersIgnoringModifiers?.lowercased().first else {
            return Unmanaged.passRetained(event)
        }
        
        // If space, return, or tab is pressed, check and correct the current word
        if char == " " || keyCode == 36 || keyCode == 48 {
            if !currentWord.isEmpty {
                let corrected = correctWord(currentWord)
                if corrected != currentWord {
                    // Delete the incorrect word
                    deleteCurrentWord(count: currentWord.count)
                    
                    // Type the corrected word
                    typeWord(corrected)
                    
                    // Register the correction
                    registerCorrection(original: currentWord, corrected: corrected)
                    
                    currentWord = ""
                } else {
                    currentWord = ""
                }
            }
            return Unmanaged.passRetained(event)
        }
        
        // If backspace is pressed, remove last character from current word
        if keyCode == 51 {
            if !currentWord.isEmpty {
                currentWord.removeLast()
            }
            return Unmanaged.passRetained(event)
        }
        
        // If it's a letter or apostrophe, add to current word
        if char.isLetter || char == "'" {
            currentWord.append(char)
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func deleteCurrentWord(count: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            let backspace = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
            backspace?.post(tap: .cghidEventTap)
            let backspaceUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
            backspaceUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func typeWord(_ word: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        for char in word {
            let keyCode = keyCodeForCharacter(char)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
            
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func keyCodeForCharacter(_ char: Character) -> CGKeyCode {
        let lowercase = char.lowercased()
        let keyCodeMap: [String: CGKeyCode] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4,
            "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35,
            "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7,
            "y": 16, "z": 6, "'": 39, "-": 27
        ]
        return keyCodeMap[lowercase] ?? 0
    }
    
    private func setupSpellChecker() {
        spellChecker.setLanguage("fr")
    }
    
    private func correctWord(_ word: String) -> String {
        let misspelledRange = spellChecker.checkSpelling(of: word, startingAt: 0)
        if misspelledRange.location == NSNotFound {
            return word
        }
        
        if let suggestions = spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.utf16.count), in: word, language: "fr", inSpellDocumentWithTag: 0),
           let firstSuggestion = suggestions.first {
            return firstSuggestion
        }
        
        return word
    }
    
    private func registerCorrection(original: String, corrected: String) {
        let correction = Correction(
            original: original,
            corrected: corrected,
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
}
