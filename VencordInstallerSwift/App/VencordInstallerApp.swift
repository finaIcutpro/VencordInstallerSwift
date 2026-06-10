import SwiftUI

@main
struct VencordInstallerApp: App {
    @State private var viewModel = InstallerViewModel()

    @SceneBuilder
    var body: some Scene {
        if #available(macOS 26, *) {
            WindowGroup {
                NavigationStack {
                    ContentView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.load()
                }
            }
            .defaultSize(width: 480, height: 600)
            .windowToolbarStyle(.unified)
        } else {
            WindowGroup {
                NavigationStack {
                    ContentView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.load()
                }
            }
            .defaultSize(width: 480, height: 600)
        }
    }
}
