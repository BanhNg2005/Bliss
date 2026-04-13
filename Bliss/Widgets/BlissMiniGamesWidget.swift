import WidgetKit
import SwiftUI

struct BlissMiniGamesEntry: TimelineEntry {
    let date: Date
}

struct BlissMiniGamesProvider: TimelineProvider {
    func placeholder(in context: Context) -> BlissMiniGamesEntry {
        BlissMiniGamesEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (BlissMiniGamesEntry) -> Void) {
        completion(BlissMiniGamesEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BlissMiniGamesEntry>) -> Void) {
        let entry = BlissMiniGamesEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct BlissMiniGamesWidgetEntryView: View {
    var entry: BlissMiniGamesProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.95), .purple.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 28, weight: .semibold))
                Text("Mini Games")
                    .font(.headline.bold())
                Text("Tap to play")
                    .font(.caption)
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
        }
        .widgetURL(URL(string: "bliss://minigames"))
    }
}

struct BlissMiniGamesWidget: Widget {
    let kind: String = "BlissMiniGamesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BlissMiniGamesProvider()) { entry in
            BlissMiniGamesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bliss Mini Games")
        .description("Opens the mini games section in Bliss.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
