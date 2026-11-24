import Foundation

// MARK: - Ernährung

enum MealType: String, Codable, CaseIterable, Identifiable {
    case fruehstueck, mittag, abend, snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fruehstueck: return "Frühstück"
        case .mittag: return "Mittagessen"
        case .abend: return "Abendessen"
        case .snack: return "Snacks"
        }
    }

    var icon: String {
        switch self {
        case .fruehstueck: return "sunrise.fill"
        case .mittag: return "sun.max.fill"
        case .abend: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        }
    }

    /// Mahlzeit passend zur aktuellen Uhrzeit.
    static var suggested: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<11: return .fruehstueck
        case 11..<15: return .mittag
        case 17..<22: return .abend
        default: return .snack
        }
    }
}

/// Ein Lebensmittel mit Nährwerten pro 100 g.
struct FoodItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var caloriesPer100: Double
    var proteinPer100: Double
    var carbsPer100: Double
    var fatPer100: Double
    var isCustom = false

    func entry(grams: Double, meal: MealType, date: Date) -> FoodEntry {
        let f = grams / 100
        return FoodEntry(name: name,
                         grams: grams,
                         calories: caloriesPer100 * f,
                         protein: proteinPer100 * f,
                         carbs: carbsPer100 * f,
                         fat: fatPer100 * f,
                         meal: meal,
                         date: date)
    }
}

/// Ein gegessenes Lebensmittel im Tagebuch.
struct FoodEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var grams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var meal: MealType
    var date: Date
}

// MARK: - Training

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case kraft, core, cardio, dehnung

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kraft: return "Kraft"
        case .core: return "Bauch & Rücken"
        case .cardio: return "Cardio"
        case .dehnung: return "Dehnen & Mobilität"
        }
    }

    var icon: String {
        switch self {
        case .kraft: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .dehnung: return "figure.flexibility"
        }
    }

    /// Typischer MET-Wert (Energieverbrauch) für diese Kategorie.
    var defaultMET: Double {
        switch self {
        case .kraft: return 5
        case .core: return 4
        case .cardio: return 8
        case .dehnung: return 2.3
        }
    }
}

enum ExerciseMeasure: String, Codable, CaseIterable, Identifiable {
    case reps, time
    var id: String { rawValue }
    var title: String { self == .reps ? "Wiederholungen" : "Zeit" }
}

struct Exercise: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var category: ExerciseCategory
    var muscles: String
    var instructions: String
    var measure: ExerciseMeasure
    var met: Double
    var isCustom = false

    /// Verbrannte Kalorien: MET × Körpergewicht (kg) × Stunden
    func calories(minutes: Double, weightKg: Double) -> Double {
        met * weightKg * minutes / 60
    }

    /// Geschätzte Dauer einer Wiederholung in Sekunden.
    static let secondsPerRep = 3.0
}

struct WorkoutLog: Codable, Identifiable, Hashable {
    var id = UUID()
    var exerciseID: String
    var exerciseName: String
    var sets: Int
    var reps: Int          // bei Zeit-Übungen 0
    var seconds: Int       // bei Wiederholungs-Übungen 0 (Dauer pro Satz)
    var durationMinutes: Double
    var calories: Double
    var date: Date

    var summary: String {
        if reps > 0 {
            return "\(sets) × \(reps) Wdh."
        } else {
            return "\(sets) × \(seconds) Sek."
        }
    }
}

// MARK: - Stress

struct StressEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var level: Int          // 1 (entspannt) … 10 (sehr gestresst)
    var note: String
    var date: Date

    static func emoji(for level: Int) -> String {
        switch level {
        case ...2: return "😌"
        case 3...4: return "🙂"
        case 5...6: return "😐"
        case 7...8: return "😣"
        default: return "🤯"
        }
    }

    static func label(for level: Int) -> String {
        switch level {
        case ...2: return "Entspannt"
        case 3...4: return "Ganz okay"
        case 5...6: return "Etwas angespannt"
        case 7...8: return "Gestresst"
        default: return "Sehr gestresst"
        }
    }
}

// MARK: - Profil

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var title: String { self == .male ? "Männlich" : "Weiblich" }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sitzend, leicht, maessig, aktiv, sehrAktiv
    var id: String { rawValue }

    var title: String {
        switch self {
        case .sitzend: return "Kaum aktiv (Bürojob)"
        case .leicht: return "Leicht aktiv (1–2× Sport/Woche)"
        case .maessig: return "Mäßig aktiv (3–4× Sport/Woche)"
        case .aktiv: return "Sehr aktiv (5–6× Sport/Woche)"
        case .sehrAktiv: return "Extrem aktiv (täglich / körperl. Arbeit)"
        }
    }

    var factor: Double {
        switch self {
        case .sitzend: return 1.2
        case .leicht: return 1.375
        case .maessig: return 1.55
        case .aktiv: return 1.725
        case .sehrAktiv: return 1.9
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case abnehmen, halten, aufbauen
    var id: String { rawValue }

    var title: String {
        switch self {
        case .abnehmen: return "Abnehmen"
        case .halten: return "Gewicht halten"
        case .aufbauen: return "Muskeln aufbauen"
        }
    }

    var adjustment: Double {
        switch self {
        case .abnehmen: return -500
        case .halten: return 0
        case .aufbauen: return 300
        }
    }
}

struct Profile: Codable, Hashable {
    var name = ""
    var sex: Sex = .male
    var age = 30
    var heightCm = 175.0
    var weightKg = 75.0
    var activity: ActivityLevel = .leicht
    var goal: FitnessGoal = .halten
    var customCalorieGoal: Double?

    /// Grundumsatz nach Mifflin-St Jeor
    var bmr: Double {
        10 * weightKg + 6.25 * heightCm - 5 * Double(age) + (sex == .male ? 5 : -161)
    }

    /// Gesamtumsatz
    var tdee: Double { bmr * activity.factor }

    var calorieGoal: Double {
        if let custom = customCalorieGoal, custom > 0 { return custom }
        return max(1200, (tdee + goal.adjustment).rounded())
    }

    var proteinGoal: Double { (weightKg * (goal == .aufbauen ? 2.0 : 1.6)).rounded() }
    var fatGoal: Double { (calorieGoal * 0.25 / 9).rounded() }
    var carbsGoal: Double { max(0, ((calorieGoal - proteinGoal * 4 - fatGoal * 9) / 4).rounded()) }

    var bmi: Double {
        let m = heightCm / 100
        return m > 0 ? weightKg / (m * m) : 0
    }
}

// MARK: - Gesamter App-Zustand

struct AppData: Codable {
    var profile = Profile()
    var foods: [FoodEntry] = []
    var customFoods: [FoodItem] = []
    var customExercises: [Exercise] = []
    var workouts: [WorkoutLog] = []
    var stress: [StressEntry] = []
}

extension AppData {
    private var cal: Calendar { Calendar.current }

    func foods(on day: Date) -> [FoodEntry] {
        foods.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    func caloriesEaten(on day: Date) -> Double {
        foods(on: day).reduce(0) { $0 + $1.calories }
    }

    func workouts(on day: Date) -> [WorkoutLog] {
        workouts.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    func caloriesBurned(on day: Date) -> Double {
        workouts(on: day).reduce(0) { $0 + $1.calories }
    }

    func trainingMinutes(on day: Date) -> Double {
        workouts(on: day).reduce(0) { $0 + $1.durationMinutes }
    }

    func stressEntries(on day: Date) -> [StressEntry] {
        stress.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    func averageStress(on day: Date) -> Double? {
        let entries = stressEntries(on: day)
        guard !entries.isEmpty else { return nil }
        return Double(entries.reduce(0) { $0 + $1.level }) / Double(entries.count)
    }

    /// Wie viele Tage am Stück wurde trainiert (heute oder bis gestern)?
    var workoutStreak: Int {
        var day = cal.startOfDay(for: Date())
        if workouts(on: day).isEmpty {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while !workouts(on: day).isEmpty {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }
}

extension Date {
    /// Zeitpunkt für einen Eintrag an einem bestimmten Tag (heute = jetzt, sonst 12 Uhr).
    static func entryDate(for day: Date) -> Date {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return Date() }
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    static func lastDays(_ count: Int) -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<count).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }
}

extension Double {
    var kcal: String { "\(Int(self.rounded())) kcal" }
    var whole: String { "\(Int(self.rounded()))" }
}
