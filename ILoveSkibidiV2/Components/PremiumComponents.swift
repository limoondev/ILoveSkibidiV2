import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 20
    var showBorder: Bool = true
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.appSurface.opacity(0.5))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showBorder ? Color.appBorder.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct PremiumButton: View {
    var title: String
    var icon: String? = nil
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var action: () -> Void
    
    enum ButtonStyleType {
        case primary, secondary, danger, success, ghost
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .appPrimary
        case .secondary: return .appSurfaceLight
        case .danger: return .appDanger
        case .success: return .appSuccess
        case .ghost: return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .danger, .success: return .white
        case .secondary: return .appTextPrimary
        case .ghost: return .appPrimary
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Group {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.appGradientHorizontal)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style == .ghost ? Color.appPrimary.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: style == .primary ? Color.appPrimary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FeatureCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var accentColor: Color
    var isSelected: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.appSuccess)
                        .frame(width: 10, height: 10)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.appPrimary.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appPrimary.opacity(0.3) : Color.appBorder.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ToggleSwitch: View {
    @Binding var isOn: Bool
    var accentColor: Color = .appPrimary
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
            .labelsHidden()
    }
}

struct StatusBadge: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

struct SectionHeader: View {
    var title: String
    var icon: String? = nil
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
