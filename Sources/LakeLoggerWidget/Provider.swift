import WidgetKit
import SwiftUI

struct LakeEntry: TimelineEntry {
    let date: Date
    let reading: LakeReading?
    let fetchedAt: Date?
    let errorMessage: String?
}

struct LakeTimelineProvider: TimelineProvider {
    private let api = LakeApiClient.shared

    func placeholder(in context: Context) -> LakeEntry {
        LakeEntry(date: Date(), reading: SharedReadingCache.load()?.reading, fetchedAt: nil, errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LakeEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LakeEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()

            // The logger uploads roughly hourly; re-check a little more often
            // than that so we pick up a fresh reading soon after it lands,
            // without hammering the API. If this attempt failed, retry sooner.
            let refreshInterval: TimeInterval = entry.reading != nil ? 20 * 60 : 5 * 60
            let nextRefresh = Date().addingTimeInterval(refreshInterval)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func fetchEntry() async -> LakeEntry {
        do {
            if let latest = try await api.fetchCurrent() {
                SharedReadingCache.save(latest)
                return LakeEntry(date: Date(), reading: latest, fetchedAt: Date(), errorMessage: nil)
            }
            // API succeeded but reported no readings; fall back to cache if we have one.
            return fallbackEntry(errorMessage: nil)
        } catch {
            return fallbackEntry(errorMessage: error.localizedDescription)
        }
    }

    private func fallbackEntry(errorMessage: String?) -> LakeEntry {
        if let cached = SharedReadingCache.load() {
            return LakeEntry(date: Date(), reading: cached.reading, fetchedAt: cached.fetchedAt, errorMessage: errorMessage)
        }
        return LakeEntry(date: Date(), reading: nil, fetchedAt: nil, errorMessage: errorMessage)
    }
}
