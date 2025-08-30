import WidgetKit
import SwiftUI

struct PrayerTimeWidgetView: View {
    var entry: PrayerTimeProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            // Consistent green gradient background for all sizes
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.7, blue: 0.3),
                    Color(red: 0.1, green: 0.55, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Adaptive content based on widget size
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: PrayerTimeProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with current prayer name
            Text(entry.nextPrayer.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // Prayer time
            Text(entry.nextPrayer.time)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Countdown
            Text(entry.countdown.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                )
        }
        .padding(12)
    }
}

// MARK: - Medium Widget (4x2) 
struct MediumWidgetView: View {
    let entry: PrayerTimeProvider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side: Next Prayer Info
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.8))
                    
                    Text(entry.nextPrayer.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(entry.nextPrayer.time)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                
                // Countdown with background
                Text(entry.countdown.text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.25))
                    )
            }
            
            Spacer()
            
            // Right side: All Prayer Times in compact grid
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    CompactPrayerItem(name: "Fajr", time: entry.prayers.fajr, isNext: entry.nextPrayer.name == "Fajr")
                    CompactPrayerItem(name: "Dhuhr", time: entry.prayers.dhuhr, isNext: entry.nextPrayer.name == "Dhuhr")
                }
                HStack(spacing: 8) {
                    CompactPrayerItem(name: "Asr", time: entry.prayers.asr, isNext: entry.nextPrayer.name == "Asr")
                    CompactPrayerItem(name: "Maghrib", time: entry.prayers.maghrib, isNext: entry.nextPrayer.name == "Maghrib")
                }
                HStack {
                    CompactPrayerItem(name: "Isha", time: entry.prayers.isha, isNext: entry.nextPrayer.name == "Isha")
                    Spacer()
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: PrayerTimeProvider.Entry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with current time
            HStack {
                Text("Prayer Times")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(entry.currentTime)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            
            // Next Prayer Section - Prominent
            VStack(spacing: 8) {
                HStack {
                    Text("Next Prayer:")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(entry.nextPrayer.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(entry.nextPrayer.time)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                
                Text(entry.countdown.text)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // All Prayer Times - Spacious Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ExpandedPrayerItem(name: "Fajr", time: entry.prayers.fajr, isNext: entry.nextPrayer.name == "Fajr")
                    ExpandedPrayerItem(name: "Dhuhr", time: entry.prayers.dhuhr, isNext: entry.nextPrayer.name == "Dhuhr")
                }
                
                HStack(spacing: 12) {
                    ExpandedPrayerItem(name: "Asr", time: entry.prayers.asr, isNext: entry.nextPrayer.name == "Asr")
                    ExpandedPrayerItem(name: "Maghrib", time: entry.prayers.maghrib, isNext: entry.nextPrayer.name == "Maghrib")
                }
                
                HStack {
                    ExpandedPrayerItem(name: "Isha", time: entry.prayers.isha, isNext: entry.nextPrayer.name == "Isha")
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Compact Prayer Item (for Medium widget)
struct CompactPrayerItem: View {
    let name: String
    let time: String
    let isNext: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isNext ? .white : Color.white.opacity(0.7))
            
            Text(formatTime(time))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isNext ? .white : Color.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isNext ? Color.white.opacity(0.25) : Color.white.opacity(0.12))
        )
    }
}

// MARK: - Expanded Prayer Item (for Large widget)
struct ExpandedPrayerItem: View {
    let name: String
    let time: String
    let isNext: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isNext ? .white : Color.white.opacity(0.8))
            
            Text(formatTime(time))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isNext ? .white : Color.white.opacity(0.95))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNext ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isNext ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Helper Function
private func formatTime(_ time: String) -> String {
    // Remove AM/PM for cleaner look in compact widgets
    return time.replacingOccurrences(of: " AM", with: "").replacingOccurrences(of: " PM", with: "")
}

