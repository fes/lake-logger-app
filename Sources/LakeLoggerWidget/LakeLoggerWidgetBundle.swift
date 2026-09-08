import WidgetKit
import SwiftUI

struct LakeLoggerWidget: Widget {
    let kind: String = "LakeLoggerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LakeTimelineProvider()) { entry in
            LakeLoggerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Lake Logger")
        .description("Shows the latest water level, temperature, power, and weather readings.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

@main
struct LakeLoggerWidgetBundle: WidgetBundle {
    var body: some Widget {
        LakeLoggerWidget()
    }
}
