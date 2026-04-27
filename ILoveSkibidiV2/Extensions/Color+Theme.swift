import SwiftUI

extension Color {
    static let appPrimary = Color(red: 0.35, green: 0.22, blue: 0.95)
    static let appSecondary = Color(red: 0.55, green: 0.27, blue: 1.0)
    static let appAccent = Color(red: 0.95, green: 0.35, blue: 0.55)
    static let appSuccess = Color(red: 0.20, green: 0.85, blue: 0.55)
    static let appWarning = Color(red: 1.0, green: 0.72, blue: 0.20)
    static let appDanger = Color(red: 1.0, green: 0.30, blue: 0.35)
    static let appBackground = Color(red: 0.06, green: 0.06, blue: 0.12)
    static let appSurface = Color(red: 0.10, green: 0.10, blue: 0.18)
    static let appSurfaceLight = Color(red: 0.15, green: 0.15, blue: 0.25)
    static let appCardBackground = Color(red: 0.12, green: 0.12, blue: 0.22)
    static let appTextPrimary = Color(red: 0.95, green: 0.95, blue: 1.0)
    static let appTextSecondary = Color(red: 0.65, green: 0.65, blue: 0.78)
    static let appBorder = Color(red: 0.20, green: 0.20, blue: 0.35)
    static let appGradientStart = Color(red: 0.35, green: 0.22, blue: 0.95)
    static let appGradientMid = Color(red: 0.55, green: 0.27, blue: 1.0)
    static let appGradientEnd = Color(red: 0.95, green: 0.35, blue: 0.55)
    
    var glassBackground: some View {
        self.opacity(0.15)
    }
}

extension LinearGradient {
    static let appGradient = LinearGradient(
        colors: [.appGradientStart, .appGradientMid, .appGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let appGradientReversed = LinearGradient(
        colors: [.appGradientEnd, .appGradientMid, .appGradientStart],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let appGradientHorizontal = LinearGradient(
        colors: [.appGradientStart, .appGradientMid, .appGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
}
