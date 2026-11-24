import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject private var store: AppStore
    @State private var mode = 0
    @State private var search = ""
    @State private var showAddExercise = false
    @State private var showCircuit = false

    var body: some View {
        NavigationStack {
            List {
                Picker("Ansicht", selection: $mode) {
                    Text("Übungen").tag(0)
                    Text("Verlauf").tag(1)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if mode == 0 {
                    exercisesContent
                } else {
                    historyContent
                }
            }
            .navigationTitle("Training")
            .searchable(text: $search, prompt: "Übung suchen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddExercise = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) { AddExerciseView() }
            .sheet(isPresented: $showCircuit) { CircuitSetupView() }
        }
    }

    // MARK: Übungen

    @ViewBuilder
    private var exercisesContent: some View {
        Section {
            Button { showCircuit = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading) {
                        Text("Quick-Workout starten").font(.headline)
                        Text("Zirkeltraining mit Timer – ohne Geräte")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }

        ForEach(ExerciseCategory.allCases) { category in
            let items = store.allExercises.filter {
                $0.category == category && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
            }
            if !items.isEmpty {
                Section {
                    ForEach(items) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                    }
                } header: {
                    Label(category.title, systemImage: category.icon)
                }
            }
        }
    }

    // MARK: Verlauf

    private var groupedLogs: [(day: Date, logs: [WorkoutLog])] {
        Dictionary(grouping: store.data.workouts) { Calendar.current.startOfDay(for: $0.date) }
            .map { (day: $0.key, logs: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    @ViewBuilder
    private var historyContent: some View {
        if store.data.workouts.isEmpty {
            Section {
                ContentUnavailableView("Noch kein Training",
                                       systemImage: "figure.walk",
                                       description: Text("Wähle eine Übung aus und trage sie ein – oder starte ein Quick-Workout."))
            }
        }
        ForEach(groupedLogs, id: \.day) { group in
            Section {
                ForEach(group.logs) { log in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(log.exerciseName)
                            Text("\(log.summary) · \(log.date.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(log.calories.kcal)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .swipeActions {
                        Button(role: .destructive) { store.deleteWorkout(log) } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text(group.day.formatted(.dateTime.weekday(.wide).day().month()))
                    Spacer()
                    Text("\(group.logs.reduce(0) { $0 + $1.durationMinutes }.whole) Min · \(group.logs.reduce(0) { $0 + $1.calories }.kcal)")
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.category.icon)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(exercise.name)
                    if exercise.isCustom {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    }
                }
                Text(exercise.muscles)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Detail & Eintragen

struct ExerciseDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    @State private var sets = 3
    @State private var reps = 12
    @State private var seconds = 30
    @State private var saved = false

    var body: some View {
        let log = store.makeLog(for: exercise, sets: sets, reps: reps, seconds: seconds)
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(exercise.category.title, systemImage: exercise.category.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                    Text("Muskeln: \(exercise.muscles)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(exercise.instructions)
                }
                .padding(.vertical, 4)
            }

            Section("Training eintragen") {
                Stepper("Sätze: \(sets)", value: $sets, in: 1...20)
                if exercise.measure == .reps {
                    Stepper("Wiederholungen: \(reps)", value: $reps, in: 1...200)
                } else {
                    Stepper("Dauer pro Satz: \(seconds) Sek.", value: $seconds, in: 5...1800, step: 5)
                }
                LabeledContent("Dauer gesamt", value: "\(log.durationMinutes.formatted(.number.precision(.fractionLength(1)))) Min")
                LabeledContent("Verbrannt (ca.)", value: log.calories.kcal)
                Button {
                    store.addWorkouts([log])
                    saved = true
                } label: {
                    Label("Eintragen", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
            }

            if exercise.isCustom {
                Section {
                    Button("Übung löschen", role: .destructive) {
                        store.deleteExercise(exercise)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .alert("Eingetragen! 💪", isPresented: $saved) {
            Button("Super") {}
        } message: {
            Text("\(exercise.name): \(log.summary), ca. \(log.calories.kcal)")
        }
    }
}

// MARK: - Eigene Übung hinzufügen

struct AddExerciseView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ExerciseCategory = .kraft
    @State private var muscles = ""
    @State private var instructions = ""
    @State private var measure: ExerciseMeasure = .reps
    @State private var intensity = 1 // 0 leicht, 1 mittel, 2 hart

    private var met: Double {
        let base = category.defaultMET
        switch intensity {
        case 0: return base * 0.75
        case 2: return base * 1.3
        default: return base
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Übung") {
                    TextField("Name (z. B. Bergsteiger am Sofa)", text: $name)
                    Picker("Kategorie", selection: $category) {
                        ForEach(ExerciseCategory.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    TextField("Trainierte Muskeln", text: $muscles)
                }
                Section("Messung") {
                    Picker("Gemessen in", selection: $measure) {
                        ForEach(ExerciseMeasure.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Anstrengung", selection: $intensity) {
                        Text("Leicht").tag(0)
                        Text("Mittel").tag(1)
                        Text("Hart").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Anleitung (optional)") {
                    TextField("Wie wird die Übung ausgeführt?", text: $instructions, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Neue Übung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.addExercise(Exercise(name: name.trimmingCharacters(in: .whitespaces),
                                                   category: category,
                                                   muscles: muscles.isEmpty ? "–" : muscles,
                                                   instructions: instructions.isEmpty ? "Eigene Übung" : instructions,
                                                   measure: measure,
                                                   met: met,
                                                   isCustom: true))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
