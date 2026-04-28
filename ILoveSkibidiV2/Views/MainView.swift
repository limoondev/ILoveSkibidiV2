import SwiftUI

struct MainView: View {
    @State private var selectedTab: Tab = .correction
    @State private var sidebarHover: Tab? = nil
    @State private var isAnimating = false
    
    enum Tab: String, CaseIterable {
        case correction = "Correction"
        case notability = "Notability"
        case scanner = "Scanner"
        case settings = "Réglages"
        case clipboard = "Presse-papier"
        case shortcuts = "Raccourcis"
        
        var icon: String {
            switch self {
            case .correction: return "text.badge.checkmark"
            case .notability: return "square.and.arrow.down"
            case .scanner: return "doc.text.viewfinder"
            case .settings: return "gearshape.fill"
            case .clipboard: return "doc.on.clipboard"
            case .shortcuts: return "keyboard"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .correction: return .appPrimary
            case .notability: return .appAccent
            case .scanner: return .appSuccess
            case .settings: return .appTextSecondary
            case .clipboard: return .purple
            case .shortcuts: return .orange
            }
        }
        
        var subtitle: String {
            switch self {
            case .correction: return "Correction de texte avancée"
            case .notability: return "Import automatique Notability"
            case .scanner: return "Scanner & amélioration"
            case .settings: return "Préférences de l'app"
            case .clipboard: return "Historique du presse-papier"
            case .shortcuts: return "Raccourcis clavier personnalisés"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 280)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            Divider()
                .overlay(Color.appBorder)
            
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
        }
        .background(Color.appBackground)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    private var sidebar: some View {
        VStack(spacing: 0) {
            appHeader
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            
            Divider().overlay(Color.appBorder.opacity(0.5))
            
            VStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    SidebarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isHovered: sidebarHover == tab,
                        action: { selectedTab = tab },
                        onHover: { hovering in if hovering { sidebarHover = tab } else { sidebarHover = nil } }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            
            Spacer()
            
            VStack(spacing: 12) {
                Divider().overlay(Color.appBorder.opacity(0.5))
                
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.appGradient)
                            .frame(width: 36, height: 36)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ILoveSkibidi V2")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                        Text("v2.0.0 • Premium")
                            .font(.system(size: 10))
                            .foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(
            ZStack {
                Color.appSurface
                Color.appPrimary.opacity(0.03)
            }
        )
    }
    
    private var appHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient.appGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: .appPrimary.opacity(0.4), radius: 12, x: 0, y: 4)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("ILoveSkibidi")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.appGradientHorizontal)
            
            Text("V2")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.appAccent)
        }
    }
    
    private var contentArea: some View {
        ZStack {
            Color.appBackground
            
            switch selectedTab {
            case .correction:
                TextCorrectionView()
            case .notability:
                NotabilityImportView()
            case .scanner:
                ScannerView()
            case .settings:
                SettingsView()
            case .clipboard:
                ClipboardHistoryView()
            case .shortcuts:
                ShortcutsView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
}

struct SidebarButton: View {
    var tab: MainView.Tab
    var isSelected: Bool
    var isHovered: Bool
    var action: () -> Void
    var onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? tab.accentColor.opacity(0.2) : (isHovered ? Color.appSurfaceLight : Color.clear))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? tab.accentColor : .appTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                    Text(tab.subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(tab.accentColor)
                        .frame(width: 4, height: 24)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.accentColor.opacity(0.08) : (isHovered ? Color.appSurfaceLight.opacity(0.5) : Color.clear))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onHover(perform: onHover)
    }
}
