import Foundation

@MainActor
final class DeviceDiagnosticsViewModel: ObservableObject {
    @Published var ipAddress: String
    @Published private(set) var status: DeviceStatus?
    @Published private(set) var probe: DeviceProbeReading?
    @Published private(set) var isLoading = false
    @Published private(set) var isResetting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastCheckedAt: Date?

    /// Raw JSON text from the device's own responses, kept alongside the
    /// decoded models so an exported report includes every field the
    /// firmware returns -- not just the subset this app's UI displays.
    private var lastStatusRawJSON: String?
    private var lastProbeRawJSON: String?
    private var lastErrorContext: String?

    private let api = DeviceApiClient()

    init() {
        ipAddress = DeviceSettingsStore.loadIPAddress() ?? ""
    }

    func saveAddress() {
        DeviceSettingsStore.saveIPAddress(ipAddress)
    }

    func refreshStatus() async {
        saveAddress()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let (value, rawJSON) = try await api.fetchStatus()
            status = value
            lastStatusRawJSON = rawJSON
            lastCheckedAt = Date()
        } catch {
            status = nil
            errorMessage = error.localizedDescription
            lastErrorContext = "GET /status failed: \(error)"
        }
    }

    func triggerProbe() async {
        saveAddress()
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let (value, rawJSON) = try await api.fetchProbe()
            probe = value
            lastProbeRawJSON = rawJSON
            lastCheckedAt = Date()
        } catch {
            probe = nil
            errorMessage = error.localizedDescription
            lastErrorContext = "GET /probe failed: \(error)"
        }
    }

    func rebootDevice() async {
        saveAddress()
        isResetting = true
        errorMessage = nil
        defer { isResetting = false }

        do {
            try await api.reset()
            status = nil
            probe = nil
            lastStatusRawJSON = nil
            lastProbeRawJSON = nil
        } catch {
            errorMessage = error.localizedDescription
            lastErrorContext = "GET /reset failed: \(error)"
        }
    }

    /// Builds a plain-text diagnostic report -- app/device metadata plus the
    /// full raw `/status` and `/probe` JSON last fetched -- formatted so a
    /// user can paste it directly into an AI assistant (Copilot, ChatGPT,
    /// etc.) or a support ticket without needing to screenshot anything.
    var diagnosticsReportText: String {
        var lines: [String] = []
        lines.append("Lake Logger device diagnostics report")
        lines.append("Generated: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Device address: \(ipAddress.isEmpty ? "(not set)" : ipAddress)")
        if let lastCheckedAt {
            lines.append("Last successful check: \(ISO8601DateFormatter().string(from: lastCheckedAt))")
        }
        if let errorMessage {
            lines.append("Most recent error: \(errorMessage)")
        }
        if let lastErrorContext {
            lines.append("Error context: \(lastErrorContext)")
        }

        lines.append("")
        lines.append("--- /status ---")
        lines.append(lastStatusRawJSON ?? "(not fetched yet)")

        lines.append("")
        lines.append("--- /probe ---")
        lines.append(lastProbeRawJSON ?? "(not fetched yet)")

        return lines.joined(separator: "\n")
    }

    var hasReportContent: Bool {
        lastStatusRawJSON != nil || lastProbeRawJSON != nil || errorMessage != nil
    }
}
