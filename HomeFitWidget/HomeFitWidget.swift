import WidgetKit
import SwiftUI

// MARK: - Daten für das Widget

struct HomeFitEntry: TimelineEntry {
    let date: Date
    let eaten: Double
    let goal: Double
    let burned: Double
    let stress: Double?
    let trainingMinutes: Double
    let streak: Int

    var remaining: Double { goal - eaten + burned }
    var progress: Double { eaten / max(goal + burned, 1) }

    static func current() -> HomeFitEntry {
        let data = Persistence.load()
        let today = Date()
        return HomeFitEntry(date: today,
                            eaten: data.caloriesEaten(on: today),
                            goal: data.profile.calorieGoal,
                            burned: data.caloriesBurned(on: today),
                            stress: data.averageStress(on: today),
                            trainingMinutes: data.trainingMinutes(on: today),
                            streak: data.workoutStreak)
    }

    static let sample = HomeFitEntry(date: Date(), eaten: 1350, goal: 2200, burned: 240,
                                     stress: 4, trainingMinutes: 25, streak: 3)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HomeFitEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (HomeFitEntry) -> Void) {
        completion(context.isPreview ? .sample : .current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeFitEntry>) -> Void) {
        let entry = HomeFitEntry.current()
        let cal = Calendar.current
        // Spätestens nach Mitternacht neu laden (neuer Tag), sonst stündlich
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!.addingTimeInterval(60)
        let next = min(Date().addingTimeInterval(3600), tomorrow)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Ansichten

struct HomeFitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HomeFitEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    private var ring: some View {
        ZStack {
            RingView(progress: entry.progress, color: .orange, lineWidth: 10)
            VStack(spacing: 0) {
                Text(max(entry.remaining, 0).whole)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.6)
                Text("kcal übrig")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "house.fill").foregroundStyle(.green)
                Text("HomeFit").font(.caption.bold())
                Spacer()
                if let s = entry.stress {
                    Text(StressEntry.emoji(for: Int(s.rounded())))
                }
            }
            ring.frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.red)
                Text("\(entry.burned.whole)")
                Spacer()
                Image(systemName: "stopwatch").foregroundStyle(.green)
                Text("\(entry.trainingMinutes.whole)′")
            }
            .font(.caption2.bold())
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ring.frame(width: 110, height: 110)
            VStack(alignment: .leading, spacing: 7) {
                Text("Heute").font(.headline)
                row("fork.knife", .orange, "Gegessen", entry.eaten.kcal)
                row("flame.fill", .red, "Verbrannt", entry.burned.kcal)
                row("stopwatch.fill", .green, "Training", "\(entry.trainingMinutes.whole) Min · \(entry.streak)🔥")
                row("brain.head.profile",
                    entry.stress.map { Color.stressColor($0) } ?? .gray,
                    "Stress",
                    entry.stress.map { String(format: "%.1f/10 %@", $0, StressEntry.emoji(for: Int($0.rounded()))) } ?? "–")
            }
        }
    }

    private func row(_ icon: String, _ color: Color, _ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(value).bold().lineLimit(1).minimumScaleFactor(0.7)
        }
        .font(.caption)
    }

    private var circular: some View {
        Gauge(value: min(entry.progress, 1)) {
            Image(systemName: "fork.knife")
        } currentValueLabel: {
            Text(max(entry.remaining, 0).whole)
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HomeFit").font(.headline)
            Text("\(max(entry.remaining, 0).whole) kcal übrig")
            Text("🔥 \(entry.burned.whole) kcal · \(entry.trainingMinutes.whole) Min")
                .font(.caption)
        }
    }
}

// MARK: - Widget

struct HomeFitWidget: Widget {
    let kind = "HomeFitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeFitWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("HomeFit Tagesübersicht")
        .description("Kalorien, Training und Stress auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct HomeFitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeFitWidget()
    }
}

#Preview(as: .systemMedium) {
    HomeFitWidget()
} timeline: {
    HomeFitEntry.sample
}
