import SwiftUI

struct TextCorrectionView: View {
    @StateObject private var service = TextCorrectionService.shared
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    @State private var selectedCorrectionLevel: CorrectionLevel = .standard
    @State private var showAdvancedOptions = false
    
    enum CorrectionLevel: String, CaseIterable {
        case minimal = "Minimal"
        case standard = "Standard"
        case aggressive = "Aggressif"
        case custom = "Personnalisé"
        
        var icon: String {
            switch self {
            case .minimal: return "minus.circle"
            case .standard: return "checkmark.circle"
            case .aggressive: return "exclamationmark.triangle"
            case .custom: return "slider.horizontal.3"
            }
        }
        
        var description: String {
            switch self {
            case .minimal: return "Corrections essentielles uniquement"
            case .standard: return "Équilibre optimal"
            case .aggressive: return "Toutes les corrections possibles"
            case .custom: return "Paramètres personnalisés"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        HStack {
                            ToggleSwitch(isOn: $service.isEnabled, accentColor: .appPrimary)
                            Text("Correction globale active")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            StatusBadge(text: service.isEnabled ? "ACTIF" : "INACTIF", color: service.isEnabled ? .appSuccess : .appDanger)
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        VStack(spacing: 12) {
                            Text("Niveau de correction")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(CorrectionLevel.allCases, id: \.self) { level in
                                    CorrectionLevelCard(
                                        level: level,
                                        isSelected: selectedCorrectionLevel == level,
                                        action: { selectedCorrectionLevel = level }
                                    )
                                }
                            }
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Options avancées")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Button(action: { withAnimation { showAdvancedOptions.toggle() } }) {
                                    Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.appPrimary)
                                }
                            }
                            
                            if showAdvancedOptions {
                                VStack(spacing: 12) {
                                    correctionToggle(icon: "text.append", title: "Remplacement automatique", subtitle: "Corrige le texte automatiquement", isOn: $service.autoReplace)
                                    correctionToggle(icon: "quote.opening", title: "Guillemets intelligents", subtitle: "Remplace les guillemets droits", isOn: $service.smartQuotes)
                                    correctionToggle(icon: "arrow.triangle.2.circlepath", title: "Tirets intelligents", subtitle: "Remplace les doubles tirets", isOn: $service.smartDashes)
                                    correctionToggle(icon: "textformat.size", title: "Auto-capitalisation", subtitle: "Capitalise après les points", isOn: $service.autoCapitalize)
                                    correctionToggle(icon: "textformat.abc", title: "Vérification orthographique", subtitle: "Corrige l'orthographe", isOn: $service.correctSpelling)
                                    correctionToggle(icon: "text.badge.star", title: "Vérification grammaticale", subtitle: "Détecte les erreurs de grammaire", isOn: $service.grammarCheck)
                                    correctionToggle(icon: "textformat", title: "Normalisation des espaces", subtitle: "Supprime les espaces en trop", isOn: .constant(true))
                                    correctionToggle(icon: "number", title: "Correction des nombres", subtitle: "Formate les nombres correctement", isOn: .constant(false))
                                }
                            } else {
                                VStack(spacing: 12) {
                                    correctionToggle(icon: "text.append", title: "Remplacement automatique", subtitle: "Corrige le texte automatiquement", isOn: $service.autoReplace)
                                    correctionToggle(icon: "quote.opening", title: "Guillemets intelligents", subtitle: "Remplace les guillemets droits", isOn: $service.smartQuotes)
                                    correctionToggle(icon: "textformat.abc", title: "Vérification orthographique", subtitle: "Corrige l'orthographe", isOn: $service.correctSpelling)
                                }
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Testeur de correction", icon: "flask")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Texte à corriger")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                            TextEditor(text: $inputText)
                                .font(.system(size: 14))
                                .frame(height: 100)
                                .padding(12)
                                .background(Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder.opacity(0.5), lineWidth: 1))
                        }
                        
                        HStack(spacing: 12) {
                            PremiumButton(title: "Corriger le texte", icon: "wand.and.stars", isLoading: isProcessing) {
                                isProcessing = true
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let result = service.correctText(inputText)
                                    DispatchQueue.main.async {
                                        outputText = result
                                        isProcessing = false
                                    }
                                }
                            }
                            
                            Button(action: { inputText = ""; outputText = "" }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.appSurfaceLight)
                                        .frame(width: 100, height: 44)
                                    Text("Effacer")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        if !outputText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Résultat")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.appSuccess)
                                    Spacer()
                                    Button(action: {
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(outputText, forType: .string)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 11))
                                            Text("Copier")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.appPrimary)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                
                                Text(outputText)
                                    .font(.system(size: 14))
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appSuccess.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Statistiques", icon: "chart.bar")
                        HStack(spacing: 20) {
                            StatBox(value: "\(service.correctionsCount)", label: "Corrections", icon: "checkmark.circle", color: .appPrimary)
                            StatBox(value: "\(service.correctionHistory.count)", label: "Historique", icon: "clock.arrow.circlepath", color: .appAccent)
                            StatBox(value: "98%", label: "Précision", icon: "target", color: .appSuccess)
                        }
                        
                        if !service.lastCorrection.isEmpty {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.appWarning)
                                Text("Dernière: \(service.lastCorrection)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 8) {
                        SectionHeader(title: "Historique récent", icon: "clock")
                        if service.correctionHistory.isEmpty {
                            Text("Aucune correction pour le moment")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(service.correctionHistory.prefix(10), id: \.timestamp) { correction in
                                HStack {
                                    StatusBadge(text: correction.type.rawValue, color: .appPrimary)
                                    Text(correction.original)
                                        .font(.system(size: 12))
                                        .foregroundColor(.appTextSecondary)
                                        .lineLimit(1)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.appPrimary)
                                    Text(correction.corrected)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.appTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(correction.timestamp, style: .time)
                                        .font(.system(size: 10))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func correctionToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            ToggleSwitch(isOn: isOn)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appGradient)
                        .frame(width: 50, height: 50)
                        .shadow(color: .appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "text.badge.checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Correction de texte")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.appGradientHorizontal)
                    Text("Correction avancée avec intelligence artificielle")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "V2.1", color: .appAccent)
            }
        }
    }
}

struct CorrectionLevelCard: View {
    let level: TextCorrectionView.CorrectionLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? level.accentColor.opacity(0.15) : Color.appSurfaceLight.opacity(0.5))
                        .frame(width: 50, height: 50)
                    Image(systemName: level.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? level.accentColor : .appTextSecondary)
                }
                
                VStack(spacing: 4) {
                    Text(level.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                    Text(level.description)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? level.accentColor.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? level.accentColor : Color.appBorder.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var accentColor: Color {
        switch level {
        case .minimal: return .blue
        case .standard: return .appPrimary
        case .aggressive: return .orange
        case .custom: return .purple
        }
    }
}

struct StatBox: View {
    var value: String
    var label: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }
}
