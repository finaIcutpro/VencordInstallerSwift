import SwiftUI
import UniformTypeIdentifiers

struct DiscordInstallSection: View {
    @Bindable var viewModel: InstallerViewModel
    @State private var isImporterPresented = false

    var body: some View {
        Section("Discord Install") {
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
    Form {
        DiscordInstallSection(viewModel: InstallerViewModel())
    }
    .padding()
}
