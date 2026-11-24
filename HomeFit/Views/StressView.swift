import SwiftUI
import Charts

struct StressView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false
    @State private var breathing: BreathingPattern?

    private var chartData: [(day: Date, value: Double)] {
        Date.lastDays(14).compactMap { day in
            store.data.averageStress(on: day).map { (day: day, value: $0) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Heute
                Section {
                    HStack(spacing: 16) {
                        if let avg = store.data.averageStress(on: Date()) {
                            ZStack {
                                RingView(progress: avg / 10, color: .stressColor(avg), lineWidth: 10)
                                Text(StressEntry.emoji(for: Int(avg.rounded()))).font(.largeTitle)
                            }
                            .frame(width: 80, height: 80)
                            VStack(alignment: .leading) {
                                Text(StressEntry.label(for: Int(avg.rounded()))).font(.headline)
                                Text(String(format: "Ø %.1f von 10 heute", avg))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("🫶").font(.system(size: 50))
                            VStack(alignment: .leading) {
                                Text("Wie geht's dir gerade?").font(.headline)
                                Text("Erfasse dein Stresslevel, um Muster zu erkennen.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    Button {
                        showAdd = true
                    } label: {
                        Label("Stresslevel erfassen", systemImage: "plus.circle.fill")
                    }
                }

                // Entspannung
                Section("Entspannen") {
                    ForEach(BreathingPattern.all) { pattern in
                        Button {
                            breathing = pattern
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "wind")
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(pattern.color.gradient, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading) {
                                    Text(pattern.name).foregroundStyle(.primary)
                                    Text(pattern.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Verlauf
                if !chartData.isEmpty {
                    Section("Letzte 14 Tage") {
                        Chart {
                            ForEach(chartData, id: \.day) { point in
                                LineMark(x: .value("Tag", point.day, unit: .day),
                                         y: .value("Stress", point.value))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(Color.purple)
                                PointMark(x: .value("Tag", point.day, unit: .day),
                                          y: .value("Stress", point.value))
                                    .foregroundStyle(Color.stressColor(point.value))
                            }
                        }
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                                AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                            }
                        }
                        .frame(height: 170)
                        .padding(.vertical, 6)
                    }
                }

                // Tipps
                Section("Tipps gegen Stress") {
                    ForEach(StressTip.all) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Text(tip.emoji).font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tip.title).font(.subheadline.bold())
                                Text(tip.text).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Einträge
                if !store.data.stress.isEmpty {
                    Section("Einträge") {
                        ForEach(store.data.stress.sorted { $0.date > $1.date }.prefix(30)) { entry in
                            HStack {
                                Text(StressEntry.emoji(for: entry.level)).font(.title2)
                                VStack(alignment: .leading) {
                                    Text("\(entry.level)/10 · \(StressEntry.label(for: entry.level))")
                                    if !entry.note.isEmpty {
                                        Text(entry.note).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(entry.date.formatted(.dateTime.day().month().hour().minute()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) { store.deleteStress(entry) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stress")
            .sheet(isPresented: $showAdd) { AddStressView() }
            .sheet(item: $breathing) { BreathingView(pattern: $0) }
        }
    }
}

// MARK: - Stress erfassen

struct AddStressView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var level: Double = 5
    @State private var note = ""
    @State private var showBreathing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Text(StressEntry.emoji(for: Int(level)))
                            .font(.system(size: 70))
                        Text("\(Int(level)) / 10 · \(StressEntry.label(for: Int(level)))")
                            .font(.headline)
                            .foregroundStyle(Color.stressColor(level))
                        Slider(value: $level, in: 1...10, step: 1) {
                            Text("Stress")
                        } minimumValueLabel: {
                            Text("😌")
                        } maximumValueLabel: {
                            Text("🤯")
                        }
                        .tint(Color.stressColor(level))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } header: {
                    Text("Wie gestresst fühlst du dich?")
                }
                Section("Notiz (optional)") {
                    TextField("Was beschäftigt dich?", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                if level >= 7 {
                    Section {
                        Label("Hoher Stress – probier doch direkt eine 2-Minuten-Atemübung.", systemImage: "heart.text.square")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Stress erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.addStress(StressEntry(level: Int(level), note: note, date: Date()))
                        if level >= 7 {
                            showBreathing = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showBreathing, onDismiss: { dismiss() }) {
                BreathingView()
            }
        }
    }
}

// MARK: - Atemübung

struct BreathingPattern: Identifiable, Hashable {
    struct Step: Hashable {
        var title: String
        var seconds: Int
        var scale: CGFloat
    }

    var id: String { name }
    var name: String
    var subtitle: String
    var color: Color
    var steps: [Step]

    static let box = BreathingPattern(
        name: "Box-Atmung", subtitle: "4-4-4-4 · beruhigt & fokussiert", color: .teal,
        steps: [Step(title: "Einatmen", seconds: 4, scale: 1.0),
                Step(title: "Halten", seconds: 4, scale: 1.0),
                Step(title: "Ausatmen", seconds: 4, scale: 0.45),
                Step(title: "Halten", seconds: 4, scale: 0.45)])

    static let sleep = BreathingPattern(
        name: "4-7-8-Atmung", subtitle: "Zum Einschlafen & Runterkommen", color: .indigo,
        steps: [Step(title: "Einatmen", seconds: 4, scale: 1.0),
                Step(title: "Halten", seconds: 7, scale: 1.0),
                Step(title: "Ausatmen", seconds: 8, scale: 0.45)])

    static let calm = BreathingPattern(
        name: "Ruhiger Atem", subtitle: "5-5 · Herzfrequenz-Kohärenz", color: .mint,
        steps: [Step(title: "Einatmen", seconds: 5, scale: 1.0),
                Step(title: "Ausatmen", seconds: 5, scale: 0.45)])

    static let all = [box, sleep, calm]
}

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    var pattern: BreathingPattern = .box

    @State private var running = false
    @State private var stepTitle = "Bereit?"
    @State private var secondsLeft = 0
    @State private var scale: CGFloat = 0.45
    @State private var cycles = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(pattern.subtitle)
                    .foregroundStyle(.secondary)

                Spacer()

                ZStack {
                    Circle()
                        .fill(pattern.color.opacity(0.15))
                        .frame(width: 280, height: 280)
                    Circle()
                        .fill(pattern.color.gradient)
                        .frame(width: 280, height: 280)
                        .scaleEffect(scale)
                        .shadow(color: pattern.color.opacity(0.5), radius: 20)
                    VStack {
                        Text(stepTitle)
                            .font(.title.bold())
                        if running {
                            Text("\(secondsLeft)")
                                .font(.title2.monospacedDigit())
                        }
                    }
                    .foregroundStyle(.white)
                    .shadow(radius: 3)
                }

                Text("Runden: \(cycles)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if running { stop() } else { start() }
                } label: {
                    Label(running ? "Stopp" : "Start", systemImage: running ? "stop.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(pattern.color)
                .padding(.horizontal, 40)
                .padding(.bottom)
            }
            .navigationTitle(pattern.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onDisappear {
                task?.cancel()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    private func start() {
        running = true
        UIApplication.shared.isIdleTimerDisabled = true
        task = Task { @MainActor in
            while !Task.isCancelled {
                for step in pattern.steps {
                    stepTitle = step.title
                    withAnimation(.easeInOut(duration: Double(step.seconds))) {
                        scale = step.scale
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    for s in stride(from: step.seconds, to: 0, by: -1) {
                        secondsLeft = s
                        try? await Task.sleep(for: .seconds(1))
                        if Task.isCancelled { return }
                    }
                }
                cycles += 1
            }
        }
    }

    private func stop() {
        task?.cancel()
        running = false
        stepTitle = "Gut gemacht 🌿"
        UIApplication.shared.isIdleTimerDisabled = false
        withAnimation(.easeInOut(duration: 1)) { scale = 0.45 }
    }
}

// MARK: - Tipps

struct StressTip: Identifiable {
    var id: String { title }
    var emoji: String
    var title: String
    var text: String

    static let all = [
        StressTip(emoji: "🚶", title: "Kurz bewegen", text: "Schon 10 Minuten Bewegung senken Stresshormone spürbar – z. B. ein Quick-Workout oder ein Spaziergang."),
        StressTip(emoji: "🌬️", title: "Bewusst atmen", text: "Langsames Ausatmen aktiviert das Entspannungs-Nervensystem. Probier die Atemübungen oben."),
        StressTip(emoji: "📵", title: "Handy-Pause", text: "Lege das Handy für 30 Minuten weg, besonders vor dem Schlafengehen."),
        StressTip(emoji: "💧", title: "Genug trinken", text: "Schon leichter Flüssigkeitsmangel kann Konzentration und Stimmung verschlechtern."),
        StressTip(emoji: "😴", title: "Schlaf-Routine", text: "Feste Schlafenszeiten und 7–9 Stunden Schlaf machen dich belastbarer."),
        StressTip(emoji: "📝", title: "Gedanken aufschreiben", text: "Notiere, was dich beschäftigt – das schafft Abstand. Nutze dafür die Notiz beim Erfassen."),
    ]
}
