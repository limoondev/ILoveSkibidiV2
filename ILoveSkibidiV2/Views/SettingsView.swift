import SwiftUI

struct SettingsView: View {
    @AppStorage("correctionLanguage") private var correctionLanguage = "fr"
    
    @StateObject private var correctionService = TextCorrectionService.shared
    @StateObject private var notabilityService = NotabilityImportService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                
                VStack(spacing: 24) {
                    // Corrector Toggle
                    GlassCard {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient.appGradient)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: .appPrimary.opacity(0.3), radius: 12, x: 0, y: 4)
                                    
                                    Image(systemName: "text.badge.checkmark")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Correcteur automatique")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.appTextPrimary)
                                    
                                    Text("Corrige vos fautes en temps réel")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                                
                                ToggleSwitch(isOn: $correctionService.isEnabled)
                                    .scaleEffect(1.3)
                            }
                            
                            if correctionService.isEnabled {
                                Divider().overlay(Color.appBorder)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(correctionService.correctionsCount)")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(.appPrimary)
                                        Text("Corrections effectuées")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(correctionService.lastCorrection.isEmpty ? "Aucune" : correctionService.lastCorrection)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.appAccent)
                                            .lineLimit(1)
                                        Text("Dernière correction")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.appSurfaceLight)
                                )
                            }
                        }
                    }
                    
                    // Language Selection
                    GlassCard {
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.appPrimary)
                                
                                Text("Langue de correction")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.appTextPrimary)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                LanguageButton(code: "fr", name: "Français", isSelected: correctionLanguage == "fr") {
                                    correctionLanguage = "fr"
                                }
                                LanguageButton(code: "en", name: "English", isSelected: correctionLanguage == "en") {
                                    correctionLanguage = "en"
                                }
                            }
                        }
                    }
                    
                    // Notability Service
                    GlassCard {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.appAccent)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: .appAccent.opacity(0.3), radius: 12, x: 0, y: 4)
                                    
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Import Notability")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.appTextPrimary)
                                    
                                    Text("\(notabilityService.importCount) imports effectués")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                                
                                ToggleSwitch(isOn: $notabilityService.isEnabled)
                                    .scaleEffect(1.3)
                            }
                        }
                    }
                    
                    // About
                    GlassCard {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(LinearGradient.appGradient)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: .appPrimary.opacity(0.3), radius: 12, x: 0, y: 4)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mixky")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(LinearGradient.appGradientHorizontal)
                                    
                                    Text("Version 1.0")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider().overlay(Color.appBorder)
                            
                            Text("Assistant d'écriture pour les élèves DYS, TDAH et dyslexiques")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(32)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appGradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: .appPrimary.opacity(0.3), radius: 12, x: 0, y: 4)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Réglages")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.appGradientHorizontal)
                    Text("Personnalisez Mixky")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }
}

struct LanguageButton: View {
    var code: String
    var name: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(code.uppercased())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
                Text(name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient.appGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appSurfaceLight.opacity(0.5))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
