import SwiftUI

@main
struct VencordInstallerApp: App {
    @State private var viewModel = InstallerViewModel()

    var body: some Scene {
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
