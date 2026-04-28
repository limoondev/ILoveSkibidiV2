import Foundation
import AppKit
import SwiftUI

class QuickNotesService: ObservableObject {
    @Published var notes: [QuickNote] = []
    @Published var isRecording = false
    
    static let shared = QuickNotesService()
    
    struct QuickNote: Identifiable, Codable {
        var id = UUID()
        var content: String
        var createdAt: Date
        var updatedAt: Date
        var isPinned: Bool
        var tags: [String]
        var color: NoteColor
        
        enum NoteColor: String, Codable, CaseIterable {
            case white = "Blanc"
            case yellow = "Jaune"
            case blue = "Bleu"
            case green = "Vert"
            case pink = "Rose"
            case purple = "Violet"
            
            var color: Color {
                switch self {
                case .white: return .white
                case .yellow: return Color(hex: "FFF9C4")
                case .blue: return Color(hex: "BBDEFB")
                case .green: return Color(hex: "C8E6C9")
                case .pink: return Color(hex: "F8BBD0")
                case .purple: return Color(hex: "E1BEE7")
                }
            }
        }
    }
    
    init() {
        loadNotes()
    }
    
    func addNote(content: String, color: QuickNote.NoteColor = .white) {
        let note = QuickNote(
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            isPinned: false,
            tags: [],
            color: color
        )
        notes.insert(note, at: 0)
        saveNotes()
    }
    
    func updateNote(_ note: QuickNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func deleteNote(_ note: QuickNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func togglePin(_ note: QuickNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            saveNotes()
        }
    }
    
    func addTag(_ tag: String, to note: QuickNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            if !notes[index].tags.contains(tag) {
                notes[index].tags.append(tag)
                saveNotes()
            }
        }
    }
    
    private func saveNotes() {
        // Save to UserDefaults or file
    }
    
    private func loadNotes() {
        // Load from UserDefaults or file
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
