import WidgetKit
import SwiftUI

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: String
    let timeRemaining: String
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let lastUpdated: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerTimesEntry {
        PrayerTimesEntry(
            date: Date(),
            nextPrayerName: "Fajr",
            nextPrayerTime: "05:30",
            timeRemaining: "2h 30m",
            fajr: "05:30",
            dhuhr: "12:45",
            asr: "15:30",
            maghrib: "17:45",
            isha: "19:15",
            lastUpdated: "Just now"
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
            fajr: sharedDefaults?.string(forKey: "prayer_fajr") ?? "--:--",
            dhuhr: sharedDefaults?.string(forKey: "prayer_dhuhr") ?? "--:--",
            asr: sharedDefaults?.string(forKey: "prayer_asr") ?? "--:--",
            maghrib: sharedDefaults?.string(forKey: "prayer_maghrib") ?? "--:--",
            isha: sharedDefaults?.string(forKey: "prayer_isha") ?? "--:--",
            lastUpdated: sharedDefaults?.string(forKey: "last_updated") ?? ""
        )
    }
}

struct PrayerTimesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Prayer Times")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.lastUpdated)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            // Next Prayer Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Prayer")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Text(entry.nextPrayerName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Spacer()
                    Text(entry.nextPrayerTime)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Text("in \(entry.timeRemaining)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            // All Prayer Times
            VStack(spacing: 6) {
                PrayerTimeRow(name: "Fajr", time: entry.fajr)
                PrayerTimeRow(name: "Dhuhr", time: entry.dhuhr)
                PrayerTimeRow(name: "Asr", time: entry.asr)
                PrayerTimeRow(name: "Maghrib", time: entry.maghrib)
                PrayerTimeRow(name: "Isha", time: entry.isha)
            }
        }
        .padding()
    }
}

struct PrayerTimeRow: View {
    let name: String
    let time: String

    var body: some View {
        HStack {
            Text(name)
                .font(.body)
            Spacer()
            Text(time)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

@main
struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Display prayer times on your home screen")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct PrayerTimesWidget_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesWidgetEntryView(entry: PrayerTimesEntry(
            date: Date(),
            nextPrayerName: "Fajr",
            nextPrayerTime: "05:30",
            timeRemaining: "2h 30m",
            fajr: "05:30",
            dhuhr: "12:45",
            asr: "15:30",
            maghrib: "17:45",
            isha: "19:15",
            lastUpdated: "Just now"
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
