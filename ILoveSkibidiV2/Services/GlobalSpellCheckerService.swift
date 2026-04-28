import Foundation
import AppKit
import Carbon

class GlobalSpellCheckerService: ObservableObject {
    @Published var isEnabled = true
    @Published var correctionShortcut: String = "Cmd+Shift+C"
    @Published var isMonitoring = false
    @Published var currentSuggestions: [String] = []
    @Published var showCorrectionMenu = false
    @Published var menuPosition: NSPoint = .zero
    @Published var selectedWord: String = ""
    
    static let shared = GlobalSpellCheckerService()
    
    private var eventMonitor: EventMonitor?
    private let spellChecker = NSSpellChecker.shared
    
    init() {
        setupGlobalHotkey()
    }
    
    func setupGlobalHotkey() {
        // Setup global hotkey for spell checking
        // This would require accessibility permissions
    }
    
    func startMonitoring() {
        isMonitoring = true
        // Start monitoring clipboard and keyboard for misspelled words
    }
    
    func stopMonitoring() {
        isMonitoring = false
        // Stop monitoring
    }
    
    func checkCurrentWord() {
        // Get the currently selected text from the active application
        // This requires accessibility permissions
        if let selectedText = getSelectedText() {
            checkWord(selectedText)
        }
    }
    
    private func getSelectedText() -> String? {
        // Use accessibility API to get selected text
        // This is a simplified version
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    func checkWord(_ word: String) {
        selectedWord = word
        let misspelledRange = spellChecker.checkSpelling(of: word, startingAt: 0)
        
        if misspelledRange.location != NSNotFound {
            // Word is misspelled, get suggestions
            let suggestions = spellChecker.guesses(
                forWordRange: NSRange(location: 0, length: word.utf16.count),
                in: word,
                language: "fr",
                inSpellDocumentWithTag: 0
            )
            
            currentSuggestions = suggestions ?? []
            
            if !currentSuggestions.isEmpty {
                showCorrectionMenu = true
                menuPosition = getCursorPosition()
            }
        }
    }
    
    private func getCursorPosition() -> NSPoint {
        // Get the current cursor position
        // This would use accessibility API
        return NSEvent.mouseLocation
    }
    
    func applyCorrection(_ suggestion: String) {
        // Replace the misspelled word with the correction
        // This would use accessibility API to modify the text
        showCorrectionMenu = false
        currentSuggestions.removeAll()
    }
    
    func dismissMenu() {
        showCorrectionMenu = false
        currentSuggestions.removeAll()
        selectedWord = ""
    }
    
    func addToDictionary(_ word: String) {
        spellChecker.ignoreWord(word, inSpellDocumentWithTag: 0)
        dismissMenu()
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
