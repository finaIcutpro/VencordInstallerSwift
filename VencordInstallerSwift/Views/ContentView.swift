import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: InstallerViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                securityNotice

                if PermissionDiagnostics.runningFromTransientLocation() {
                    transientLocationWarning
                }

                DiscordInstallSection(viewModel: viewModel)

                vencordSection

                autoPatchSection
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(windowBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .frame(minWidth: 480, minHeight: 520)
        .navigationTitle("Vencord Installer")
        .disabled(viewModel.isWorking || viewModel.isAutoPatching)
        .overlay {
            if viewModel.isWorking || viewModel.isAutoPatching {
                LoadingOverlay(
                    title: viewModel.workingTitle,
                    detail: viewModel.workingDetail
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isWorking || viewModel.isAutoPatching)
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

    private var windowBackground: some View {
        Group {
            if #available(macOS 26, *) {
                Color.clear
                    .background(.thinMaterial)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .ignoresSafeArea()
    }

    private var securityNotice: some View {
        Label {
            (Text("Only download Vencord from ")
                + Text("GitHub").bold()
                + Text(" or ")
                + Text("vencord.dev").bold()
                + Text(". Other sites claiming to be us are malicious."))
                .font(.callout)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .installerGlass()
    }

    private var transientLocationWarning: some View {
        Label {
            Text("This copy was launched from Xcode or DerivedData. macOS permission toggles won't stick — install the release app to /Applications instead.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .installerGlass()
    }

    private var vencordSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            installerSectionHeader("Vencord")

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
        }
        .padding(16)
        .installerGlass()
    }

    private var autoPatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            installerSectionHeader("Auto-patch")

            Toggle("Re-patch when Discord updates", isOn: Binding(
                get: { viewModel.autoRepatchEnabled },
                set: { viewModel.setAutoRepatchEnabled($0) }
            ))

            Toggle("Relaunch Discord after auto-patch", isOn: Binding(
                get: { viewModel.autoRelaunchDiscord },
                set: { viewModel.setAutoRelaunchDiscord($0) }
            ))
            .disabled(!viewModel.autoRepatchEnabled)

            Toggle("Launch at login", isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
            .disabled(!viewModel.autoRepatchEnabled)

            Text("Watches the selected Discord install for updates. When Discord replaces app.asar, the installer quits Discord, re-patches, and optionally relaunches it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .installerGlass()
    }

    @ViewBuilder
    private var actionBar: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 10) {
                actionBarContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            actionBarContent
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
        }
    }

    private var actionBarContent: some View {
        HStack(spacing: 10) {
            installerActionButton("Install", prominent: true) { viewModel.install() }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.selectedInstall == nil)

            installerActionButton("Repair") { viewModel.repair() }
                .disabled(viewModel.selectedInstall == nil)

            installerActionButton("Uninstall") { viewModel.uninstall() }
                .disabled(viewModel.selectedInstall == nil)

            Spacer()

            installerActionButton(
                viewModel.isOpenAsarInstalled ? "Remove OpenAsar" : "Install OpenAsar"
            ) {
                viewModel.toggleOpenAsar()
            }
            .disabled(viewModel.selectedInstall == nil)
        }
    }
}

#Preview {
    NavigationStack {
        ContentView(viewModel: InstallerViewModel())
    }
}
