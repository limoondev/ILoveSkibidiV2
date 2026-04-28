import SwiftUI

struct PDFMergerView: View {
    @StateObject private var service = PDFMergerService.shared
    @State private var showSavePanel = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Fichiers PDF", icon: "doc.richtext")
                        
                        PremiumButton(title: "Ajouter des PDFs", icon: "plus", style: .primary) {
                            service.selectPDFs()
                        }
                        
                        if !service.pdfFiles.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(Array(service.pdfFiles.enumerated()), id: \.offset) { index, url in
                                    PDFFileRow(url: url, index: index) {
                                        service.removePDF(at: IndexSet(integer: index))
                                    }
                                }
                                .onMove { source, destination in
                                    service.reorderPDFs(from: source, to: destination)
                                }
                            }
                        } else {
                            Text("Aucun PDF sélectionné")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
                
                if !service.pdfFiles.isEmpty {
                    GlassCard {
                        VStack(spacing: 16) {
                            SectionHeader(title: "Fusion", icon: "arrow.merge")
                            
                            HStack(spacing: 12) {
                                Text("\(service.pdfFiles.count) fichier(s) sélectionné(s)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                                
                                Spacer()
                                
                                PremiumButton(title: "Fusionner", icon: "checkmark", style: .success) {
                                    showSavePanel = true
                                }
                            }
                            
                            PremiumButton(title: "Effacer tout", icon: "trash", style: .danger) {
                                service.clearPDFs()
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .fileExporter(
            isPresented: $showSavePanel,
            document: PDFDocument(),
            contentType: .pdf,
            defaultFilename: "merged_document",
            onComplete: { result in
                switch result {
                case .success(let url):
                    service.mergePDFs(to: url)
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        )
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fusion PDF")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Combinez plusieurs PDFs en un seul")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "\(service.pdfFiles.count)", color: .orange)
            }
        }
    }
}

struct PDFFileRow: View {
    let url: URL
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appPrimary)
                .frame(width: 30)
            
            Image(systemName: "doc.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                Text(url.path)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appDanger)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .background(Color.appSurfaceLight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
