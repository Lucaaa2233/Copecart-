import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmReset = false

    var body: some View {
        let p = store.profile
        NavigationStack {
            Form {
                ProfileFormSections(profile: $store.data.profile)

                Section("Deine Werte") {
                    LabeledContent("Grundumsatz", value: p.bmr.kcal)
                    LabeledContent("Gesamtumsatz", value: p.tdee.kcal)
                    LabeledContent("BMI", value: String(format: "%.1f", p.bmi))
                    LabeledContent("Tagesziel", value: p.calorieGoal.kcal)
                    LabeledContent("Eiweiß / KH / Fett", value: "\(p.proteinGoal.whole) / \(p.carbsGoal.whole) / \(p.fatGoal.whole) g")
                }

                Section {
                    Toggle("Eigenes Kalorienziel", isOn: Binding(
                        get: { store.data.profile.customCalorieGoal != nil },
                        set: { store.data.profile.customCalorieGoal = $0 ? p.calorieGoal : nil }
                    ))
                    if store.data.profile.customCalorieGoal != nil {
                        Stepper(value: Binding(
                            get: { store.data.profile.customCalorieGoal ?? p.calorieGoal },
                            set: { store.data.profile.customCalorieGoal = $0 }
                        ), in: 1000...5000, step: 50) {
                            Text("Ziel: \(p.calorieGoal.kcal)")
                        }
                    }
                } footer: {
                    Text("Standardmäßig wird dein Ziel automatisch aus Grundumsatz, Aktivität und Ziel berechnet (Mifflin-St-Jeor-Formel).")
                }

                Section {
                    Button("Alle Einträge löschen", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("HomeFit ersetzt keine ärztliche Beratung. Kalorienangaben sind Schätzwerte.")
                }
            }
            .navigationTitle("Profil")
            .confirmationDialog("Wirklich alle Essens-, Trainings- und Stress-Einträge löschen?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) { store.resetAll() }
            }
        }
    }
}

/// Formularfelder für das Profil (auch im Onboarding genutzt).
struct ProfileFormSections: View {
    @Binding var profile: Profile

    var body: some View {
        Section("Über dich") {
            TextField("Vorname", text: $profile.name)
            Picker("Geschlecht", selection: $profile.sex) {
                ForEach(Sex.allCases) { Text($0.title).tag($0) }
            }
            Stepper("Alter: \(profile.age) Jahre", value: $profile.age, in: 12...100)
            Stepper("Größe: \(Int(profile.heightCm)) cm", value: $profile.heightCm, in: 120...230, step: 1)
            Stepper(value: $profile.weightKg, in: 30...250, step: 0.5) {
                Text("Gewicht: \(profile.weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
            }
        }
        Section("Aktivität & Ziel") {
            Picker("Aktivität", selection: $profile.activity) {
                ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.navigationLink)
            Picker("Ziel", selection: $profile.goal) {
                ForEach(FitnessGoal.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }
}
