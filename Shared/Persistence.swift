import Foundation

/// Speichert alle Daten als JSON in der App Group,
/// damit das Homebildschirm-Widget sie ebenfalls lesen kann.
enum Persistence {
    /// Muss mit der App Group in den .entitlements-Dateien übereinstimmen.
    static let appGroupID = "group.de.homefit.app"

    static var fileURL: URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return container.appendingPathComponent("homefit-data.json")
        }
        // Fallback (z. B. wenn App Group noch nicht eingerichtet ist)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("homefit-data.json")
    }

    static func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else {
            return AppData()
        }
        return decoded
    }

    static func save(_ appData: AppData) {
        do {
            let data = try JSONEncoder().encode(appData)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("HomeFit: Speichern fehlgeschlagen – \(error)")
        }
    }
}
