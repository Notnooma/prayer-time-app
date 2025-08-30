import WidgetKit
import SwiftUI

struct PrayerTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimeEntry {
        PrayerTimeEntry(
            date: Date(),
            prayers: PrayerTimes(
                fajr: "5:15 AM",
                dhuhr: "12:45 PM",
                asr: "3:30 PM",
                maghrib: "6:00 PM",
                isha: "7:45 PM"
            ),
            nextPrayer: NextPrayerInfo(name: "Maghrib", time: "6:00 PM"),
            countdown: CountdownInfo(text: "2h 30m", hours: 2, minutes: 30, seconds: 0, totalSeconds: 9000),
            currentTime: "3:30 PM"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimeEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = createEntry(for: currentDate)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry(for date: Date = Date()) -> PrayerTimeEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.wia.prayer_app.widgets")
        
        let prayers = PrayerTimes(
            fajr: userDefaults?.string(forKey: "fajr_time") ?? "5:15 AM",
            dhuhr: userDefaults?.string(forKey: "dhuhr_time") ?? "12:45 PM",
            asr: userDefaults?.string(forKey: "asr_time") ?? "3:30 PM",
            maghrib: userDefaults?.string(forKey: "maghrib_time") ?? "6:00 PM",
            isha: userDefaults?.string(forKey: "isha_time") ?? "7:45 PM"
        )
        
        let nextPrayer = NextPrayerInfo(
            name: userDefaults?.string(forKey: "next_prayer_name") ?? "Maghrib",
            time: userDefaults?.string(forKey: "next_prayer_time") ?? "6:00 PM"
        )
        
        let countdown = CountdownInfo(
            text: userDefaults?.string(forKey: "countdown_text") ?? "2h 30m",
            hours: userDefaults?.integer(forKey: "countdown_hours") ?? 2,
            minutes: userDefaults?.integer(forKey: "countdown_minutes") ?? 30,
            seconds: userDefaults?.integer(forKey: "countdown_seconds") ?? 0,
            totalSeconds: userDefaults?.integer(forKey: "total_seconds") ?? 9000
        )
        
        let currentTime = userDefaults?.string(forKey: "current_time") ?? DateFormatter.timeFormatter.string(from: date)
        
        return PrayerTimeEntry(
            date: date,
            prayers: prayers,
            nextPrayer: nextPrayer,
            countdown: countdown,
            currentTime: currentTime
        )
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
