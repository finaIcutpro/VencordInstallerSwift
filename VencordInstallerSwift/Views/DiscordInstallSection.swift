import SwiftUI
import UniformTypeIdentifiers

struct DiscordInstallSection: View {
    @Bindable var viewModel: InstallerViewModel
    @State private var isImporterPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            installerSectionHeader("Discord Install")

            if viewModel.discords.isEmpty && viewModel.customPath == nil {
                Text("No Discord installs found in /Applications or ~/Applications.")
                    .foregroundStyle(.secondary)
            }

            Picker("Install", selection: $viewModel.selectedInstallID) {
                ForEach(viewModel.discords) { install in
                    Text(install.displayName).tag(Optional(install.id))
                }
            }
            .pickerStyle(.radioGroup)
            .onChange(of: viewModel.selectedInstallID) { _, _ in
                viewModel.customPath = nil
                viewModel.updateAutoPatchWatchTarget()
            }

            if let customPath = viewModel.customPath,
               let install = DiscordInstall.parse(at: customPath) {
                LabeledContent("Custom") {
                    Text(install.displayName)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Choose Custom Location…") {
                isImporterPresented = true
            }
        }
        .padding(16)
        .installerGlass()
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.applicationBundle],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.selectCustomLocation(url)
                }
            case .failure:
                break
            }
        }
    }
}

#Preview {
    ScrollView {
        DiscordInstallSection(viewModel: InstallerViewModel())
            .padding()
    }
}
