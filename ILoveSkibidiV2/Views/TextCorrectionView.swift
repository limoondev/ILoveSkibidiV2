import SwiftUI

struct TextCorrectionView: View {
    @StateObject private var service = TextCorrectionService.shared
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionHeader(title: "Correction Automatique", icon: "text.badge.checkmark", subtitle: "Correction avancée pour toutes les applications")
                
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
                            correctionToggle(icon: "text.append", title: "Remplacement automatique", subtitle: "Corrige le texte automatiquement", isOn: $service.autoReplace)
                            correctionToggle(icon: "quote.opening", title: "Guillemets intelligents", subtitle: "Remplace les guillemets droits", isOn: $service.smartQuotes)
                            correctionToggle(icon: "arrow.triangle.2.circlepath", title: "Tirets intelligents", subtitle: "Remplace les doubles tirets", isOn: $service.smartDashes)
                            correctionToggle(icon: "textformat.size", title: "Auto-capitalisation", subtitle: "Capitalise après les points", isOn: $service.autoCapitalize)
                            correctionToggle(icon: "textformat.abc", title: "Vérification orthographique", subtitle: "Corrige l'orthographe", isOn: $service.correctSpelling)
                            correctionToggle(icon: "text.badge.star", title: "Vérification grammaticale", subtitle: "Détecte les erreurs de grammaire", isOn: $service.grammarCheck)
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
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder.opacity(0.5), lineWidth: 1))
                        }
                        
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
                        
                        if !outputText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Résultat")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appSuccess)
                                Text(outputText)
                                    .font(.system(size: 14))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appSuccess.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
