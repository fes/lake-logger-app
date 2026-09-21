import Foundation

/// Persists the logger device's local-network IP address (e.g.
/// "10.2.12.247"), entered once by the user, so the app can talk to it
/// directly over the LAN without needing mDNS/Bonjour support (the device
/// firmware does not currently advertise itself).
enum DeviceSettingsStore {
    private static let ipAddressKey = "deviceLocalIPAddress"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedReadingCache.appGroupId)
    }

    static func loadIPAddress() -> String? {
        defaults?.string(forKey: ipAddressKey)
    }

    static func saveIPAddress(_ address: String?) {
        let trimmed = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            defaults?.set(trimmed, forKey: ipAddressKey)
        } else {
            defaults?.removeObject(forKey: ipAddressKey)
        }
    }
}

enum DeviceApiError: LocalizedError {
    case noAddressConfigured
    case invalidAddress
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .noAddressConfigured:
            return "Enter the logger's local network IP address first."
        case .invalidAddress:
            return "That doesn't look like a valid IP address or hostname."
        case .invalidResponse:
            return "The device returned an unexpected response."
        case .httpStatus(let code):
            return "The device returned HTTP \(code)."
        case .decodingFailed:
            return "Could not understand the device's response."
        case .transport(let error):
            return "Couldn't reach the device: \(error.localizedDescription). Make sure your phone is on the same Wi-Fi network as the logger."
        }
    }
}

/// Thin client for the logger device's own local HTTP API (`/status`,
/// `/probe`, `/reset`), served directly by the device on the LAN -- distinct
/// from `LakeApiClient`, which talks to the feslabs.com cloud API. Only
/// reachable when the phone and the device are on the same local network.
struct DeviceApiClient {
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            // The device is on the LAN; if it doesn't respond quickly it's
            // almost certainly unreachable (wrong network, device down),
            // so fail fast rather than hanging for the default 60s.
            configuration.timeoutIntervalForRequest = 6
            configuration.timeoutIntervalForResource = 6
            self.session = URLSession(configuration: configuration)
        }
    }

    private func baseURL() throws -> URL {
        guard let address = DeviceSettingsStore.loadIPAddress(), !address.isEmpty else {
            throw DeviceApiError.noAddressConfigured
        }
        guard let url = URL(string: "http://\(address)") else {
            throw DeviceApiError.invalidAddress
        }
        return url
    }

    func fetchStatus() async throws -> (value: DeviceStatus, rawJSON: String) {
        try await get(path: "status")
    }

    func fetchProbe() async throws -> (value: DeviceProbeReading, rawJSON: String) {
        try await get(path: "probe")
    }

    /// Reboots the device (`NVIC_SystemReset()` on the firmware side). Used
    /// to recover from the known clock-skew scheduler stall until the
    /// firmware fix is flashed to the physical device.
    func reset() async throws {
        let url = try baseURL().appendingPathComponent("reset")
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        do {
            _ = try await session.data(for: request)
        } catch {
            // The device deliberately closes the connection as it reboots,
            // so a transport error here is expected and not a failure.
        }
    }

    /// Triggers `POST /rs485/selftest`: an internal loopback test of the
    /// SC16IS752 bridge/UART core on both RS-485 channels (not the physical
    /// bus or the downstream sensors). Manually triggered only -- it's
    /// disruptive to any in-flight Modbus transaction on these channels.
    func triggerRs485SelfTest() async throws -> (value: DeviceRs485SelfTestResult, rawJSON: String) {
        try await post(path: "rs485/selftest")
    }

    /// Fetches and decodes `path`, also returning the raw response body as
    /// text. The raw text is kept (not just the typed model) so a user can
    /// export/share the *complete* response -- including any fields not
    /// modeled in `DeviceStatus`/`DeviceProbeReading` -- when reporting an
    /// issue to a support/debugging assistant.
    private func get<T: Decodable>(path: String) async throws -> (value: T, rawJSON: String) {
        let url = try baseURL().appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        return try await send(request: request)
    }

    /// Same as `get`, but issues a `POST` with an empty body -- used for
    /// manually-triggered actions (like the RS-485 self-test) that the
    /// firmware deliberately doesn't accept over `GET`, so an accidental
    /// link click/prefetch can't trigger a disruptive diagnostic.
    private func post<T: Decodable>(path: String) async throws -> (value: T, rawJSON: String) {
        let url = try baseURL().appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 6

        return try await send(request: request)
    }

    private func send<T: Decodable>(request: URLRequest) async throws -> (value: T, rawJSON: String) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DeviceApiError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeviceApiError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw DeviceApiError.httpStatus(httpResponse.statusCode)
        }

        let rawJSON = String(data: data, encoding: .utf8) ?? "<non-UTF8 response, \(data.count) bytes>"

        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            return (value, rawJSON)
        } catch {
            throw DeviceApiError.decodingFailed(error)
        }
    }
}
