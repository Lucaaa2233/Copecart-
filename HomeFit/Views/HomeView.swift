import SwiftUI
import Charts

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selectedTab: Int

    @State private var showAddFood = false
    @State private var showAddStress = false
    @State private var showBreathing = false
    @State private var showQuickWorkout = false

    private var today: Date { Date() }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = store.profile.name.isEmpty ? "" : ", \(store.profile.name)"
        switch hour {
        case 5..<11: return "Guten Morgen\(name)"
        case 11..<18: return "Hallo\(name)"
        default: return "Guten Abend\(name)"
        }
    }

    var body: some View {
        let data = store.data
        let goal = store.profile.calorieGoal
        let eaten = data.caloriesEaten(on: today)
        let burned = data.caloriesBurned(on: today)
        let remaining = goal - eaten + burned
        let foods = data.foods(on: today)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Kalorien-Ring
                    Card {
                        HStack(spacing: 20) {
                            ZStack {
                                RingView(progress: eaten / max(goal + burned, 1), color: .orange, lineWidth: 16)
                                VStack(spacing: 0) {
                                    Text(max(remaining, 0).whole)
                                        .font(.title.bold())
                                    Text(remaining >= 0 ? "übrig" : "drüber")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 130, height: 130)

                            VStack(alignment: .leading, spacing: 10) {
                                Label("Ziel: \(goal.kcal)", systemImage: "target")
                                Label("Gegessen: \(eaten.kcal)", systemImage: "fork.knife")
                                    .foregroundStyle(.orange)
                                Label("Verbrannt: \(burned.kcal)", systemImage: "flame.fill")
                                    .foregroundStyle(.red)
                            }
                            .font(.subheadline)
                        }
                    }

                    // Makros
                    Card {
                        VStack(spacing: 10) {
                            MacroBar(title: "Eiweiß", value: foods.reduce(0) { $0 + $1.protein }, goal: store.profile.proteinGoal, color: .blue)
                            MacroBar(title: "Kohlenhydrate", value: foods.reduce(0) { $0 + $1.carbs }, goal: store.profile.carbsGoal, color: .green)
                            MacroBar(title: "Fett", value: foods.reduce(0) { $0 + $1.fat }, goal: store.profile.fatGoal, color: .yellow)
                        }
                    }

                    // Kacheln
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatTile(title: "Training heute",
                                 value: "\(data.trainingMinutes(on: today).whole) Min",
                                 icon: "stopwatch.fill", color: .green)
                        StatTile(title: "Tage-Serie",
                                 value: "\(data.workoutStreak) 🔥",
                                 icon: "calendar", color: .orange)
                        StatTile(title: "Stress heute",
                                 value: data.averageStress(on: today).map { String(format: "%.1f / 10", $0) } ?? "–",
                                 icon: "brain.head.profile",
                                 color: data.averageStress(on: today).map { Color.stressColor($0) } ?? .gray)
                        StatTile(title: "Übungen heute",
                                 value: "\(data.workouts(on: today).count)",
                                 icon: "figure.mixed.cardio", color: .purple)
                    }

                    // Schnellaktionen
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Schnell hinzufügen").font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                QuickButton(title: "Essen", icon: "plus.circle.fill", color: .orange) { showAddFood = true }
                                QuickButton(title: "Quick-Workout", icon: "bolt.heart.fill", color: .green) { showQuickWorkout = true }
                                QuickButton(title: "Stress erfassen", icon: "gauge.with.needle", color: .purple) { showAddStress = true }
                                QuickButton(title: "Atemübung", icon: "wind", color: .teal) { showBreathing = true }
                            }
                        }
                    }

                    // Wochenübersicht
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kalorien der letzten 7 Tage").font(.headline)
                            Chart {
                                ForEach(Date.lastDays(7), id: \.self) { day in
                                    BarMark(x: .value("Tag", day, unit: .day),
                                            y: .value("Gegessen", data.caloriesEaten(on: day)))
                                        .foregroundStyle(Color.orange.gradient)
                                        .cornerRadius(6)
                                }
                                RuleMark(y: .value("Ziel", goal))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(Color.gray)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                }
                            }
                            .frame(height: 160)
                        }
                    }

                    // Widget-Hinweis
                    Card {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "apps.iphone.badge.plus")
                                .font(.title)
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auf den Homebildschirm").font(.headline)
                                Text("Halte eine freie Stelle auf dem Homebildschirm gedrückt → „+“ oben links → „HomeFit“ suchen. So siehst du Kalorien & Stress ohne die App zu öffnen.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .sheet(isPresented: $showAddFood) { AddFoodView(day: Date()) }
            .sheet(isPresented: $showAddStress) { AddStressView() }
            .sheet(isPresented: $showBreathing) { BreathingView() }
            .sheet(isPresented: $showQuickWorkout) { CircuitSetupView() }
        }
    }
}

struct QuickButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .font(.subheadline.weight(.semibold))
            .padding(12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
