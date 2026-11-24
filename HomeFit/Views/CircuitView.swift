import SwiftUI

/// Quick-Workout: Übungen auswählen, Runden & Zeiten einstellen.
struct CircuitSetupView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selected: [Exercise] = []
    @State private var rounds = 3
    @State private var work = 40
    @State private var rest = 20
    @State private var running = false

    private var totalMinutes: Int {
        let perRound = selected.count * (work + rest)
        return Int((Double(perRound * rounds) / 60).rounded())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        randomize()
                    } label: {
                        Label("Zufällig zusammenstellen", systemImage: "shuffle")
                    }
                    Stepper("Runden: \(rounds)", value: $rounds, in: 1...10)
                    Stepper("Belastung: \(work) Sek.", value: $work, in: 10...180, step: 5)
                    Stepper("Pause: \(rest) Sek.", value: $rest, in: 0...120, step: 5)
                    LabeledContent("Dauer ca.", value: "\(totalMinutes) Min")
                } header: {
                    Text("Einstellungen")
                }

                Section {
                    if selected.isEmpty {
                        Text("Tippe unten auf Übungen, um sie hinzuzufügen.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(selected.enumerated()), id: \.element.id) { index, ex in
                        HStack {
                            Text("\(index + 1).").foregroundStyle(.secondary)
                            Text(ex.name)
                        }
                    }
                    .onDelete { selected.remove(atOffsets: $0) }
                    .onMove { selected.move(fromOffsets: $0, toOffset: $1) }
                } header: {
                    Text("Dein Zirkel (\(selected.count))")
                }

                ForEach(ExerciseCategory.allCases) { category in
                    Section(category.title) {
                        ForEach(store.allExercises.filter { $0.category == category }) { ex in
                            Button {
                                toggle(ex)
                            } label: {
                                HStack {
                                    Text(ex.name).foregroundStyle(.primary)
                                    Spacer()
                                    if selected.contains(where: { $0.id == ex.id }) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "circle").foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quick-Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        running = true
                    } label: {
                        Label("Workout starten", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selected.isEmpty)
                }
            }
            .onAppear { if selected.isEmpty { randomize() } }
            .fullScreenCover(isPresented: $running) {
                CircuitRunView(exercises: selected, rounds: rounds, work: work, rest: rest) {
                    running = false
                    dismiss()
                }
            }
        }
    }

    private func toggle(_ ex: Exercise) {
        if let i = selected.firstIndex(where: { $0.id == ex.id }) {
            selected.remove(at: i)
        } else {
            selected.append(ex)
        }
    }

    private func randomize() {
        let pool = store.allExercises
        let kraft = pool.filter { $0.category == .kraft }.shuffled().prefix(2)
        let core = pool.filter { $0.category == .core }.shuffled().prefix(2)
        let cardio = pool.filter { $0.category == .cardio }.shuffled().prefix(2)
        selected = Array(cardio.prefix(1)) + Array(kraft) + Array(core) + Array(cardio.dropFirst())
    }
}

/// Läuft das Zirkeltraining mit großem Countdown ab.
struct CircuitRunView: View {
    @EnvironmentObject private var store: AppStore
    let exercises: [Exercise]
    let rounds: Int
    let work: Int
    let rest: Int
    var onClose: () -> Void

    @State private var round = 1
    @State private var index = 0
    @State private var isRest = false
    @State private var isCountdown = true
    @State private var remaining = 5
    @State private var paused = false
    @State private var finished = false
    @State private var completedRounds = 0
    @State private var task: Task<Void, Never>?

    private var current: Exercise { exercises[min(index, exercises.count - 1)] }
    private var next: Exercise? {
        if index + 1 < exercises.count { return exercises[index + 1] }
        return round < rounds ? exercises.first : nil
    }

    private var phaseColor: Color {
        if finished { return .green }
        if isCountdown { return .blue }
        return isRest ? .teal : .orange
    }

    var body: some View {
        ZStack {
            phaseColor.opacity(0.15).ignoresSafeArea()
            if finished {
                finishedView
            } else {
                runningView
            }
        }
        .animation(.easeInOut, value: isRest)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            task?.cancel()
        }
    }

    private var runningView: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    task?.cancel()
                    finish(partial: true)
                } label: {
                    Label("Beenden", systemImage: "xmark")
                }
                Spacer()
                Text("Runde \(round)/\(rounds) · Übung \(index + 1)/\(exercises.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            Text(isCountdown ? "Mach dich bereit" : (isRest ? "Pause" : "Los!"))
                .font(.title2.bold())
                .foregroundStyle(phaseColor)

            Text(isRest ? (next?.name ?? "") : current.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if isRest {
                Text("Als Nächstes").foregroundStyle(.secondary)
            }

            ZStack {
                let total = Double(isCountdown ? 5 : (isRest ? rest : work))
                RingView(progress: Double(remaining) / max(total, 1), color: phaseColor, lineWidth: 18)
                Text("\(remaining)")
                    .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
            }
            .frame(width: 240, height: 240)

            if !isRest && !isCountdown {
                Text(current.instructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 30)
            }

            Spacer()

            Button {
                paused.toggle()
            } label: {
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(phaseColor, in: Circle())
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 30)
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Text("🎉").font(.system(size: 90))
            Text("Workout geschafft!").font(.largeTitle.bold())
            Text("\(completedRounds) Runde(n) mit \(exercises.count) Übungen wurden in deinem Verlauf gespeichert.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Fertig", action: onClose)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private func start() {
        task = Task { @MainActor in
            isCountdown = true
            guard await countdown(5) else { return }
            isCountdown = false
            for r in 1...rounds {
                for i in exercises.indices {
                    round = r
                    index = i
                    isRest = false
                    guard await countdown(work) else { return }
                    let isLast = r == rounds && i == exercises.count - 1
                    if !isLast && rest > 0 {
                        isRest = true
                        guard await countdown(rest) else { return }
                    }
                }
                completedRounds = r
            }
            finish(partial: false)
        }
    }

    /// Zählt herunter, false wenn abgebrochen.
    private func countdown(_ seconds: Int) async -> Bool {
        remaining = seconds
        while remaining > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return false }
            if !paused {
                withAnimation { remaining -= 1 }
                if remaining <= 3 && remaining > 0 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return true
    }

    private func finish(partial: Bool) {
        // Vollständige Runden + bei Abbruch die bereits gemachten Übungen der aktuellen Runde
        var logs: [WorkoutLog] = []
        let roundsDone = partial ? max(round - 1, 0) : rounds
        for ex in exercises.enumerated() {
            var setsDone = roundsDone
            if partial && !isCountdown && (ex.offset < index || (ex.offset == index && isRest)) {
                setsDone += 1
            }
            guard setsDone > 0 else { continue }
            var log = store.makeLog(for: ex.element, sets: setsDone, reps: 0, seconds: work)
            // Im Zirkel wird immer auf Zeit trainiert
            log.reps = 0
            log.seconds = work
            log.durationMinutes = Double(setsDone * work) / 60
            log.calories = ex.element.calories(minutes: log.durationMinutes, weightKg: store.profile.weightKg)
            logs.append(log)
        }
        store.addWorkouts(logs)
        completedRounds = roundsDone
        if logs.isEmpty {
            onClose()
        } else {
            finished = true
        }
    }
}
