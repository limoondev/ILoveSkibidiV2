import SwiftUI

struct ScannerView: View {
    @StateObject private var service = ScannerService.shared
    @State private var showImagePreview = false
    @State private var isCapturing = false
    @State private var selectedFilter: ScannerFilter = .none
    @State private var showAdvancedFilters = false
    
    enum ScannerFilter: String, CaseIterable {
        case none = "Aucun"
        case grayscale = "Niveau de gris"
        case sepia = "Sépia"
        case vintage = "Vintage"
        case blackAndWhite = "Noir et blanc"
        case cool = "Froid"
        case warm = "Chaud"
        
        var icon: String {
            switch self {
            case .none: return "photo"
            case .grayscale: return "circle.lefthalf.filled"
            case .sepia: return "paintpalette"
            case .vintage: return "camera.aperture"
            case .blackAndWhite: return "circle"
            case .cool: return "snow"
            case .warm: return "sun.max.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .grayscale: return .black
            case .sepia: return .orange
            case .vintage: return .brown
            case .blackAndWhite: return .black
            case .cool: return .blue
            case .warm: return .yellow
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Source", icon: "camera")
                        
                        HStack(spacing: 16) {
                            ScannerSourceButton(icon: "camera.fill", title: "Appareil photo", subtitle: "Capturer via la caméra", color: .appPrimary) {
                                isCapturing = true
                                if let image = service.openImageForScanning() {
                                    service.scannedImage = image
                                    service.processedImage = service.processImage(image)
                                    showImagePreview = true
                                    service.saveScannedImage(image)
                                }
                                isCapturing = false
                            }
                            
                            ScannerSourceButton(icon: "photo.on.rectangle", title: "Ouvrir une image", subtitle: "Sélectionner depuis le disque", color: .appAccent) {
                                if let image = service.openImageForScanning() {
                                    service.scannedImage = image
                                    service.processedImage = service.processImage(image)
                                    showImagePreview = true
                                    service.saveScannedImage(image)
                                }
                            }
                        }
                    }
                }
                
                if showImagePreview, let processedImage = service.processedImage {
                    GlassCard {
                        VStack(spacing: 16) {
                            SectionHeader(title: "Aperçu du scan", icon: "eye")
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appSurfaceLight)
                                    .frame(height: 300)
                                
                                Image(nsImage: processedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 8)
                            }
                            
                            HStack(spacing: 12) {
                                PremiumButton(title: "Exporter", icon: "square.and.arrow.up", style: .success) {
                                    service.exportImage(processedImage)
                                }
                                
                                PremiumButton(title: "Import Notability", icon: "square.and.arrow.down", style: .secondary) {
                                    // Export temp then import
                                    let tempDir = FileManager.default.temporaryDirectory
                                    let tempURL = tempDir.appendingPathComponent("scan_\(Int(Date().timeIntervalSince1970)).png")
                                    if let tiffData = processedImage.tiffRepresentation,
                                       let bitmap = NSBitmapImageRep(data: tiffData),
                                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                                        try? pngData.write(to: tempURL)
                                        NotabilityImportService.shared.importToNotability(url: tempURL)
                                    }
                                }
                                
                                Button(action: {
                                    service.copyToClipboard(processedImage)
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.appSurfaceLight)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appPrimary)
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Réglages d'image", icon: "slider.horizontal.3")
                        
                        HStack {
                            ToggleSwitch(isOn: $service.autoEnhance, accentColor: .appSuccess)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Amélioration automatique")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.appTextPrimary)
                                Text("Ajuste automatiquement la clarté et le contraste")
                                    .font(.system(size: 11))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Filtres")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Button(action: { withAnimation { showAdvancedFilters.toggle() } }) {
                                    Image(systemName: showAdvancedFilters ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.appSuccess)
                                }
                            }
                            
                            if showAdvancedFilters {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 10) {
                                    ForEach(ScannerFilter.allCases, id: \.self) { filter in
                                        FilterButton(
                                            filter: filter,
                                            isSelected: selectedFilter == filter,
                                            action: { selectedFilter = filter }
                                        )
                                    }
                                }
                            } else {
                                HStack(spacing: 10) {
                                    ForEach([ScannerFilter.none, .grayscale, .sepia, .blackAndWhite], id: \.self) { filter in
                                        FilterButton(
                                            filter: filter,
                                            isSelected: selectedFilter == filter,
                                            action: { selectedFilter = filter }
                                        )
                                    }
                                }
                            }
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        VStack(spacing: 16) {
                            ScannerSlider(value: $service.brightness, range: -1...1, label: "Luminosité", icon: "sun.max.fill", color: .appWarning)
                            ScannerSlider(value: $service.contrast, range: 0.5...3, label: "Contraste", icon: "circle.lefthalf.filled", color: .appPrimary)
                            ScannerSlider(value: $service.saturation, range: 0...2, label: "Saturation", icon: "paintpalette.fill", color: .appAccent)
                            ScannerSlider(value: $service.sharpness, range: 0...2, label: "Netteté", icon: "scope", color: .appSuccess)
                        }
                        
                        PremiumButton(title: "Réinitialiser les réglages", icon: "arrow.counterclockwise", style: .ghost) {
                            service.resetAdjustments()
                        }
                    }
                }
            }
            
            if showImagePreview, let processedImage = service.processedImage {
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Aperçu du scan", icon: "eye")
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appSurfaceLight)
                                .frame(height: 300)
                            
                            Image(nsImage: processedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 8)
                        }
                        
                        HStack(spacing: 12) {
                            PremiumButton(title: "Exporter", icon: "square.and.arrow.up", style: .success) {
                                service.exportImage(processedImage)
                            }
                            
                            PremiumButton(title: "Import Notability", icon: "square.and.arrow.down", style: .secondary) {
                                // Export temp then import
                                let tempDir = FileManager.default.temporaryDirectory
                                let tempURL = tempDir.appendingPathComponent("scan_\(Int(Date().timeIntervalSince1970)).png")
                                if let tiffData = processedImage.tiffRepresentation,
                                   let bitmap = NSBitmapImageRep(data: tiffData),
                                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                                    try? pngData.write(to: tempURL)
                                    NotabilityImportService.shared.importToNotability(url: tempURL)
                                }
                            }
                            
                            Button(action: {
                                service.copyToClipboard(processedImage)
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.appSurfaceLight)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appPrimary)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
            
            GlassCard {
                VStack(spacing: 16) {
                    SectionHeader(title: "Réglages d'image", icon: "slider.horizontal.3")
                    
                    HStack {
                        ToggleSwitch(isOn: $service.autoEnhance, accentColor: .appSuccess)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Amélioration automatique")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Ajuste automatiquement la clarté et le contraste")
                                .font(.system(size: 11))
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                }
            }
            
            GlassCard {
                VStack(spacing: 12) {
                    SectionHeader(title: "Historique des scans", icon: "clock.arrow.circlepath")
                    
                    if service.scanHistory.isEmpty {
                            Text("Aucun scan pour le moment")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(service.scanHistory.prefix(8)) { record in
                                HStack(spacing: 12) {
                                    Image(nsImage: record.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Scan - \(record.mode.rawValue)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                        HStack(spacing: 6) {
                                            Text(record.date, style: .date)
                                            Text("•")
                                            if record.enhanced {
                                                StatusBadge(text: "AMÉLIORÉ", color: .appSuccess)
                                            }
                                        }
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { service.exportImage(record.image) }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.appPrimary)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .onChange(of: service.brightness) { _ in reprocessImage() }
            .onChange(of: service.contrast) { _ in reprocessImage() }
            .onChange(of: service.saturation) { _ in reprocessImage() }
            .onChange(of: service.sharpness) { _ in reprocessImage() }
            .onChange(of: service.documentMode) { _ in reprocessImage() }
        }
    }
    
    private func reprocessImage() {
        if let scanned = service.scannedImage {
            service.processedImage = service.processImage(scanned)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.appSuccess, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .appSuccess.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanner de documents")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.appSuccess, .teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Scannez et améliorez vos documents avec l'appareil photo")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "V2.0", color: .appSuccess)
            }
        }
    }
}

struct FilterButton: View {
    let filter: ScannerView.ScannerFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? filter.color.opacity(0.2) : Color.appSurfaceLight.opacity(0.5))
                        .frame(width: 36, height: 36)
                    Image(systemName: filter.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? filter.color : .appTextSecondary)
                }
                Text(filter.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? filter.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? filter.color : Color.appBorder.opacity(0.3), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScannerSourceButton: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appSurfaceLight.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScannerSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var label: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(String(format: "%.1f", value))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.appTextSecondary)
            }
            
            Slider(value: $value, in: range)
                .tint(color)
        }
    }
}

struct ScannerModeButton: View {
    var mode: ScannerService.DocumentMode
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
                
                Text(mode.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.appGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appSurfaceLight.opacity(0.5))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
