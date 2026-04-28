import SwiftUI

struct QuickNotesView: View {
    @StateObject private var service = QuickNotesService.shared
    @State private var newNoteContent = ""
    @State private var selectedColor: QuickNotesService.QuickNote.NoteColor = .white
    @State private var showColorPicker = false
    @State private var editingNote: QuickNotesService.QuickNote?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Nouvelle note", icon: "plus.circle.fill")
                        
                        ZStack(alignment: .topLeading) {
                            if newNoteContent.isEmpty {
                                Text("Écrivez votre note ici...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary.opacity(0.6))
                                    .padding(16)
                            }
                            
                            TextEditor(text: $newNoteContent)
                                .font(.system(size: 14))
                                .padding(16)
                                .frame(minHeight: 100)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                        }
                        .background(selectedColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
                        )
                        
                        HStack(spacing: 12) {
                            Button(action: { showColorPicker.toggle() }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(selectedColor.color)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                                        )
                                    Text("Couleur")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                            
                            PremiumButton(title: "Ajouter", icon: "plus", style: .primary) {
                                if !newNoteContent.isEmpty {
                                    service.addNote(content: newNoteContent, color: selectedColor)
                                    newNoteContent = ""
                                    selectedColor = .white
                                }
                            }
                        }
                        
                        if showColorPicker {
                            HStack(spacing: 8) {
                                ForEach(QuickNotesService.QuickNote.NoteColor.allCases, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                        showColorPicker = false
                                    }) {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color ? Color.appPrimary : Color.appBorder.opacity(0.3), lineWidth: selectedColor == color ? 2 : 1)
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 4)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Mes notes", icon: "note.text")
                        
                        if service.notes.isEmpty {
                            Text("Aucune note pour le moment")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(service.notes) { note in
                                    NoteCard(note: note) {
                                        editingNote = note
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .sheet(item: $editingNote) { note in
            NoteEditView(note: note)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "note.text")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes Rapides")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Capturez vos idées instantanément")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "\(service.notes.count)", color: .orange)
            }
        }
    }
}

struct NoteCard: View {
    let note: QuickNotesService.QuickNote
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(note.content)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.appPrimary)
                }
            }
            
            HStack {
                Text(formatDate(note.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.appPrimary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(note.color.color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

struct NoteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    let note: QuickNotesService.QuickNote
    
    init(note: QuickNotesService.QuickNote) {
        self.note = note
        self._content = State(initialValue: note.content)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Modifier la note")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.appTextPrimary)
            
            TextEditor(text: $content)
                .font(.system(size: 14))
                .frame(minHeight: 200)
                .padding(12)
                .background(Color.appSurfaceLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                PremiumButton(title: "Annuler", icon: "xmark", style: .ghost) {
                    dismiss()
                }
                
                PremiumButton(title: "Sauvegarder", icon: "checkmark", style: .primary) {
                    var updatedNote = note
                    updatedNote.content = content
                    QuickNotesService.shared.updateNote(updatedNote)
                    dismiss()
                }
            }
        }
        .padding(24)
        .frame(width: 500, height: 400)
        .background(Color.appBackground)
    }
}
