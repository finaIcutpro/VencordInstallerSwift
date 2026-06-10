import SwiftUI

struct LoadingOverlay: View {
    let title: String
    let detail: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .installerGlass(interactive: true)
            .shadow(color: .black.opacity(0.1), radius: 20, y: 6)
        }
        .transition(.opacity)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        LoadingOverlay(title: "Repairing Vencord", detail: "Downloading latest builds…")
    }
    .frame(width: 480, height: 400)
}
