import SwiftUI
import UniformTypeIdentifiers

struct NotabilityImportView: View {
    @StateObject private var service = NotabilityImportService.shared
    @State private var isImporting = false
    @State private var selectedFiles: [URL] = []
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionHeader(title: "Import Notability", icon: "square.and.arrow.down", subtitle: "Importez automatiquement vos fichiers dans Notability")
                
                GlassCard {
                    VStack(spacing: 16) {
                        HStack {
                            ToggleSwitch(isOn: $service.isEnabled, accentColor: .appAccent)
                            Text("Import Notability activé")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            StatusBadge(text: service.isNotabilityInstalled() ? "NOTABILITY DÉTECTÉ" : "NON DÉTECTÉ", color: service.isNotabilityInstalled() ? .appSuccess : .appWarning)
                        }
                        
                        Divider().overlay(Color.appBorder)
                        
                        HStack {
                            ToggleSwitch(isOn: $service.autoImport, accentColor: .appAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import automatique")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.appTextPrimary)
                                Text("Ouvrir directement dans Notability après sélection")
                                    .font(.system(size: 11))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Importer un fichier", icon: "doc.badge.plus")
                        
                        PremiumButton(title: "Sélectionner des fichiers", icon: "folder.open", style: .primary) {
                            let files = service.openFilePicker()
                            if !files.isEmpty {
                                selectedFiles = files
                                isImporting = true
                                
                                for file in files {
                                    let success = service.importToNotability(url: file)
                                    if success {
                                        successMessage = "Fichier importé avec succès !"
                                        showSuccess = true
                                    }
                                }
                                isImporting = false
                            }
                        }
                        
                        PremiumButton(title: "Partager via Share Sheet", icon: "square.and.arrow.up", style: .secondary) {
                            let files = service.openFilePicker()
                            if !files.isEmpty {
                                for file in files {
                                    service.importToNotabilityViaShareSheet(url: file)
                                }
                            }
                        }
                        
                        if isImporting {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                                Text("Import en cours...")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if showSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appSuccess)
                                Text(successMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appSuccess)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Formats supportés", icon: "doc.on.doc")
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(service.supportedFormats) { format in
                                VStack(spacing: 6) {
                                    Image(systemName: format.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(.appAccent)
                                    Text(format.name)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextPrimary)
                                    Text(".\(format.fileExtension)")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.appAccent.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Statistiques d'import", icon: "chart.bar.fill")
                        
                        HStack(spacing: 20) {
                            StatBox(value: "\(service.importCount)", label: "Imports", icon: "arrow.down.doc.fill", color: .appAccent)
                            StatBox(value: service.lastImportDate.map { formatDate($0) } ?? "—", label: "Dernier import", icon: "clock.fill", color: .appWarning)
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 8) {
                        SectionHeader(title: "Historique des imports", icon: "clock.arrow.circlepath")
                        
                        if service.importHistory.isEmpty {
                            Text("Aucun import pour le moment")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(service.importHistory.prefix(10)) { record in
                                HStack(spacing: 10) {
                                    Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(record.success ? .appSuccess : .appDanger)
                                        .font(.system(size: 14))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.fileName)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 8) {
                                            Text(".\(record.fileType)")
                                                .foregroundColor(.appTextSecondary)
                                            Text("•")
                                                .foregroundColor(.appTextSecondary)
                                            Text(service.formatFileSize(record.fileSize))
                                                .foregroundColor(.appTextSecondary)
                                        }
                                        .font(.system(size: 11))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(record.importDate, style: .time)
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}
