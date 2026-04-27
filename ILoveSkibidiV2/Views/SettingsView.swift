import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("correctionLanguage") private var correctionLanguage = "fr"
    @AppStorage("darkMode") private var darkMode = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    @StateObject private var correctionService = TextCorrectionService.shared
    @StateObject private var notabilityService = NotabilityImportService.shared
    @StateObject private var scannerService = ScannerService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionHeader(title: "Réglages", icon: "gearshape.fill", subtitle: "Personnalisez votre expérience ILoveSkibidi V2")
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Général", icon: "gear")
                        
                        settingRow(icon: "power", title: "Lancer au démarrage", subtitle: "Ouvrir automatiquement au login", isOn: $launchAtLogin)
                        settingRow(icon: "menubar.arrow.up.rectangle", title: "Afficher dans la barre de menu", subtitle: "Icône dans la barre de menu", isOn: $showInMenuBar)
                        settingRow(icon: "moon.fill", title: "Mode sombre", subtitle: "Interface sombre premium", isOn: $darkMode)
                        settingRow(icon: "bell.fill", title: "Notifications", subtitle: "Notifications de correction", isOn: $notificationsEnabled)
                        settingRow(icon: "hand.tap.fill", title: "Retour haptique", subtitle: "Vibrations lors des interactions", isOn: $hapticFeedback)
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Langue de correction", icon: "globe")
                        
                        HStack(spacing: 12) {
                            LanguageButton(code: "fr", name: "Français", isSelected: correctionLanguage == "fr") {
                                correctionLanguage = "fr"
                                correctionService.correctionLanguage = "fr"
                            }
                            LanguageButton(code: "en", name: "English", isSelected: correctionLanguage == "en") {
                                correctionLanguage = "en"
                                correctionService.correctionLanguage = "en"
                            }
                            LanguageButton(code: "de", name: "Deutsch", isSelected: correctionLanguage == "de") {
                                correctionLanguage = "de"
                                correctionService.correctionLanguage = "de"
                            }
                            LanguageButton(code: "es", name: "Español", isSelected: correctionLanguage == "es") {
                                correctionLanguage = "es"
                                correctionService.correctionLanguage = "es"
                            }
                            LanguageButton(code: "it", name: "Italiano", isSelected: correctionLanguage == "it") {
                                correctionLanguage = "it"
                                correctionService.correctionLanguage = "it"
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Services", icon: "wrench.and.screwdriver")
                        
                        HStack(spacing: 8) {
                            ServiceStatusCard(name: "Correction", icon: "text.badge.checkmark", isEnabled: correctionService.isEnabled, color: .appPrimary)
                            ServiceStatusCard(name: "Notability", icon: "square.and.arrow.down", isEnabled: notabilityService.isEnabled, color: .appAccent)
                            ServiceStatusCard(name: "Scanner", icon: "doc.text.viewfinder", isEnabled: true, color: .appSuccess)
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Raccourcis clavier", icon: "keyboard")
                        
                        shortcutRow(key: "⌘ + ⇧ + C", description: "Corriger le texte sélectionné")
                        shortcutRow(key: "⌘ + ⇧ + N", description: "Import Notability")
                        shortcutRow(key: "⌘ + ⇧ + S", description: "Ouvrir le scanner")
                        shortcutRow(key: "⌘ + ⇧ + E", description: "Amélioration automatique")
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "À propos", icon: "info.circle.fill")
                        
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LinearGradient.appGradient)
                                    .frame(width: 50, height: 50)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ILoveSkibidi V2")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.appTextPrimary)
                                Text("Version 2.0.0 • Build 2024.1")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appTextSecondary)
                                Text("Premium Edition")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.appAccent)
                            }
                            
                            Spacer()
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        HStack(spacing: 20) {
                            aboutStat(label: "Fonctionnalités", value: "3+")
                            aboutStat(label: "Langues", value: "5")
                            aboutStat(label: "Formats", value: "8+")
                            aboutStat(label: "Statut", value: "Premium")
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Données", icon: "externaldrive")
                        
                        PremiumButton(title: "Effacer l'historique des corrections", icon: "trash", style: .danger) {
                            correctionService.correctionHistory = []
                            correctionService.correctionsCount = 0
                            correctionService.lastCorrection = ""
                        }
                        
                        PremiumButton(title: "Effacer l'historique des imports", icon: "trash", style: .danger) {
                            notabilityService.importHistory = []
                            notabilityService.importCount = 0
                        }
                        
                        PremiumButton(title: "Effacer l'historique des scans", icon: "trash", style: .danger) {
                            scannerService.scanHistory = []
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func settingRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
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
    
    private func shortcutRow(key: String, description: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.appPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appPrimary.opacity(0.12))
                )
            Text(description)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextPrimary)
            Spacer()
        }
    }
    
    private func aboutStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LanguageButton: View {
    var code: String
    var name: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(code.uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
                Text(name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? LinearGradient.appGradient : Color.appSurfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ServiceStatusCard: View {
    var name: String
    var icon: String
    var isEnabled: Bool
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isEnabled ? color : .appTextSecondary)
            
            Text(name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            
            StatusBadge(text: isEnabled ? "ACTIF" : "OFF", color: isEnabled ? .appSuccess : .appDanger)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
