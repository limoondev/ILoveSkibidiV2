import SwiftUI

struct ImageToTextView: View {
    @StateObject private var service = ImageToTextService.shared
    @State private var selectedImage: NSImage?
    @State private var showFilePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Image", icon: "photo")
                        
                        if let image = selectedImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 8)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.appTextSecondary.opacity(0.5))
                                Text("Sélectionnez une image")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.appSurfaceLight.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        PremiumButton(title: "Sélectionner une image", icon: "photo.on.rectangle", style: .primary) {
                            showFilePicker = true
                        }
                    }
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Texte extrait", icon: "text.bubble")
                        
                        if service.isProcessing {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                                Text("Extraction en cours...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding(.vertical, 20)
                        } else if !service.extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Confiance: \(Int(service.confidence * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(service.confidence > 0.8 ? .appSuccess : .appWarning)
                                    
                                    Spacer()
                                    
                                    Button(action: { service.copyToClipboard() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 11))
                                            Text("Copier")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .foregroundColor(.appPrimary)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                                
                                ScrollView {
                                    Text(service.extractedText)
                                        .font(.system(size: 13))
                                        .foregroundColor(.appTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxHeight: 200)
                                .padding(12)
                                .background(Color.appSurfaceLight)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        } else {
                            Text("Aucun texte extrait")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
            }
            .padding(24)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let image = NSImage(contentsOf: url) {
                    selectedImage = image
                    service.extractText(from: image)
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "text.bubble")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image vers Texte")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Extrayez le texte de vos images")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "OCR", color: .purple)
            }
        }
    }
}
