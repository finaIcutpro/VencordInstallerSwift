import SwiftUI

struct LoadingOverlay: View {
    let title: String
    let detail: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        }
        .transition(.opacity)
    }
}

#Preview {
    ZStack {
        Form { Text("Content behind overlay") }
        LoadingOverlay(title: "Repairing Vencord", detail: "Downloading latest builds…")
    }
    .frame(width: 480, height: 400)
}
