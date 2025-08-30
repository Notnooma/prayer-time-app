import WidgetKit
import SwiftUI

struct PrayerTimeEntry: TimelineEntry {
    let date: Date
    let prayers: PrayerTimes
    let nextPrayer: NextPrayerInfo
    let countdown: CountdownInfo
    let currentTime: String
}

struct PrayerTimes {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
}

struct NextPrayerInfo {
    let name: String
    let time: String
}

struct CountdownInfo {
    let text: String
    let hours: Int
    let minutes: Int
    let seconds: Int
    let totalSeconds: Int
}
