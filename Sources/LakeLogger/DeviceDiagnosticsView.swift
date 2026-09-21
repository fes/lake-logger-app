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
                Button {
                    Task { await viewModel.triggerSelfTest() }
                } label: {
                    Label("Run RS-485 bridge self-test", systemImage: "waveform.path.ecg")
                }
                .disabled(viewModel.isRunningSelfTest)
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reboot device", systemImage: "power")
                }
                .disabled(viewModel.isResetting)
            }

            if viewModel.isLoading || viewModel.isResetting || viewModel.isRunningSelfTest {
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

            if let selfTest = viewModel.selfTest {
                selfTestSection(selfTest)
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

        Section("RS-485 bridge") {
            diagnosticRow("Modbus failures (total)", status.modbusFailureTotal.map(String.init))
            diagnosticRow("Solinst failures (consecutive)", status.consecutiveSolinstModbusFailures.map(String.init))
            diagnosticRow("Weather failures (consecutive)", status.consecutiveWeatherModbusFailures.map(String.init))
            diagnosticRow("Bridge recovery attempts", status.rs485BridgeRecoveryAttempts.map(String.init))
            diagnosticRow("Bridge recovery successes", status.rs485BridgeRecoverySuccesses.map(String.init))
            bridgeHealthRow(
                "Solinst channel",
                supported: status.rs485SolinstBridgeHealthSupported,
                overrun: status.rs485SolinstBridgeOverrunError,
                parity: status.rs485SolinstBridgeParityError,
                framing: status.rs485SolinstBridgeFramingError,
                breakDetected: status.rs485SolinstBridgeBreakDetected
            )
            bridgeHealthRow(
                "Weather channel",
                supported: status.rs485WeatherBridgeHealthSupported,
                overrun: status.rs485WeatherBridgeOverrunError,
                parity: status.rs485WeatherBridgeParityError,
                framing: status.rs485WeatherBridgeFramingError,
                breakDetected: status.rs485WeatherBridgeBreakDetected
            )
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
    private func selfTestSection(_ result: DeviceRs485SelfTestResult) -> some View {
        Section {
            selfTestRow("Solinst channel", supported: result.solinstSelftestSupported, passed: result.solinstSelftestPassed)
            selfTestRow("Weather channel", supported: result.weatherSelftestSupported, passed: result.weatherSelftestPassed)
        } header: {
            Text("RS-485 self-test result")
        } footer: {
            Text("An internal loopback test of the bridge/UART core, not the physical bus or sensors -- it can pass even with a sensor disconnected.")
        }
    }

    /// A single "channel: pass/fail" row for the self-test result, styled to
    /// stand out (green/red) since this is the one diagnostic that directly
    /// answers "is the shared bridge chip itself OK" independent of sensor
    /// wiring or the sensor's own responsiveness.
    private func selfTestRow(_ label: String, supported: Bool?, passed: Bool?) -> some View {
        HStack {
            Text(label)
            Spacer()
            if supported == false {
                Text("Not supported")
                    .foregroundStyle(.secondary)
            } else if let passed {
                Label(passed ? "Passed" : "Failed", systemImage: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(passed ? .green : .red)
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// A compact "no errors" / "flag list" row for continuous bridge
    /// line-status monitoring (distinct from the on-demand self-test above).
    private func bridgeHealthRow(
        _ label: String,
        supported: Bool?,
        overrun: Bool?,
        parity: Bool?,
        framing: Bool?,
        breakDetected: Bool?
    ) -> some View {
        let flags: [String] = [
            overrun == true ? "overrun" : nil,
            parity == true ? "parity" : nil,
            framing == true ? "framing" : nil,
            breakDetected == true ? "break" : nil,
        ].compactMap { $0 }

        return HStack {
            Text(label)
            Spacer()
            if supported == false {
                Text("Not supported")
                    .foregroundStyle(.secondary)
            } else if flags.isEmpty {
                Text("No errors")
                    .foregroundStyle(.secondary)
            } else {
                Text(flags.joined(separator: ", "))
                    .foregroundStyle(.orange)
            }
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
