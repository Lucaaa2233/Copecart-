import SwiftUI
import WidgetKit

@main
struct HomeFitApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

/// Zentraler Datenspeicher der App. Jede Änderung wird gespeichert
/// und das Widget auf dem Homebildschirm aktualisiert.
final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet { save() }
    }

    init() {
        data = Persistence.load()
    }

    private func save() {
        Persistence.save(data)
        WidgetCenter.shared.reloadAllTimelines()
    }

    var profile: Profile { data.profile }

    var allExercises: [Exercise] { ExerciseLibrary.all + data.customExercises }
    var allFoods: [FoodItem] { data.customFoods + FoodLibrary.all }

    // MARK: Essen
    func addFood(_ entry: FoodEntry) { data.foods.append(entry) }
    func deleteFood(_ entry: FoodEntry) { data.foods.removeAll { $0.id == entry.id } }
    func addCustomFood(_ item: FoodItem) { data.customFoods.append(item) }
    func deleteCustomFood(_ item: FoodItem) { data.customFoods.removeAll { $0.id == item.id } }

    // MARK: Training
    func addExercise(_ exercise: Exercise) { data.customExercises.append(exercise) }
    func deleteExercise(_ exercise: Exercise) { data.customExercises.removeAll { $0.id == exercise.id } }
    func addWorkouts(_ logs: [WorkoutLog]) { data.workouts.append(contentsOf: logs) }
    func deleteWorkout(_ log: WorkoutLog) { data.workouts.removeAll { $0.id == log.id } }

    func makeLog(for exercise: Exercise, sets: Int, reps: Int, seconds: Int, date: Date = Date()) -> WorkoutLog {
        let minutes: Double
        if exercise.measure == .reps {
            minutes = Double(sets * reps) * Exercise.secondsPerRep / 60
        } else {
            minutes = Double(sets * seconds) / 60
        }
        return WorkoutLog(exerciseID: exercise.id,
                          exerciseName: exercise.name,
                          sets: sets,
                          reps: exercise.measure == .reps ? reps : 0,
                          seconds: exercise.measure == .time ? seconds : 0,
                          durationMinutes: minutes,
                          calories: exercise.calories(minutes: minutes, weightKg: profile.weightKg),
                          date: date)
    }

    // MARK: Stress
    func addStress(_ entry: StressEntry) { data.stress.append(entry) }
    func deleteStress(_ entry: StressEntry) { data.stress.removeAll { $0.id == entry.id } }

    func resetAll() {
        let profile = data.profile
        data = AppData()
        data.profile = profile
    }
}
