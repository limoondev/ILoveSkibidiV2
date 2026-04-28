import SwiftUI

struct ClipboardHistoryView: View {
    @State private var clipboardItems: [ClipboardItem] = []
    @State private var selectedItem: ClipboardItem?
    @State private var searchText = ""
    @State private var maxHistoryItems = 50
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardItems
        }
        return clipboardItems.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                searchSection
                settingsSection
                itemsSection
            }
            .padding(24)
        }
        .onAppear {
            loadClipboardHistory()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Historique du presse-papier")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("\(clipboardItems.count) éléments sauvegardés")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Button(action: clearHistory) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var searchSection: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.appTextSecondary)
                
                TextField("Rechercher dans l'historique...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.appTextSecondary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var settingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paramètres")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Maximum d'éléments")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                        Stepper(value: $maxHistoryItems, in: 10...200) {
                            Text("\(maxHistoryItems)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appTextPrimary)
                        }
                        .labelsHidden()
                    }
                    
                    HStack {
                        Text("Sauvegarder automatiquement")
                            .font(.system(size: 14))
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                        ToggleSwitch(isOn: .constant(true))
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var itemsSection: some View {
        VStack(spacing: 12) {
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.appTextSecondary.opacity(0.5))
                    Text(searchText.isEmpty ? "Aucun élément dans l'historique" : "Aucun résultat")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(filteredItems) { item in
                    ClipboardItemCard(item: item, onTap: { selectedItem = item })
                }
            }
        }
    }
    
    private func loadClipboardHistory() {
        // Simulated clipboard history
        clipboardItems = [
            ClipboardItem(id: UUID(), content: "Exemple de texte copié", type: .text, date: Date()),
            ClipboardItem(id: UUID(), content: "https://github.com", type: .url, date: Date().addingTimeInterval(-3600)),
            ClipboardItem(id: UUID(), content: "Autre texte important", type: .text, date: Date().addingTimeInterval(-7200)),
        ]
    }
    
    private func clearHistory() {
        clipboardItems.removeAll()
    }
}

struct ClipboardItem: Identifiable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let date: Date
}

enum ClipboardItemType {
    case text
    case url
    case image
    case file
}

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let onTap: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(typeColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: typeIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(typeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.content)
                            .font(.system(size: 14))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(2)
                        Text(formatDate(item.date))
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onTap) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appPrimary.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(16)
        }
    }
    
    private var typeColor: Color {
        switch item.type {
        case .text: return .blue
        case .url: return .green
        case .image: return .purple
        case .file: return .orange
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
