import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Lets the user talk directly to the logger device over the local
/// network (bypassing the feslabs.com cloud entirely), for diagnosing
/// issues like a stalled upload schedule even when the phone has no
/// internet connectivity but is on the same Wi-Fi as the device.
struct DeviceDiagnosticsView: View {
    @StateObject private var viewModel = DeviceDiagnosticsViewModel()
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            Section("Device address") {
                TextField("e.g. 10.2.12.247", text: $viewModel.ipAddress)
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit { viewModel.saveAddress() }

                Text("Only reachable when your phone is on the same local Wi-Fi network as the logger.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    Task { await viewModel.refreshStatus() }
                } label: {
                    Label("Check device status", systemImage: "arrow.clockwise")
                }
                Button {
                    Task { await viewModel.triggerProbe() }
                } label: {
                    Label("Trigger live sensor probe", systemImage: "bolt.horizontal.circle")
                }
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reboot device", systemImage: "power")
                }
                .disabled(viewModel.isResetting)
            }

            if viewModel.isLoading || viewModel.isResetting {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            if let status = viewModel.status {
                statusSection(status)
            }

            if let probe = viewModel.probe {
                probeSection(probe)
            }

            if viewModel.hasReportContent {
                exportSection
            }
        }
        .navigationTitle("Device Diagnostics")
        .alert("Reboot logger device?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reboot", role: .destructive) {
                Task { await viewModel.rebootDevice() }
            }
        } message: {
            Text("This will power-cycle the physical device. Any unsent readings are kept in its local backlog, so this is safe.")
        }
    }

    @ViewBuilder
    private func statusSection(_ status: DeviceStatus) -> some View {
        Section("Connectivity") {
            diagnosticRow("Site health", status.siteHealth)
            diagnosticRow("Wi-Fi RSSI", status.wifiRssiDbm.map { "\($0) dBm" })
            diagnosticRow("Uptime", LakeFormat.relativeDuration(status.uptimeS))
            diagnosticRow("Last reset reason", status.lastSystemResetReason)
        }

        Section("Clock / NTP") {
            diagnosticRow("Clock valid", status.clockValid.map { $0 ? "Yes" : "No" })
            diagnosticRow("Last NTP sync", status.lastNtpSyncAge)
            diagnosticRow("Last sync delta", status.ntpSyncDeltaSeconds.map { "\($0) s" })
            diagnosticRow("Largest observed skew", status.ntpLargestObservedSkewSeconds.map { "\($0) s" })
            diagnosticRow("NTP failures (consecutive)", status.consecutiveNtpFailures.map(String.init))
        }

        Section("Upload / probe schedule") {
            diagnosticRow("Last successful upload", status.lastSuccessfulUploadAge)
            diagnosticRow("Last upload error", status.lastUploadError?.isEmpty == false ? status.lastUploadError : "None")
            diagnosticRow("Upload failures (consecutive)", status.consecutiveUploadFailures.map(String.init))
            diagnosticRow("Backlog (unsent readings)", status.backlogCount.map(String.init))
            diagnosticRow("Last successful probe", status.lastSuccessfulProbeReadAge)
        }

        Section("Sensors / power") {
            diagnosticRow("Sensor found", status.sensorFound.map { $0 ? "Yes" : "No" })
            diagnosticRow("Battery voltage", LakeFormat.volts(status.cachedProbeBatteryOutputVoltageV))
            diagnosticRow("Solar voltage", LakeFormat.volts(status.cachedProbeSolarInputVoltageV))
            diagnosticRow("Battery charge", LakeFormat.percent(status.batteryChargeLevelPctApprox))
        }
    }

    @ViewBuilder
    private func probeSection(_ probe: DeviceProbeReading) -> some View {
        Section("Live probe result") {
            diagnosticRow("Timestamp (device UTC)", probe.timestampUtc)
            diagnosticRow("Water level", LakeFormat.meters(probe.waterLevelM))
            diagnosticRow("Water temperature", LakeFormat.celsius(probe.temperatureC))
            diagnosticRow("Air temperature", LakeFormat.celsius(probe.weatherAirTemperatureC))
            diagnosticRow("Humidity", LakeFormat.percent(probe.weatherRelativeHumidityPct))
        }
    }

    @ViewBuilder
    private var exportSection: some View {
        Section {
            ShareLink(
                item: viewModel.diagnosticsReportText,
                preview: SharePreview("Lake Logger device diagnostics")
            ) {
                Label("Share report…", systemImage: "square.and.arrow.up")
            }

            Button {
                #if os(iOS)
                UIPasteboard.general.string = viewModel.diagnosticsReportText
                #endif
            } label: {
                Label("Copy report to clipboard", systemImage: "doc.on.doc")
            }
        } header: {
            Text("Export")
        } footer: {
            Text("Includes the full raw response from the device (not just the fields shown above) plus any recent errors -- paste this into Copilot, ChatGPT, or a support message for help diagnosing an issue.")
        }
    }

    private func diagnosticRow(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value ?? "—")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        DeviceDiagnosticsView()
    }
}
