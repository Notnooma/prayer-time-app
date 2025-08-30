import WidgetKit
import SwiftUI

struct PrayerTimeWidget: Widget {
    let kind: String = "PrayerTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimeProvider()) { entry in
            PrayerTimeWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Display prayer times and countdown to next prayer")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct PrayerTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimeWidget()
    }
}
