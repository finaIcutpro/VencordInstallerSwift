import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: InstallerViewModel

    var body: some View {
        Form {
            Section {
                Label {
                    (Text("Only download Vencord from ")
                        + Text("GitHub").bold()
                        + Text(" or ")
                        + Text("vencord.dev").bold()
                        + Text(". Other sites claiming to be us are malicious."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if PermissionDiagnostics.runningFromTransientLocation() {
                Section {
                    Label {
                        Text("This copy was launched from Xcode or DerivedData. macOS permission toggles won't stick — install the release app to /Applications instead.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            DiscordInstallSection(viewModel: viewModel)

            Section {
                LabeledContent("Installed") {
                    Text(viewModel.installedHash)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }

                LabeledContent("Latest") {
                    Text(viewModel.latestHash)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }

                if let error = viewModel.vencordDataError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            } header: {
                Text("Vencord")
            }

        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .frame(minWidth: 480, minHeight: 420)
        .navigationTitle("Vencord Installer")
        .disabled(viewModel.isWorking)
        .overlay {
            if viewModel.isWorking {
                LoadingOverlay(
                    title: viewModel.workingTitle,
                    detail: viewModel.workingDetail
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isWorking)
        .alert(item: $viewModel.activeAlert) { alert in
            switch alert {
            case .openAsarConfirm:
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Continue")) {
                        viewModel.confirmOpenAsarInstall()
                    },
                    secondaryButton: .cancel()
                )
            case .success(let title, let message):
                Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
            case .permissionRequired(let message):
                Alert(
                    title: Text("Permission Required"),
                    message: Text(message),
                    primaryButton: .default(Text("Open Full Disk Access")) {
                        SystemSettingsOpener.openFullDiskAccess()
                    },
                    secondaryButton: .default(Text("App Management")) {
                        SystemSettingsOpener.openAppManagement()
                    }
                )
            case .error(let title, let message):
                Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("Install") { viewModel.install() }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.selectedInstall == nil)

            Button("Repair") { viewModel.repair() }
                .disabled(viewModel.selectedInstall == nil)

            Button("Uninstall") { viewModel.uninstall() }
                .disabled(viewModel.selectedInstall == nil)

            Spacer()

            Button(viewModel.isOpenAsarInstalled ? "Remove OpenAsar" : "Install OpenAsar") {
                viewModel.toggleOpenAsar()
            }
            .disabled(viewModel.selectedInstall == nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

#Preview {
    ContentView(viewModel: InstallerViewModel())
}
