import SwiftUI
import CleanupEngine
import Permissions
import SharedUtilities

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(PermissionManager.self) private var permissionManager

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            permissionsTab
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }

    private var generalTab: some View {
        Form {
            Picker("Default deletion method:", selection: Binding(
                get: { appState.defaultDeletionMethod },
                set: { appState.updateDeletionMethod($0) }
            )) {
                Text("Move to Trash").tag(DeletionMethod.moveToTrash)
                Text("Permanent Delete").tag(DeletionMethod.permanentDelete)
            }

            Toggle("Launch at login", isOn: Binding(
                get: { appState.launchAtLogin },
                set: { newValue in
                    appState.launchAtLogin = newValue
                    UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
                }
            ))

            LabeledContent("node_modules stale after:") {
                Stepper(
                    "\(appState.nodeModulesStaleDays) days",
                    value: Binding(
                        get: { appState.nodeModulesStaleDays },
                        set: { appState.nodeModulesStaleDays = $0 }
                    ),
                    in: 7...365,
                    step: 7
                )
            }

            if appState.totalBytesFreedAllTime > 0 {
                LabeledContent("Total space freed:") {
                    Text(ByteFormatter.shared.formatPrecise(appState.totalBytesFreedAllTime))
                        .monospacedDigit()
                }

                LabeledContent("Cleanup sessions:") {
                    Text("\(appState.cleanupCount)")
                        .monospacedDigit()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var permissionsTab: some View {
        Form {
            LabeledContent("Full Disk Access:") {
                HStack {
                    Image(systemName: permissionManager.hasFullDiskAccess
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
                        .foregroundStyle(permissionManager.hasFullDiskAccess ? .green : .red)
                    Text(permissionManager.hasFullDiskAccess ? "Granted" : "Not Granted")

                    if !permissionManager.hasFullDiskAccess {
                        Button("Grant Access") {
                            permissionManager.openFullDiskAccessSettings()
                        }
                        .buttonStyle(.link)
                    }
                }
            }

            Button("Check Permissions") {
                permissionManager.checkFullDiskAccess()
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.minus")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("FreeUpSpace")
                .font(.title2.weight(.semibold))

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Free and open source disk cleanup for developers.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
