import Foundation

/// Häufige Lebensmittel mit ungefähren Nährwerten pro 100 g.
enum FoodLibrary {
    private static func f(_ name: String, _ kcal: Double, _ p: Double, _ c: Double, _ fat: Double) -> FoodItem {
        // Feste IDs aus dem Namen, damit sie über App-Starts stabil bleiben
        let uuid = UUID(uuidString: stableUUID(name)) ?? UUID()
        return FoodItem(id: uuid, name: name, caloriesPer100: kcal, proteinPer100: p, carbsPer100: c, fatPer100: fat)
    }

    private static func stableUUID(_ s: String) -> String {
        var hash: UInt64 = 1469598103934665603
        for b in s.utf8 { hash = (hash ^ UInt64(b)) &* 1099511628211 }
        let hex = String(format: "%016llx", hash)
        return "00000000-0000-4000-8000-\(hex.suffix(12))"
    }

    static let all: [FoodItem] = [
        f("Apfel", 54, 0.3, 11.4, 0.4),
        f("Avocado", 160, 2, 9, 15),
        f("Banane", 93, 1.2, 20, 0.2),
        f("Beeren (gemischt)", 45, 1, 8, 0.4),
        f("Brokkoli", 34, 2.8, 4, 0.4),
        f("Brötchen (Weizen)", 270, 9, 52, 2),
        f("Butter", 741, 0.7, 0.6, 83),
        f("Cola", 42, 0, 10.6, 0),
        f("Döner", 215, 12, 20, 10),
        f("Ei (gekocht)", 155, 13, 1.1, 11),
        f("Erdnussbutter", 588, 25, 20, 50),
        f("Feta", 264, 17, 0.7, 21),
        f("Gouda", 356, 25, 0, 28),
        f("Gurke", 15, 0.6, 2, 0.1),
        f("Hähnchenbrust", 110, 23, 0, 1.5),
        f("Haferflocken", 372, 13.5, 58.7, 7),
        f("Joghurt natur 3,5 %", 64, 3.4, 4.5, 3.5),
        f("Kartoffeln (gekocht)", 72, 2, 15, 0.1),
        f("Lachs", 208, 20, 0, 13),
        f("Linsen (gekocht)", 116, 9, 20, 0.4),
        f("Magerquark", 67, 12, 4, 0.2),
        f("Mandeln", 579, 21, 22, 50),
        f("Milch 1,5 %", 47, 3.4, 4.8, 1.5),
        f("Müsli", 360, 9, 66, 6),
        f("Nudeln (gekocht)", 150, 5, 30, 1),
        f("Olivenöl", 884, 0, 0, 100),
        f("Orangensaft", 45, 0.7, 10, 0.2),
        f("Paprika", 31, 1, 6, 0.3),
        f("Pizza Margherita", 266, 11, 33, 10),
        f("Proteinpulver", 380, 75, 8, 5),
        f("Reis (gekocht)", 130, 2.7, 28, 0.3),
        f("Rinderhack", 250, 17, 0, 20),
        f("Salat (grün)", 15, 1.3, 1.5, 0.2),
        f("Schokolade (Vollmilch)", 535, 7.6, 59, 30),
        f("Skyr", 63, 11, 4, 0.2),
        f("Süßkartoffel", 86, 1.6, 20, 0.1),
        f("Thunfisch (in Wasser)", 116, 26, 0, 1),
        f("Tofu", 76, 8, 1.9, 4.8),
        f("Tomate", 18, 0.9, 3, 0.2),
        f("Vollkornbrot", 215, 7, 39, 1.5),
        f("Wraps (Weizen)", 300, 8, 50, 7),
    ]
}
