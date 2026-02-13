import SwiftUI
import CleanupEngine

struct MainView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationSplitView {
            SidebarView()
        } detail: {
            if appState.showSystemDataView {
                SystemDataView()
            } else if let categoryId = appState.selectedCategoryId,
                      let category = appState.categories.first(where: { $0.id == categoryId }) {
                CategoryDetailView(category: category)
            } else {
                DashboardView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if appState.isScanning {
                    ProgressView()
                        .controlSize(.small)
                    Button("Cancel") {
                        appState.cancelScan()
                    }
                } else {
                    Button {
                        appState.startScan()
                    } label: {
                        Label("Rescan", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if appState.categories.isEmpty && !appState.isScanning {
                appState.startScan()
            }
        }
    }
}
