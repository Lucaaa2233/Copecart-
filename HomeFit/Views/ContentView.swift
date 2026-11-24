import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectedTab: $tab)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            NutritionView()
                .tabItem { Label("Essen", systemImage: "fork.knife") }
                .tag(1)
            WorkoutView()
                .tabItem { Label("Training", systemImage: "figure.strengthtraining.traditional") }
                .tag(2)
            StressView()
                .tabItem { Label("Stress", systemImage: "brain.head.profile") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .fullScreenCover(isPresented: Binding(get: { !onboardingDone }, set: { _ in })) {
            OnboardingView { onboardingDone = true }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    var onFinish: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Willkommen bei HomeFit 💪")
                            .font(.title2.bold())
                        Text("Training für zuhause, Kalorien rechnen und Stress im Blick – alles in einer App. Erzähl uns kurz etwas über dich, damit wir dein Kalorienziel berechnen können.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                ProfileFormSections(profile: $store.data.profile)
                Section {
                    Button {
                        onFinish()
                    } label: {
                        Text("Los geht's")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Dein Profil")
        }
    }
}

// MARK: - Wiederverwendbare Bausteine

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct StatTile: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct MacroBar: View {
    var title: String
    var value: Double
    var goal: Double
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.weight(.semibold))
                Spacer()
                Text("\(value.whole) / \(goal.whole) g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(value, goal), total: max(goal, 1))
                .tint(color)
        }
    }
}
