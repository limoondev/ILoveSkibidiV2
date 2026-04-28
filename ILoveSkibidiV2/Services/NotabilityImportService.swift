import Foundation
import AppKit
import UniformTypeIdentifiers

class NotabilityImportService: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var autoImport: Bool = false
    @Published var importCount: Int = 0
    @Published var lastImportDate: Date? = nil
    @Published var supportedFormats: [FileFormat] = []
    @Published var importHistory: [ImportRecord] = []
    
    static let shared = NotabilityImportService()
    
    struct FileFormat: Identifiable {
        let id = UUID()
        let name: String
        let utType: UTType
        let fileExtension: String
        let icon: String
    }
    
    struct ImportRecord: Identifiable {
        let id = UUID()
        let fileName: String
        let fileType: String
        let importDate: Date
        let success: Bool
        let fileSize: Int64
    }
    
    init() {
        loadSupportedFormats()
    }
    
    private func loadSupportedFormats() {
        supportedFormats = [
            FileFormat(name: "PDF", utType: .pdf, fileExtension: "pdf", icon: "doc.fill"),
            FileFormat(name: "Image PNG", utType: .png, fileExtension: "png", icon: "photo.fill"),
            FileFormat(name: "Image JPEG", utType: .jpeg, fileExtension: "jpg", icon: "photo.fill"),
            FileFormat(name: "Image TIFF", utType: .tiff, fileExtension: "tiff", icon: "photo.fill"),
            FileFormat(name: "Texte RTF", utType: .rtf, fileExtension: "rtf", icon: "doc.text.fill"),
            FileFormat(name: "Texte brut", utType: .plainText, fileExtension: "txt", icon: "doc.text"),
            FileFormat(name: "HTML", utType: .html, fileExtension: "html", icon: "globe"),
            FileFormat(name: "Markdown", utType: UTType(filenameExtension: "md") ?? .plainText, fileExtension: "md", icon: "text.append"),
        ]
    }
    
    func importToNotability(url: URL) -> Bool {
        guard isEnabled else { return false }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            registerImport(fileName: url.lastPathComponent, fileType: url.pathExtension, success: false, fileSize: 0)
            return false
        }
        
        let fileSize = getFileSize(url: url)
        
        if let notabilityURL = URL(string: "notability://import?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(notabilityURL)
            registerImport(fileName: url.lastPathComponent, fileType: url.pathExtension, success: true, fileSize: fileSize)
            return true
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if url.pathExtension == "pdf" {
            if let pdfData = try? Data(contentsOf: url) {
                pasteboard.setData(pdfData, forType: .pdf)
            }
        } else if ["png", "jpg", "jpeg", "tiff"].contains(url.pathExtension) {
            if let image = NSImage(contentsOf: url) {
                pasteboard.writeObjects([image])
            }
        } else {
            if let textData = try? Data(contentsOf: url) {
                pasteboard.setData(textData, forType: .fileURL)
            }
        }
        
        NSWorkspace.shared.open(URL(string: "notability://")!)
        
        registerImport(fileName: url.lastPathComponent, fileType: url.pathExtension, success: true, fileSize: fileSize)
        return true
    }
    
    func importToNotabilityViaShareSheet(url: URL) {
        let sourceWindow = NSApp.keyWindow
        let sharingPicker = NSSharingServicePicker(items: [url])
        sharingPicker.show(relativeTo: .zero, of: sourceWindow?.contentView ?? NSView(), preferredEdge: .minY)
    }
    
    func openFilePicker() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        var allowedTypes: [UTType] = [.pdf, .png, .jpeg, .tiff, .rtf, .plainText]
        if let mdType = UTType(filenameExtension: "md") {
            allowedTypes.append(mdType)
        }
        if let htmlType = UTType(filenameExtension: "html") {
            allowedTypes.append(htmlType)
        }
        panel.allowedContentTypes = allowedTypes
        
        let response = panel.runModal()
        if response == .OK {
            return panel.urls
        }
        return []
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return (attributes[.size] as? Int64) ?? 0
        } catch {
            return 0
        }
    }
    
    private func registerImport(fileName: String, fileType: String, success: Bool, fileSize: Int64) {
        DispatchQueue.main.async {
            let record = ImportRecord(
                fileName: fileName,
                fileType: fileType,
                importDate: Date(),
                success: success,
                fileSize: fileSize
            )
            self.importHistory.insert(record, at: 0)
            if self.importHistory.count > 50 {
                self.importHistory.removeLast()
            }
            if success {
                self.importCount += 1
                self.lastImportDate = Date()
            }
        }
    }
    
    func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func isNotabilityInstalled() -> Bool {
        let workspace = NSWorkspace.shared
        return workspace.urlForApplication(withBundleIdentifier: "com.gingerlabs.NotabilityMac") != nil
            || workspace.urlForApplication(withBundleIdentifier: "com.gingerlabs.Notability") != nil
    }
}
