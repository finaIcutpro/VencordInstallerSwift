import SwiftUI

enum InstallerGlass {
    static let cornerRadius: CGFloat = 14
    static let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
}

extension View {
    @ViewBuilder
    func installerGlass(interactive: Bool = false) -> some View {
        if #available(macOS 26, *) {
            glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: InstallerGlass.shape
            )
        } else {
            background(.regularMaterial, in: InstallerGlass.shape)
        }
    }

    @ViewBuilder
    func installerSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

@ViewBuilder
func installerActionButton(_ title: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
    if #available(macOS 26, *) {
        Button(title, action: action)
            .buttonStyle(prominent ? .glassProminent : .glass)
    } else {
        Button(title, action: action)
            .buttonStyle(prominent ? .borderedProminent : .bordered)
    }
}
