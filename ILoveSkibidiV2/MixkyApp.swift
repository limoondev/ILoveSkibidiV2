import SwiftUI
import AppKit

@main
struct MixkyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 720)
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "mixky" else { return }
        
        if url.host == "import" {
            // Handle file import from share extension
            if let urlString = url.queryParameters?["url"],
               let fileURL = URL(string: urlString) {
                // Process the imported file
                print("Importing file from share extension: \(fileURL)")
                NotabilityImportService.shared.importFile(from: fileURL)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions if needed
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            let alert = NSAlert()
            alert.messageText = "Permissions d'accessibilité requises"
            alert.informativeText = "Pour utiliser le correcteur global, veuillez accorder les permissions d'accessibilité dans les préférences système."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Ouvrir les préférences")
            alert.addButton(withTitle: "Plus tard")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        
        // Start the background corrector if enabled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if TextCorrectionService.shared.isEnabled {
                TextCorrectionService.shared.startGlobalCorrection()
            }
        }
    }
}

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return nil }
        
        return queryItems.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }
}
