import Cocoa
import UniformTypeIdentifiers

class ShareViewController: NSViewController {
    
    override var nibName: NSNib.Name? {
        return "ShareViewController"
    }
    
    override func loadView() {
        super.loadView()
        // Setup your view here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the input items from the extension context
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            closeExtension()
            return
        }
        
        for item in extensionItems {
            if let attachments = item.attachments {
                handleAttachments(attachments)
            }
        }
    }
    
    private func handleAttachments(_ attachments: [NSItemProvider]) {
        for provider in attachments {
            // Handle different file types
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                loadItem(from: provider, typeIdentifier: UTType.pdf.identifier)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                loadItem(from: provider, typeIdentifier: UTType.image.identifier)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                loadItem(from: provider, typeIdentifier: UTType.text.identifier)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                loadItem(from: provider, typeIdentifier: UTType.url.identifier)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                loadItem(from: provider, typeIdentifier: UTType.data.identifier)
            }
        }
    }
    
    private func loadItem(from provider: NSItemProvider, typeIdentifier: String) {
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading item: \(error)")
                DispatchQueue.main.async {
                    self.closeExtension()
                }
                return
            }
            
            // Handle the loaded item
            if let url = item as? URL {
                self.handleURL(url)
            } else if let data = item as? Data {
                self.handleData(data, typeIdentifier: typeIdentifier)
            } else if let string = item as? String {
                self.handleText(string)
            }
            
            DispatchQueue.main.async {
                self.closeExtension()
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        // Save the file to a temporary location or open with main app
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.copyItem(at: url, to: destinationURL)
                    
                    // Open the main app with the file
                    self.openMainApp(with: destinationURL)
                }
            }
        } catch {
            print("Error copying file: \(error)")
        }
    }
    
    private func handleData(_ data: Data, typeIdentifier: String) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        var fileExtension = "dat"
        if typeIdentifier == UTType.pdf.identifier {
            fileExtension = "pdf"
        } else if typeIdentifier == UTType.image.identifier {
            fileExtension = "png"
        } else if typeIdentifier == UTType.text.identifier {
            fileExtension = "txt"
        }
        
        let filename = "shared_\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
        let destinationURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: destinationURL)
            openMainApp(with: destinationURL)
        } catch {
            print("Error writing data: \(error)")
        }
    }
    
    private func handleText(_ text: String) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let filename = "shared_\(Int(Date().timeIntervalSince1970)).txt"
        let destinationURL = tempDir.appendingPathComponent(filename)
        
        do {
            try text.write(to: destinationURL, atomically: true, encoding: .utf8)
            openMainApp(with: destinationURL)
        } catch {
            print("Error writing text: \(error)")
        }
    }
    
    private func openMainApp(with url: URL) {
        // Use URL scheme to open main app with the file
        let appURL = URL(string: "iloveskibidi://import?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        if let appURL = appURL {
            NSWorkspace.shared.open(appURL)
        }
    }
    
    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
