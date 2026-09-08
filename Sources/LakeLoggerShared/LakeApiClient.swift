import Foundation

struct LakeApiWarning: Codable, Equatable {
    var code: String
    var message: String
    var details: [String]?
}

struct LakeCurrentResponse: Codable {
    var ok: Bool
    var reading: LakeReading?
    var count: Int
    var tabsRead: [String]?
    var tabsMissing: [String]?
    var warnings: [LakeApiWarning]?
}

struct LakeHistoryResponse: Codable {
    var ok: Bool
    var readings: [LakeReading]
    var count: Int
    var tabsRead: [String]?
    var tabsMissing: [String]?
    var warnings: [LakeApiWarning]?
}

enum LakeApiError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case apiReportedFailure(String)
    case decodingFailed(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpStatus(let code):
            return "The server returned HTTP \(code)."
        case .apiReportedFailure(let message):
            return message
        case .decodingFailed:
            return "Could not understand the server's response."
        case .transport(let error):
            return error.localizedDescription
        }
    }
}

/// Thin client for the public, unauthenticated fesLabs Lake Logger read API.
/// Used by both the main app and the widget extension's timeline provider.
struct LakeApiClient {
    static let shared = LakeApiClient()

    private let baseURL = URL(string: "https://feslabs.com/api")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches the most recent reading. Returns `nil` if the sheet has no
    /// readings yet (not an error condition).
    func fetchCurrent() async throws -> LakeReading? {
        let url = baseURL.appendingPathComponent("lake/current")
        let decoded: LakeCurrentResponse = try await get(url)
        guard decoded.ok else {
            throw LakeApiError.apiReportedFailure("The lake logger API reported a failure.")
        }
        return decoded.reading
    }

    /// Fetches readings for the trailing `days` days, oldest first.
    func fetchHistory(days: Int) async throws -> [LakeReading] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("lake/history"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "days", value: String(days))]

        let decoded: LakeHistoryResponse = try await get(components.url!)
        guard decoded.ok else {
            throw LakeApiError.apiReportedFailure("The lake logger API reported a failure.")
        }
        return decoded.readings
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LakeApiError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LakeApiError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LakeApiError.httpStatus(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw LakeApiError.decodingFailed(error)
        }
    }
}
