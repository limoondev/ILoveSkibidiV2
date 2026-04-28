import SwiftUI

struct CorrectionMenuView: View {
    @StateObject private var service = GlobalSpellCheckerService.shared
    @State private var showMenu = false
    @State private var menuPosition: CGPoint = .zero
    @State private var selectedWord = ""
    @State private var suggestions: [String] = []
    
    var body: some View {
        ZStack {
            if showMenu {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mot mal orthographié")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.appTextSecondary)
                            
                            Text(selectedWord)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appDanger)
                        }
                        
                        Spacer()
                        
                        Button(action: { dismissMenu() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextSecondary)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(12)
                    .background(Color.appSurfaceLight.opacity(0.8))
                    
                    Divider().overlay(Color.appBorder)
                    
                    if !suggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    applyCorrection(suggestion)
                                }) {
                                    HStack {
                                        Text(suggestion)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12))
                                            .foregroundColor(.appSuccess)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                if suggestion != suggestions.last {
                                    Divider()
                                        .overlay(Color.appBorder.opacity(0.5))
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.appWarning)
                            Text("Aucune suggestion")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(20)
                    }
                    
                    Divider().overlay(Color.appBorder)
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            service.addToDictionary(selectedWord)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                                Text("Ajouter au dictionnaire")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            service.copyToClipboard(selectedWord)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                Text("Copier")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.appSurfaceLight.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(12)
                    .background(Color.appSurfaceLight.opacity(0.8))
                }
                .frame(width: 320)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
                )
                .position(menuPosition)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .onChange(of: service.showCorrectionMenu) { newValue in
            showMenu = newValue
            if newValue {
                selectedWord = service.selectedWord
                suggestions = service.currentSuggestions
                menuPosition = CGPoint(x: service.menuPosition.x, y: service.menuPosition.y)
            }
        }
    }
    
    private func applyCorrection(_ suggestion: String) {
        service.applyCorrection(suggestion)
        dismissMenu()
    }
    
    private func dismissMenu() {
        showMenu = false
        service.dismissMenu()
    }
}

struct CorrectionPopupView: View {
    @Binding var isPresented: Bool
    let word: String
    let suggestions: [String]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appWarning)
                    
                    Text("Correction orthographique")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    Text("Le mot \"\(word)\" semble mal orthographié")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                if !suggestions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                onSelect(suggestion)
                            }) {
                                HStack {
                                    Text(suggestion)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.appTextPrimary)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.appSuccess)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                } else {
                    Text("Aucune suggestion disponible")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                        .padding()
                }
                
                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Ignorer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appSurfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: {
                        GlobalSpellCheckerService.shared.addToDictionary(word)
                        onDismiss()
                    }) {
                        Text("Ajouter au dictionnaire")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(LinearGradient.appGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(24)
            .frame(width: 400)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .transition(.opacity)
    }
}
