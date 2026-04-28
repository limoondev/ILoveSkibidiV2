import Foundation
import AppKit
import SwiftUI

enum FileCategory: String, CaseIterable {
    case documents = "Documents"
    case images = "Images"
    case videos = "Vidéos"
    case audio = "Audio"
    case archives = "Archives"
    case other = "Autres"
    
    var icon: String {
        switch self {
        case .documents: return "doc.text"
        case .images: return "photo"
        case .videos: return "video"
        case .audio: return "music.note"
        case .archives: return "archivebox"
        case .other: return "folder"
        }
    }
    
    var color: Color {
        switch self {
        case .documents: return .blue
        case .images: return .green
        case .videos: return .purple
        case .audio: return .orange
        case .archives: return .brown
        case .other: return .gray
        }
    }
}

class FileOrganizerService: ObservableObject {
    @Published var organizedFolders: [OrganizedFolder] = []
    @Published var isProcessing = false
    
    static let shared = FileOrganizerService()
    
    struct OrganizedFolder: Identifiable {
        let id = UUID()
        let name: String
        let files: [URL]
        let category: FileCategory
    }
    
    func organizeFiles(in directory: URL) {
        isProcessing = true
        organizedFolders.removeAll()
        
        let fileManager = FileManager.default
        var categorizedFiles: [FileCategory: [URL]] = [:]
        
        if let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files {
                let category = categorizeFile(file)
                if categorizedFiles[category] == nil {
                    categorizedFiles[category] = []
                }
                categorizedFiles[category]?.append(file)
            }
        }
        
        for (category, files) in categorizedFiles {
            let folder = OrganizedFolder(
                name: category.rawValue,
                files: files,
                category: category
            )
            organizedFolders.append(folder)
        }
        
        isProcessing = false
    }
    
    private func categorizeFile(_ url: URL) -> FileCategory {
        let ext = url.pathExtension.lowercased()
        
        let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "pages", "key"]
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v"]
        let audioExtensions = ["mp3", "wav", "aac", "m4a", "flac"]
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz"]
        
        if documentExtensions.contains(ext) { return .documents }
        if imageExtensions.contains(ext) { return .images }
        if videoExtensions.contains(ext) { return .videos }
        if audioExtensions.contains(ext) { return .audio }
        if archiveExtensions.contains(ext) { return .archives }
        
        return .other
    }
    
    func moveFilesToOrganizedFolders(sourceDirectory: URL, destinationDirectory: URL) {
        let fileManager = FileManager.default
        
        for folder in organizedFolders {
            let destFolder = destinationDirectory.appendingPathComponent(folder.name)
            
            try? fileManager.createDirectory(at: destFolder, withIntermediateDirectories: true)
            
            for file in folder.files {
                let destFile = destFolder.appendingPathComponent(file.lastPathComponent)
                try? fileManager.moveItem(at: file, to: destFile)
            }
        }
    }
    
    func clearOrganization() {
        organizedFolders.removeAll()
    }
}

extension Color {
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
}
