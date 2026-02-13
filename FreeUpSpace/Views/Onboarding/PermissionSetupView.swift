import SwiftUI
import Permissions

struct PermissionSetupView: View {
    @Environment(PermissionManager.self) private var permissionManager
    let onContinue: () -> Void
    @State private var checkTimer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: permissionManager.hasFullDiskAccess
                  ? "checkmark.shield.fill"
                  : "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(permissionManager.hasFullDiskAccess ? .green : .orange)
                .symbolRenderingMode(.hierarchical)
                .contentTransition(.symbolEffect(.replace))

            Text("Full Disk Access")
                .font(.title.weight(.semibold))

            Text("FreeUpSpace needs Full Disk Access to scan all\ncaches and developer tool data on your Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if permissionManager.hasFullDiskAccess {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3.weight(.medium))
            } else {
                VStack(spacing: 12) {
                    Text("1. Click \"Open System Settings\" below\n2. Enable FreeUpSpace in the Full Disk Access list\n3. Return to this window")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 350)

                    Button {
                        permissionManager.openFullDiskAccessSettings()
                    } label: {
                        Label("Open System Settings", systemImage: "gear")
                            .frame(maxWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            Spacer()

            HStack {
                if !permissionManager.hasFullDiskAccess {
                    Button("Skip for now") {
                        onContinue()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!permissionManager.hasFullDiskAccess)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .padding()
        .onAppear {
            // Poll for permission changes
            checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                permissionManager.checkFullDiskAccess()
            }
        }
        .onDisappear {
            checkTimer?.invalidate()
        }
    }
}
