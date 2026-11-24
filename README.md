# HomeFit 🏠💪 – Fitness für zuhause (iOS)

Native iPhone-App (SwiftUI, iOS 17+) mit:

| Bereich | Funktionen |
|---|---|
| **Home** | Tagesübersicht: Kalorien-Ring (Ziel − gegessen + verbrannt), Makros, Trainingsminuten, Serie 🔥, Stress-Level, 7-Tage-Diagramm, Schnellaktionen |
| **Essen** | Kalorien rechnen: 40+ Lebensmittel (Werte pro 100 g) mit Grammangabe, eigene Lebensmittel speichern, Schnelleintrag nur mit kcal, Mahlzeiten, frühere Tage ansehen |
| **Training** | 27 Übungen ohne Geräte (Kraft, Bauch/Rücken, Cardio, Dehnen) mit Anleitung, **eigene Übungen hinzufügen**, Sätze/Wdh. eintragen inkl. kcal-Schätzung (MET), **Quick-Workout** mit Timer, Verlauf |
| **Stress** | Stresslevel 1–10 mit Notiz erfassen, 14-Tage-Verlauf, 3 geführte Atemübungen (Box, 4-7-8, 5-5), Anti-Stress-Tipps |
| **Profil** | Alter, Größe, Gewicht, Aktivität, Ziel → automatisches Kalorien- & Makroziel (Mifflin-St-Jeor) |
| **Homebildschirm-Widget** | Klein & mittel + Sperrbildschirm: übrige kcal, verbrannt, Training, Stress |

## App auf dein iPhone bringen

Du brauchst einen **Mac mit Xcode 15 oder neuer** (kostenlos im App Store).

1. Repository auf den Mac klonen bzw. herunterladen.
2. XcodeGen installieren und das Xcode-Projekt erzeugen:
   ```bash
   brew install xcodegen   # einmalig (Homebrew: https://brew.sh)
   cd Copecart-
   xcodegen generate
   open HomeFit.xcodeproj
   ```
3. In Xcode links das Projekt **HomeFit** anklicken → für **beide** Targets (`HomeFit` und `HomeFitWidget`) unter
   **Signing & Capabilities** dein Team (Apple-ID) auswählen.
4. Falls Xcode meckert, dass die Bundle-ID oder App Group schon vergeben ist: eigene Namen wählen, z. B.
   `de.deinname.homefit` / `de.deinname.homefit.widget` und App Group `group.de.deinname.homefit`.
   Die App Group dann auch in `Shared/Persistence.swift` (`appGroupID`) anpassen.
5. iPhone per Kabel verbinden, oben als Ziel auswählen und ▶︎ drücken.
   Beim ersten Mal auf dem iPhone: *Einstellungen → Allgemein → VPN & Geräteverwaltung → Entwickler-App vertrauen*.

### Widget auf den Homebildschirm
Freie Stelle auf dem Homebildschirm gedrückt halten → **+** oben links → „HomeFit“ suchen → Größe wählen → *Widget hinzufügen*.

## Projektstruktur

```
project.yml              XcodeGen-Projektdefinition
Shared/                  Von App & Widget gemeinsam genutzt (Modelle, Speicherung, Ring)
HomeFit/                 Die App
  HomeFitApp.swift       Einstieg + AppStore (Datenspeicher)
  Data/                  Übungs- und Lebensmittel-Bibliothek
  Views/                 Home, Essen, Training, Quick-Workout, Stress, Profil
HomeFitWidget/           Homebildschirm-Widget
```

Alle Daten bleiben lokal auf dem Gerät (JSON in der App Group, damit das Widget sie lesen kann).

> Hinweis: Kalorienwerte sind Schätzungen. Die App ersetzt keine ärztliche Beratung.
