import SwiftUI
import AppKit

@main
struct ILoveSkibidiV2App: App {
    @State private var isLoading = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingScreenView()
                        .transition(.opacity)
                } else {
                    MainView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: isLoading)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 720)
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "iloveskibidi" else { return }
        
        if url.host == "import" {
            // Handle file import from share extension
            if let urlString = url.queryParameters?["url"],
               let fileURL = URL(string: urlString) {
                // Process the imported file
                print("Importing file from share extension: \(fileURL)")
                // TODO: Navigate to appropriate view based on file type
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
