import WidgetKit
import SwiftUI

struct LakeLoggerWidget: Widget {
    let kind: String = "LakeLoggerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LakeTimelineProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                LakeLoggerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LakeLoggerWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
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
