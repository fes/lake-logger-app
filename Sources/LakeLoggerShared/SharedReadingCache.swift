import Foundation

/// Caches the last successfully fetched reading in the shared App Group
/// container so the widget can show recent data instantly (and fall back to
/// it if a network refresh fails) without waiting on its own network call,
/// and so the app and widget stay visually consistent.
enum SharedReadingCache {
    static let appGroupId = "group.com.feslabs.lakelogger"
    private static let readingKey = "lastReading"
    private static let fetchedAtKey = "lastReadingFetchedAt"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func save(_ reading: LakeReading) {
        guard let defaults, let data = try? JSONEncoder().encode(reading) else { return }
        defaults.set(data, forKey: readingKey)
        defaults.set(Date(), forKey: fetchedAtKey)
    }

    static func load() -> (reading: LakeReading, fetchedAt: Date)? {
        guard let defaults,
              let data = defaults.data(forKey: readingKey),
              let reading = try? JSONDecoder().decode(LakeReading.self, from: data) else {
            return nil
        }
        let fetchedAt = defaults.object(forKey: fetchedAtKey) as? Date ?? Date.distantPast
        return (reading, fetchedAt)
    }
}
