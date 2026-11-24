import SwiftUI

struct NutritionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var day = Date()
    @State private var showAdd = false

    private let cal = Calendar.current

    var body: some View {
        let entries = store.data.foods(on: day)
        let eaten = entries.reduce(0) { $0 + $1.calories }
        let burned = store.data.caloriesBurned(on: day)
        let goal = store.profile.calorieGoal

        NavigationStack {
            List {
                // Tag wählen
                Section {
                    HStack {
                        Button { shiftDay(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(dayTitle)
                            .font(.headline)
                        Spacer()
                        Button { shiftDay(1) } label: { Image(systemName: "chevron.right") }
                            .disabled(cal.isDateInToday(day))
                    }
                    .buttonStyle(.borderless)
                }

                // Rechnung
                Section("Kalorien-Rechnung") {
                    CalcRow(label: "Ziel", value: goal.kcal)
                    CalcRow(label: "− Gegessen", value: eaten.kcal, color: .orange)
                    CalcRow(label: "+ Training", value: burned.kcal, color: .red)
                    let rest = goal - eaten + burned
                    CalcRow(label: rest >= 0 ? "= Noch übrig" : "= Überschritten",
                            value: abs(rest).kcal,
                            color: rest >= 0 ? .green : .red,
                            bold: true)
                    VStack(spacing: 8) {
                        MacroBar(title: "Eiweiß", value: entries.reduce(0) { $0 + $1.protein }, goal: store.profile.proteinGoal, color: .blue)
                        MacroBar(title: "Kohlenhydrate", value: entries.reduce(0) { $0 + $1.carbs }, goal: store.profile.carbsGoal, color: .green)
                        MacroBar(title: "Fett", value: entries.reduce(0) { $0 + $1.fat }, goal: store.profile.fatGoal, color: .yellow)
                    }
                    .padding(.vertical, 4)
                }

                // Mahlzeiten
                ForEach(MealType.allCases) { meal in
                    let mealEntries = entries.filter { $0.meal == meal }.sorted { $0.date < $1.date }
                    Section {
                        if mealEntries.isEmpty {
                            Text("Noch nichts eingetragen")
                                .foregroundStyle(.tertiary)
                        }
                        ForEach(mealEntries) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(entry.name)
                                    Spacer()
                                    Text(entry.calories.kcal).bold()
                                }
                                Text("\(entry.grams.whole) g · E \(entry.protein.whole) g · KH \(entry.carbs.whole) g · F \(entry.fat.whole) g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.deleteFood(entry)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Label(meal.title, systemImage: meal.icon)
                            Spacer()
                            Text(mealEntries.reduce(0) { $0 + $1.calories }.kcal)
                        }
                    }
                }
            }
            .navigationTitle("Essen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddFoodView(day: day)
            }
        }
    }

    private var dayTitle: String {
        if cal.isDateInToday(day) { return "Heute" }
        if cal.isDateInYesterday(day) { return "Gestern" }
        return day.formatted(.dateTime.weekday(.wide).day().month())
    }

    private func shiftDay(_ value: Int) {
        if let d = cal.date(byAdding: .day, value: value, to: day) {
            day = d
        }
    }
}

private struct CalcRow: View {
    var label: String
    var value: String
    var color: Color = .primary
    var bold = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(color)
        }
        .fontWeight(bold ? .bold : .regular)
    }
}

// MARK: - Essen hinzufügen

struct AddFoodView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    var day: Date

    @State private var search = ""

    private var filtered: [FoodItem] {
        let all = store.allFoods
        guard !search.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CustomFoodView(day: day, prefillName: search) { dismiss() }
                    } label: {
                        Label("Eigenes Lebensmittel eintragen", systemImage: "square.and.pencil")
                    }
                    NavigationLink {
                        QuickCaloriesView(day: day) { dismiss() }
                    } label: {
                        Label("Nur Kalorien schnell eintragen", systemImage: "bolt.fill")
                    }
                }

                Section("Lebensmittel · Werte pro 100 g") {
                    ForEach(filtered) { item in
                        NavigationLink {
                            FoodAmountView(item: item, day: day) { dismiss() }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                    Text("E \(item.proteinPer100.whole) · KH \(item.carbsPer100.whole) · F \(item.fatPer100.whole)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if item.isCustom {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                                }
                                Text(item.caloriesPer100.kcal)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if item.isCustom {
                                Button(role: .destructive) { store.deleteCustomFood(item) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Lebensmittel suchen")
            .navigationTitle("Essen hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

struct FoodAmountView: View {
    @EnvironmentObject private var store: AppStore
    let item: FoodItem
    let day: Date
    var onDone: () -> Void

    @State private var grams: Double = 100
    @State private var meal: MealType = .suggested

    var body: some View {
        let entry = item.entry(grams: grams, meal: meal, date: Date.entryDate(for: day))
        Form {
            Section("Menge") {
                HStack {
                    TextField("Gramm", value: $grams, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                    Text("g").foregroundStyle(.secondary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach([30.0, 50, 100, 150, 200, 250, 300], id: \.self) { g in
                            Button("\(Int(g)) g") { grams = g }
                                .buttonStyle(.bordered)
                                .tint(grams == g ? Color.accentColor : Color.gray)
                        }
                    }
                }
            }
            Section("Mahlzeit") {
                Picker("Mahlzeit", selection: $meal) {
                    ForEach(MealType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Nährwerte") {
                LabeledContent("Kalorien", value: entry.calories.kcal)
                LabeledContent("Eiweiß", value: "\(entry.protein.whole) g")
                LabeledContent("Kohlenhydrate", value: "\(entry.carbs.whole) g")
                LabeledContent("Fett", value: "\(entry.fat.whole) g")
            }
            Section {
                Button {
                    store.addFood(entry)
                    onDone()
                } label: {
                    Text("Hinzufügen").frame(maxWidth: .infinity).bold()
                }
                .disabled(grams <= 0)
            }
        }
        .navigationTitle(item.name)
    }
}

struct CustomFoodView: View {
    @EnvironmentObject private var store: AppStore
    let day: Date
    var prefillName = ""
    var onDone: () -> Void

    @State private var name = ""
    @State private var kcal: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var grams: Double = 100
    @State private var meal: MealType = .suggested
    @State private var saveToLibrary = true

    var body: some View {
        let item = FoodItem(name: name.trimmingCharacters(in: .whitespaces),
                            caloriesPer100: kcal, proteinPer100: protein,
                            carbsPer100: carbs, fatPer100: fat, isCustom: true)
        Form {
            Section("Lebensmittel") {
                TextField("Name (z. B. Omas Lasagne)", text: $name)
            }
            Section("Nährwerte pro 100 g (steht auf der Packung)") {
                NumberRow(label: "Kalorien (kcal)", value: $kcal)
                NumberRow(label: "Eiweiß (g)", value: $protein)
                NumberRow(label: "Kohlenhydrate (g)", value: $carbs)
                NumberRow(label: "Fett (g)", value: $fat)
            }
            Section("Gegessene Menge") {
                NumberRow(label: "Menge (g)", value: $grams)
                Picker("Mahlzeit", selection: $meal) {
                    ForEach(MealType.allCases) { Text($0.title).tag($0) }
                }
                LabeledContent("Ergebnis", value: (kcal * grams / 100).kcal)
            }
            Section {
                Toggle("In meiner Liste speichern", isOn: $saveToLibrary)
                Button {
                    if saveToLibrary { store.addCustomFood(item) }
                    store.addFood(item.entry(grams: grams, meal: meal, date: Date.entryDate(for: day)))
                    onDone()
                } label: {
                    Text("Hinzufügen").frame(maxWidth: .infinity).bold()
                }
                .disabled(item.name.isEmpty || grams <= 0)
            }
        }
        .navigationTitle("Eigenes Lebensmittel")
        .onAppear { if name.isEmpty { name = prefillName } }
    }
}

struct QuickCaloriesView: View {
    @EnvironmentObject private var store: AppStore
    let day: Date
    var onDone: () -> Void

    @State private var name = ""
    @State private var kcal: Double = 0
    @State private var meal: MealType = .suggested

    var body: some View {
        Form {
            Section {
                TextField("Was hast du gegessen?", text: $name)
                NumberRow(label: "Kalorien (kcal)", value: $kcal)
                Picker("Mahlzeit", selection: $meal) {
                    ForEach(MealType.allCases) { Text($0.title).tag($0) }
                }
            }
            Section {
                Button {
                    let title = name.trimmingCharacters(in: .whitespaces)
                    store.addFood(FoodEntry(name: title.isEmpty ? "Schnelleintrag" : title,
                                            grams: 0, calories: kcal, protein: 0, carbs: 0, fat: 0,
                                            meal: meal, date: Date.entryDate(for: day)))
                    onDone()
                } label: {
                    Text("Hinzufügen").frame(maxWidth: .infinity).bold()
                }
                .disabled(kcal <= 0)
            }
        }
        .navigationTitle("Schnell eintragen")
    }
}

struct NumberRow: View {
    var label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
        }
    }
}
