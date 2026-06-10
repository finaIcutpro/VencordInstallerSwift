import AppIntents
import Foundation

// MARK: - Entity

struct DiscordInstallEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Discord Install")
    static var defaultQuery = DiscordInstallQuery()

    var id: String
    var displayName: String
    var branch: String
    var isPatched: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(_ install: DiscordInstall) {
        id = install.id
        displayName = install.displayName
        branch = install.branch
        isPatched = install.isPatched
    }
}

struct DiscordInstallQuery: EntityQuery {
    func entities(for identifiers: [DiscordInstallEntity.ID]) async throws -> [DiscordInstallEntity] {
        DiscordDiscovery.findInstalls()
            .filter { identifiers.contains($0.id) }
            .map(DiscordInstallEntity.init)
    }

    func suggestedEntities() async throws -> [DiscordInstallEntity] {
        DiscordDiscovery.findInstalls().map(DiscordInstallEntity.init)
    }
}

enum InstallResolver {
    static func resolve(_ entity: DiscordInstallEntity?) throws -> DiscordInstall {
        let installs = DiscordDiscovery.findInstalls()

        if let entity {
            guard let install = installs.first(where: { $0.id == entity.id }) else {
                throw InstallerError.discordNotFound
            }
            return install
        }

        guard let first = installs.first else {
            throw InstallerError.discordNotFound
        }
        return first
    }
}

// MARK: - Intents

struct InstallVencordIntent: AppIntent {
    static var title: LocalizedStringResource = "Install Vencord"
    static var description = IntentDescription("Download and install Vencord on a Discord client.")

    @Parameter(title: "Discord", default: nil)
    var discord: DiscordInstallEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Install Vencord on \(\.$discord)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let install = try InstallResolver.resolve(discord)
        let updated = try await InstallerOperations.shared.install(install: install)
        return .result(dialog: "Installed Vencord on \(updated.displayName).")
    }
}

struct RepairVencordIntent: AppIntent {
    static var title: LocalizedStringResource = "Repair Vencord"
    static var description = IntentDescription("Re-download and re-apply Vencord on a Discord client.")

    @Parameter(title: "Discord", default: nil)
    var discord: DiscordInstallEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Repair Vencord on \(\.$discord)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let install = try InstallResolver.resolve(discord)
        let updated = try await InstallerOperations.shared.repair(install: install)
        return .result(dialog: "Repaired Vencord on \(updated.displayName).")
    }
}

struct UninstallVencordIntent: AppIntent {
    static var title: LocalizedStringResource = "Uninstall Vencord"
    static var description = IntentDescription("Remove Vencord and restore the original Discord app.asar.")

    @Parameter(title: "Discord", default: nil)
    var discord: DiscordInstallEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Uninstall Vencord from \(\.$discord)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let install = try InstallResolver.resolve(discord)
        let updated = try await InstallerOperations.shared.uninstall(install: install)
        return .result(dialog: "Uninstalled Vencord from \(updated.displayName).")
    }
}

struct GetVencordStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Vencord Status"
    static var description = IntentDescription("Check the latest and installed Vencord build hashes.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let status = await InstallerOperations.shared.status()
        let message = "Latest: \(status.latestHash)\nInstalled: \(status.installedHash)"
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

struct ListDiscordInstallsIntent: AppIntent {
    static var title: LocalizedStringResource = "List Discord Installs"
    static var description = IntentDescription("List Discord installs found on this Mac.")

    func perform() async throws -> some IntentResult & ReturnsValue<[DiscordInstallEntity]> & ProvidesDialog {
        let installs = DiscordDiscovery.findInstalls().map(DiscordInstallEntity.init)
        guard !installs.isEmpty else {
            return .result(
                value: [],
                dialog: "No Discord installs were found."
            )
        }
        let names = installs.map(\.displayName).joined(separator: "\n")
        return .result(value: installs, dialog: IntentDialog(stringLiteral: names))
    }
}

// MARK: - Shortcuts

struct VencordInstallerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: InstallVencordIntent(),
            phrases: [
                "Install Vencord with \(.applicationName)",
                "Patch Discord with \(.applicationName)",
            ],
            shortTitle: "Install Vencord",
            systemImageName: "arrow.down.circle"
        )
        AppShortcut(
            intent: RepairVencordIntent(),
            phrases: [
                "Repair Vencord with \(.applicationName)",
            ],
            shortTitle: "Repair Vencord",
            systemImageName: "wrench.and.screwdriver"
        )
        AppShortcut(
            intent: UninstallVencordIntent(),
            phrases: [
                "Uninstall Vencord with \(.applicationName)",
            ],
            shortTitle: "Uninstall Vencord",
            systemImageName: "trash"
        )
        AppShortcut(
            intent: GetVencordStatusIntent(),
            phrases: [
                "Get Vencord status with \(.applicationName)",
            ],
            shortTitle: "Vencord Status",
            systemImageName: "info.circle"
        )
    }
}
