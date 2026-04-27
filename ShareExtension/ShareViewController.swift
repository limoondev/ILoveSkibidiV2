import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: NSViewController {
    override func loadView() {
        let hostingView = NSHostingView(rootView: ShareExtensionView())
        self.view = hostingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

struct ShareExtensionView: View {
    @State private var isImporting = false
    @State private var importSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.appPrimary, .appAccent], startPoint: .top, endPoint: .bottom))
            
            Text("ILoveSkibidi V2")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.appGradientHorizontal)
            
            Text("Importer dans Notability")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
            
            PremiumButton(title: "Importer", icon: "square.and.arrow.down") {
                importToNotability()
            }
            .frame(width: 200)
            
            if importSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appSuccess)
                    Text("Importé avec succès !")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSuccess)
                }
            }
        }
        .padding(30)
        .frame(width: 300, height: 250)
        .background(Color.appBackground)
    }
    
    private func importToNotability() {
        isImporting = true
        guard let extensionContext = (NSApplication.shared.delegate as? AppDelegate)?.extensionContext else {
            isImporting = false
            return
        }
        
        if let url = URL(string: "notability://") {
            NSWorkspace.shared.open(url)
            importSuccess = true
        }
        isImporting = false
    }
}
