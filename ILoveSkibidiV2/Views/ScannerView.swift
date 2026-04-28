import SwiftUI

struct ScannerView: View {
    @StateObject private var service = ScannerService.shared
    @State private var showImagePreview = false
    @State private var isCapturing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionHeader(title: "Scanner de documents", icon: "doc.text.viewfinder", subtitle: "Scannez et améliorez vos documents avec l'appareil photo")
                
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
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Mode document", icon: "doc.text.fill")
                        
                        HStack(spacing: 12) {
                            ForEach(ScannerService.DocumentMode.allCases, id: \.self) { mode in
                                ScannerModeButton(
                                    mode: mode,
                                    isSelected: service.documentMode == mode
                                ) {
                                    service.documentMode = mode
                                }
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 8) {
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
        }
        .onChange(of: service.brightness) { _ in reprocessImage() }
        .onChange(of: service.contrast) { _ in reprocessImage() }
        .onChange(of: service.saturation) { _ in reprocessImage() }
        .onChange(of: service.sharpness) { _ in reprocessImage() }
        .onChange(of: service.documentMode) { _ in reprocessImage() }
    }
    
    private func reprocessImage() {
        if let scanned = service.scannedImage {
            service.processedImage = service.processImage(scanned)
        }
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? LinearGradient.appGradient : Color.appSurfaceLight.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
