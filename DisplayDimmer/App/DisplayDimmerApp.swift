import SwiftUI
import AppKit
import Combine

@main
struct DisplayDimmer: App {

    @StateObject private var displayManager = DisplayManager()
    @StateObject private var dimmer = DimmerController()
    @StateObject private var launchAtLogin = LaunchAtLoginManager()
    @StateObject private var brightnessStore = BrightnessStore()

    // MARK: - Reapply Brightness

    private func reapplyBrightness(after delay: Double = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {

            displayManager.refreshDisplays()

            for display in displayManager.displays where !display.isBuiltIn {

                let savedBrightness =
                    brightnessStore.brightness(for: display)

                dimmer.setBrightness(
                    savedBrightness,
                    for: display.id
                )
            }
        }
    }

    // MARK: - App

    var body: some Scene {

        MenuBarExtra(
            "DisplayDimmer",
            systemImage: "display"
        ) {

            VStack(alignment: .leading, spacing: 14) {

                // MARK: Header

                HStack {

                    Image(systemName: "display")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {

                        Text("DisplayDimmer")
                            .font(.headline)

                        Text("External display dimming")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // MARK: External Displays

                let externalDisplays =
                    displayManager.displays.filter { !$0.isBuiltIn }

                if externalDisplays.isEmpty {

                    HStack(spacing: 8) {

                        Image(
                            systemName:
                                "display.trianglebadge.exclamationmark"
                        )

                        Text("No external display found")
                            .foregroundStyle(.secondary)
                    }

                } else {

                    ForEach(externalDisplays, id: \.id) { display in

                        VStack(alignment: .leading, spacing: 10) {

                            // Display name + percentage

                            HStack {

                                Image(systemName: "display")

                                Text(display.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                Text(
                                    "\(Int(brightnessStore.brightness(for: display) * 100))%"
                                )
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }

                            // Brightness slider

                            HStack(spacing: 10) {

                                Image(systemName: "sun.min")
                                    .foregroundStyle(.secondary)

                                Slider(
                                    value: Binding(
                                        get: {
                                            brightnessStore.brightness(
                                                for: display
                                            )
                                        },
                                        set: { newValue in

                                            brightnessStore.setBrightness(
                                                newValue,
                                                for: display
                                            )

                                            dimmer.setBrightness(
                                                newValue,
                                                for: display.id
                                            )
                                        }
                                    ),
                                    in: 0.20...1.0
                                )

                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(.secondary)
                            }

                            // Reset

                            HStack {

                                Spacer()

                                Button {

                                    dimmer.reset(
                                        displayID: display.id
                                    )

                                    brightnessStore.reset(
                                        for: display
                                    )

                                } label: {
                                    Label(
                                        "Reset",
                                        systemImage: "arrow.counterclockwise"
                                    )
                                }
                            }
                        }
                    }
                }

                Divider()

                // MARK: Launch at Login

                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: {
                            launchAtLogin.isEnabled
                        },
                        set: { newValue in
                            launchAtLogin.setEnabled(newValue)
                        }
                    )
                )

                if let error = launchAtLogin.errorMessage {

                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                // MARK: Bottom Controls

                HStack {

                    Button {
                        reapplyBrightness(after: 0)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Displays")

                    Spacer()

                    Button("Quit DisplayDimmer") {

                        dimmer.resetAll()

                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(16)
            .frame(width: 300)

            // MARK: App Lifecycle

            .onAppear {
                reapplyBrightness(after: 0.2)
            }

            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSApplication.didChangeScreenParametersNotification
                )
            ) { _ in

                reapplyBrightness(after: 0.5)
            }

            .onReceive(
                NSWorkspace.shared.notificationCenter.publisher(
                    for: NSWorkspace.didWakeNotification
                )
            ) { _ in

                reapplyBrightness(after: 1.0)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
