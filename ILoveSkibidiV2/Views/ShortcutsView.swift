import SwiftUI

struct ShortcutsView: View {
    @State private var shortcuts: [Shortcut] = []
    @State private var showingAddShortcut = false
    @State private var editingShortcut: Shortcut?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                quickActionsSection
                customShortcutsSection
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAddShortcut) {
            ShortcutEditView(shortcut: editingShortcut, onSave: saveShortcut)
        }
        .onAppear {
            loadShortcuts()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    Image(systemName: "keyboard")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Raccourcis personnalisés")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("\(shortcuts.count) raccourcis configurés")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Button(action: { showingAddShortcut = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.appGradient)
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions rapides")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "doc.text.fill",
                    title: "Corriger",
                    subtitle: "Cmd+Shift+C",
                    color: .appPrimary
                )
                
                QuickActionButton(
                    icon: "square.and.arrow.down.fill",
                    title: "Importer",
                    subtitle: "Cmd+Shift+I",
                    color: .appAccent
                )
                
                QuickActionButton(
                    icon: "doc.text.viewfinder.fill",
                    title: "Scanner",
                    subtitle: "Cmd+Shift+S",
                    color: .appSuccess
                )
                
                QuickActionButton(
                    icon: "doc.on.clipboard.fill",
                    title: "Presse-papier",
                    subtitle: "Cmd+Shift+V",
                    color: .purple
                )
            }
        }
    }
    
    private var customShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Raccourcis personnalisés")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Spacer()
            }
            
            if shortcuts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "keyboard.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                    Text("Aucun raccourci personnalisé")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    Button(action: { showingAddShortcut = true }) {
                        Text("Ajouter un raccourci")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(LinearGradient.appGradient)
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appSurfaceLight.opacity(0.5))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(shortcuts) { shortcut in
                        ShortcutCard(
                            shortcut: shortcut,
                            onEdit: { editingShortcut = shortcut; showingAddShortcut = true },
                            onDelete: deleteShortcut(shortcut)
                        )
                    }
                }
            }
        }
    }
    
    private func loadShortcuts() {
        shortcuts = [
            Shortcut(id: UUID(), name: "Ouvrir Notability", action: "open-notability", keys: ["Command", "Option", "N"]),
            Shortcut(id: UUID(), name: "Copier tout", action: "copy-all", keys: ["Command", "Shift", "A"]),
        ]
    }
    
    private func saveShortcut(_ shortcut: Shortcut) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
        } else {
            shortcuts.append(shortcut)
        }
    }
    
    private func deleteShortcut(_ shortcut: Shortcut) -> () -> Void {
        return {
            shortcuts.removeAll { $0.id == shortcut.id }
        }
    }
}

struct Shortcut: Identifiable {
    let id: UUID
    var name: String
    var action: String
    var keys: [String]
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(16)
        }
    }
}

struct ShortcutCard: View {
    let shortcut: Shortcut
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shortcut.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text(shortcut.action)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(shortcut.keys, id: \.self) { key in
                        KeyBadge(key: key)
                    }
                }
                
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onDelete) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(16)
        }
    }
}

struct KeyBadge: View {
    let key: String
    
    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.appSurfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
    }
}

struct ShortcutEditView: View {
    @Environment(\.dismiss) var dismiss
    var shortcut: Shortcut?
    var onSave: (Shortcut) -> Void
    
    @State private var name: String = ""
    @State private var action: String = ""
    @State private var keys: [String] = []
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(shortcut == nil ? "Nouveau raccourci" : "Modifier le raccourci")
                .font(.system(size: 20, weight: .bold))
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                    TextField("Ex: Ouvrir Notability", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Action")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                    TextField("Ex: open-notability", text: $action)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Touches")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(keys, id: \.self) { key in
                            KeyBadge(key: key)
                        }
                        
                        Button(action: { isRecording.toggle() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isRecording ? Color.red.opacity(0.1) : Color.appPrimary.opacity(0.1))
                                    .frame(width: 100, height: 32)
                                Text(isRecording ? "Enregistrement..." : "Enregistrer")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(isRecording ? .red : .appPrimary)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Annuler")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSurfaceLight)
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: save) {
                    Text("Enregistrer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.appGradient)
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(name.isEmpty || action.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            if let shortcut = shortcut {
                name = shortcut.name
                action = shortcut.action
                keys = shortcut.keys
            }
        }
    }
    
    private func save() {
        let newShortcut = Shortcut(
            id: shortcut?.id ?? UUID(),
            name: name,
            action: action,
            keys: keys
        )
        onSave(newShortcut)
        dismiss()
    }
}
