import WidgetKit
import SwiftUI

// MARK: - Theme Colors
struct WidgetThemeColors {
    let background: Color
    let text: Color
    let textSecondary: Color
    let accent: Color
    let cardBg: Color

    static func fromIndex(_ index: Int) -> WidgetThemeColors {
        switch index {
        case 0: // Night Sky
            return WidgetThemeColors(
                background: Color(hex: 0x0F172A),
                text: Color(hex: 0xF8FAFC),
                textSecondary: Color(hex: 0xCBD5E1),
                accent: Color(hex: 0xD4AF37),
                cardBg: Color(hex: 0x1E293B)
            )
        case 1: // Ocean Blue
            return WidgetThemeColors(
                background: Color(hex: 0x1A365D),
                text: Color(hex: 0xF8FAFC),
                textSecondary: Color(hex: 0xCBD5E1),
                accent: Color(hex: 0x38B2AC),
                cardBg: Color(hex: 0x2C5282)
            )
        case 2: // Forest
            return WidgetThemeColors(
                background: Color(hex: 0x1A4731),
                text: Color(hex: 0xF8FAFC),
                textSecondary: Color(hex: 0xCBD5E1),
                accent: Color(hex: 0x10B981),
                cardBg: Color(hex: 0x22543D)
            )
        case 3: // Light
            return WidgetThemeColors(
                background: Color(hex: 0xFFFFFF),
                text: Color(hex: 0x334155),
                textSecondary: Color(hex: 0x64748B),
                accent: Color(hex: 0x1E293B),
                cardBg: Color(hex: 0xF1F5F9)
            )
        case 4: // Pure Dark
            return WidgetThemeColors(
                background: Color(hex: 0x000000),
                text: Color(hex: 0xFFFFFF),
                textSecondary: Color(hex: 0xA1A1AA),
                accent: Color(hex: 0xD4AF37),
                cardBg: Color(hex: 0x18181B)
            )
        default:
            return fromIndex(0)
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - Timeline Entry
struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
    let timeRemaining: String
    let countdownFormatted: String
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let lastUpdated: String
    let locationName: String
    let hijriDate: String
    let themeIndex: Int
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            nextPrayerName: "Fajr",
            nextPrayerTime: "05:57",
            timeRemaining: "2h 30m",
            countdownFormatted: "02:30",
            fajr: "05:57",
            dhuhr: "12:55",
            asr: "15:37",
            maghrib: "18:12",
            isha: "19:46",
            lastUpdated: "Just now",
            locationName: "London",
            hijriDate: "15 Rajab 1446",
            themeIndex: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> ()) {
        let entry = loadPrayerTimes()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadPrayerTimes()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        completion(timeline)
    }

    func loadPrayerTimes() -> PrayerTimesEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.immutable5.prayertimes")

        return PrayerTimesEntry(
            date: Date(),
            nextPrayerName: sharedDefaults?.string(forKey: "next_prayer_name") ?? "Loading...",
            nextPrayerTime: sharedDefaults?.string(forKey: "next_prayer_time") ?? "--:--",
            timeRemaining: sharedDefaults?.string(forKey: "time_remaining") ?? "",
            countdownFormatted: sharedDefaults?.string(forKey: "countdown_formatted") ?? "--:--",
            fajr: sharedDefaults?.string(forKey: "prayer_fajr") ?? "--:--",
            dhuhr: sharedDefaults?.string(forKey: "prayer_dhuhr") ?? "--:--",
            asr: sharedDefaults?.string(forKey: "prayer_asr") ?? "--:--",
            maghrib: sharedDefaults?.string(forKey: "prayer_maghrib") ?? "--:--",
            isha: sharedDefaults?.string(forKey: "prayer_isha") ?? "--:--",
            lastUpdated: sharedDefaults?.string(forKey: "last_updated") ?? "",
            locationName: sharedDefaults?.string(forKey: "location_name") ?? "Current Location",
            hijriDate: sharedDefaults?.string(forKey: "hijri_date") ?? "",
            themeIndex: sharedDefaults?.integer(forKey: "theme_index") ?? 0
        )
    }
}

// MARK: - Widget Entry View
struct PrayerTimesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var theme: WidgetThemeColors {
        WidgetThemeColors.fromIndex(entry.themeIndex)
    }

    var body: some View {
        ZStack {
            theme.background

            VStack(spacing: 0) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.locationName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.text)
                        Text(entry.hijriDate)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(entry.nextPrayerName) in")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                        Text(entry.countdownFormatted)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(theme.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Divider
                Rectangle()
                    .fill(theme.textSecondary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // Prayer Times Row
                HStack(spacing: 0) {
                    PrayerTimeColumn(
                        name: "Fajr",
                        time: entry.fajr,
                        isNext: entry.nextPrayerName == "Fajr",
                        theme: theme
                    )
                    PrayerTimeColumn(
                        name: "Dhuhr",
                        time: entry.dhuhr,
                        isNext: entry.nextPrayerName == "Dhuhr",
                        theme: theme
                    )
                    PrayerTimeColumn(
                        name: "Asr",
                        time: entry.asr,
                        isNext: entry.nextPrayerName == "Asr",
                        theme: theme
                    )
                    PrayerTimeColumn(
                        name: "Maghrib",
                        time: entry.maghrib,
                        isNext: entry.nextPrayerName == "Maghrib",
                        theme: theme
                    )
                    PrayerTimeColumn(
                        name: "Isha",
                        time: entry.isha,
                        isNext: entry.nextPrayerName == "Isha",
                        theme: theme
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Prayer Time Column
struct PrayerTimeColumn: View {
    let name: String
    let time: String
    let isNext: Bool
    let theme: WidgetThemeColors

    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: isNext ? .semibold : .regular))
                .foregroundColor(isNext ? theme.accent : theme.textSecondary)
            Text(time)
                .font(.system(size: 13, weight: isNext ? .bold : .medium, design: .monospaced))
                .foregroundColor(isNext ? theme.accent : theme.text)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration
@main
struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PrayerTimesWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PrayerTimesWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Prayer Times")
        .description("Display prayer times on your home screen")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview
struct PrayerTimesWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Night Sky Theme
            PrayerTimesWidgetEntryView(entry: PrayerTimesEntry(
                date: Date(),
                nextPrayerName: "Maghrib",
                nextPrayerTime: "18:12",
                timeRemaining: "2h 30m",
                countdownFormatted: "02:30",
                fajr: "05:57",
                dhuhr: "12:55",
                asr: "15:37",
                maghrib: "18:12",
                isha: "19:46",
                lastUpdated: "Just now",
                locationName: "London",
                hijriDate: "15 Rajab 1446",
                themeIndex: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Night Sky")

            // Light Theme
            PrayerTimesWidgetEntryView(entry: PrayerTimesEntry(
                date: Date(),
                nextPrayerName: "Asr",
                nextPrayerTime: "15:37",
                timeRemaining: "1h 15m",
                countdownFormatted: "01:15",
                fajr: "05:57",
                dhuhr: "12:55",
                asr: "15:37",
                maghrib: "18:12",
                isha: "19:46",
                lastUpdated: "Just now",
                locationName: "Mecca",
                hijriDate: "10 Ramadan 1446",
                themeIndex: 3
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Light")
        }
    }
}
