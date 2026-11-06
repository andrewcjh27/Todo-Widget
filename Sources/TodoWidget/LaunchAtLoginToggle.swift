import ServiceManagement
import SwiftUI

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(
                "Launch at login",
                isOn: Binding(get: { isEnabled }, set: { setEnabled($0) })
            )
            .toggleStyle(.checkbox)
            .font(.caption)

            if SMAppService.mainApp.status == .requiresApproval {
                Button("Allow in System Settings") {
                    SMAppService.openSystemSettingsLoginItems()
                }
                .buttonStyle(.link)
                .font(.caption)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    private func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't update this setting. Move the app to Applications and try again."
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
