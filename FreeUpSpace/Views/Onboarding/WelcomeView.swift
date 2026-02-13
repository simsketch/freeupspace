import SwiftUI
import Permissions

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(PermissionManager.self) private var permissionManager
    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep {
        case welcome
        case permissions
        case scanning
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .welcome:
                welcomeContent
            case .permissions:
                PermissionSetupView(onContinue: {
                    step = .scanning
                    appState.completeOnboarding()
                })
            case .scanning:
                scanningContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "externaldrive.badge.minus")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)

            Text("FreeUpSpace")
                .font(.largeTitle.weight(.bold))

            Text("Reclaim disk space from developer tools,\ncaches, and build artifacts.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "shield.checkmark.fill", color: .green,
                           text: "Safety-first: items are classified by risk level")
                featureRow(icon: "terminal.fill", color: .orange,
                           text: "Shows the equivalent terminal command")
                featureRow(icon: "arrow.triangle.branch", color: .purple,
                           text: "Auto-detects your dev stack")
                featureRow(icon: "menubar.rectangle", color: .blue,
                           text: "Quick-clean from the menu bar")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                step = .permissions
            } label: {
                Text("Get Started")
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
                .frame(height: 40)
        }
        .padding()
    }

    private var scanningContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Running initial scan...")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.body)
        }
    }
}
