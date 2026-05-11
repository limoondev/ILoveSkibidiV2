import SwiftUI

struct MainView: View {
    @StateObject private var correctionService = TextCorrectionService.shared
    @State private var selectedTab: Tab = .notability
    
    enum Tab: String, CaseIterable {
        case notability = "Notability"
        case settings = "Réglages"
        
        var icon: String {
            switch self {
            case .notability: return "square.and.arrow.down"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .overlay(Color.appBorder)
            
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient.appGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: .appPrimary.opacity(0.3), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mixky")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.appGradientHorizontal)
                    
                    Text("Votre assistant d'écriture")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                // Corrector status indicator
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(correctionService.isEnabled ? Color.green : Color.gray)
                            .frame(width: 16, height: 16)
                        
                        Text(correctionService.isEnabled ? "Correcteur actif" : "Correcteur inactif")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(correctionService.isEnabled ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                    
                    if correctionService.isEnabled {
                        Text("\(correctionService.correctionsCount) corrections")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            
            // Simple tab navigation
            HStack(spacing: 16) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .semibold))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .appTextPrimary)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedTab == tab ? LinearGradient.appGradient : Color.appSurfaceLight)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .background(Color.appSurface)
    }
    
    private var contentArea: some View {
        ZStack {
            Color.appBackground
            
            switch selectedTab {
            case .notability:
                NotabilityImportView()
            case .settings:
                SettingsView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
}
