import SwiftUI

@main
struct ILoveSkibidiV2App: App {
    @State private var isLoading = true
    
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
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 720)
    }
}
