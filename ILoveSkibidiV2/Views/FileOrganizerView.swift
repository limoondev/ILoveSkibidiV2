import SwiftUI

struct FileOrganizerView: View {
    @StateObject private var service = FileOrganizerService.shared
    @State private var showDirectoryPicker = false
    @State private var selectedDirectory: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                GlassCard {
                    VStack(spacing: 16) {
                        SectionHeader(title: "Dossier à organiser", icon: "folder")
                        
                        if let directory = selectedDirectory {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.appAccent)
                                Text(directory.path)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { selectedDirectory = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.appDanger)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(12)
                            .background(Color.appSurfaceLight.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.appTextSecondary.opacity(0.5))
                                Text("Sélectionnez un dossier")
                                    .font(.system(size: 14))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.appSurfaceLight.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        PremiumButton(title: "Sélectionner un dossier", icon: "folder.open", style: .primary) {
                            showDirectoryPicker = true
                        }
                    }
                }
                
                if let directory = selectedDirectory {
                    GlassCard {
                        VStack(spacing: 16) {
                            SectionHeader(title: "Organisation", icon: "arrow.triangle.2.circlepath")
                            
                            if service.isProcessing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                                    Text("Analyse en cours...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.appTextSecondary)
                                }
                                .padding(.vertical, 20)
                            } else if !service.organizedFolders.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(service.organizedFolders) { folder in
                                        OrganizedFolderCard(folder: folder)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                PremiumButton(title: "Analyser", icon: "magnifyingglass", style: .secondary) {
                                    service.organizeFiles(in: directory)
                                }
                                
                                PremiumButton(title: "Organiser", icon: "folder.fill.badge.plus", style: .success) {
                                    let destination = directory.deletingLastPathComponent()
                                    service.moveFilesToOrganizedFolders(sourceDirectory: directory, destinationDirectory: destination)
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .fileImporter(
            isPresented: $showDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDirectory = url
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
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Organisateur de fichiers")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    Text("Organisez automatiquement vos fichiers")
                        .font(.system(size: 14))
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                StatusBadge(text: "AUTO", color: .blue)
            }
        }
    }
}

struct OrganizedFolderCard: View {
    let folder: FileOrganizerService.OrganizedFolder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: folder.category.icon)
                .font(.system(size: 24))
                .foregroundColor(folder.category.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                Text("\(folder.files.count) fichier(s)")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            StatusBadge(text: "\(folder.files.count)", color: folder.category.color)
        }
        .padding(12)
        .background(folder.category.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(folder.category.color.opacity(0.3), lineWidth: 1)
        )
    }
}
