import SwiftUI

struct VoiceDictationView: View {
    @StateObject private var service = VoiceDictationService.shared
    @State private var isRecording = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 20) {
                        SectionHeader(title: "Dictée vocale", icon: "mic.fill")
                        
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(service.isRecording ? AnyShapeStyle(LinearGradient.appGradient) : AnyShapeStyle(Color.appSurfaceLight.opacity(0.5)))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: service.isRecording ? .appPrimary.opacity(0.4) : .clear, radius: 16)
                                
                                if service.isRecording {
                                    Circle()
                                        .fill(Color.appPrimary)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .scaleEffect(service.isListening ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: service.isListening)
                                } else {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(.appPrimary)
                                }
                            }
                            .onTapGesture {
                                if service.isRecording {
                                    service.stopRecording()
                                } else {
                                    service.startRecording()
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text(service.isRecording ? "Enregistrement..." : "Taper pour enregistrer")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(service.isRecording ? .appPrimary : .appTextSecondary)
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Texte transcrit")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            
                            ZStack(alignment: .topLeading) {
                                if service.transcribedText.isEmpty {
                                    Text("Le texte transcrit apparaîtra ici...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.appTextSecondary.opacity(0.6))
                                        .padding(16)
                                }
                                
                                ScrollView {
                                    Text(service.transcribedText)
                                        .font(.system(size: 14))
                                        .foregroundColor(.appTextPrimary)
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(minHeight: 150)
                                .background(Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                                )
                            }
                            
                            HStack(spacing: 12) {
                                if !service.transcribedText.isEmpty {
                                    Button(action: { service.copyToClipboard() }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 12))
                                            Text("Copier")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.appPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.appPrimary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    
                                    Button(action: { service.clearText() }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12))
                                            Text("Effacer")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.appDanger)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.appDanger.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Langue", icon: "globe")
                        
                        HStack(spacing: 12) {
                            LanguageButton(code: "fr", name: "Français", isSelected: true) {}
                            LanguageButton(code: "en", name: "English", isSelected: false) {}
                            LanguageButton(code: "de", name: "Deutsch", isSelected: false) {}
                            LanguageButton(code: "es", name: "Español", isSelected: false) {}
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dictée Vocale")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Transformez votre voix en texte")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: service.isRecording ? "EN COURS" : "PRÊT", color: service.isRecording ? .red : .appSuccess)
            }
        }
    }
}

struct LanguageButton: View {
    let code: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
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
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appSurfaceLight.opacity(0.5))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
