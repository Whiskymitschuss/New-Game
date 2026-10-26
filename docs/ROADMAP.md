# Meilensteine und offene Arbeit

## v0.1 – spielbarer Kern

Implementiert: Startmenü, Kampf, Physikproduktion, Gates, Munition, Wellen, Upgrades, Sieg/Niederlage, Savegame, lokale Android-Debug-APK, Exportkonfiguration und CI-Workflow. Darüber hinaus technische Grundlagen späterer Meilensteine: Inhaltstabellen, Generator, Klassen, Waffen und Bossvarianten. Lokal getestet bedeutet nicht Android-Gerätetest oder bestätigter GitHub-Actions-Lauf.

## v0.2 – Mechanik und Bossqualität

Weitere Waffenanimationen und echte Flugprojektile, differenziertere Gegner-KI, mehr als ein aktiv angekündigtes Spezialmuster pro Boss, Modul-Kompositionsvalidierung, präzisere Tutorialschritte, Zwischenstandsfortsetzung und systematische Spieltests für Klassenkombinationen. Klassenspezifische Karten sind bereits implementiert; weitere Ausrüstungssynergien folgen.

## v0.3 – Kampagne

Alle 100 Level werden bereits deterministisch erzeugt und geladen. Noch nötig: vollständige Balancing-Durchläufe, Wirtschaftskurve, Loot-/Ausrüstungssystem, Freischaltökonomie für Klassen und Skins, Level-spezifische Ziele und handgeprüfte Bosskämpfe. Die aktuell sofort verfügbaren drei Klassen erleichtern Prototypentests.

## v0.4 – Art und Audio

Die eigenständige Vektor-/Audio-Produktion ist ein Anfang. Weitere Arbeit: umfangreichere Animationen und Silhouetten, detaillierte mehrschichtige Umgebungen mit Kamera-Parallaxe, eigene Klanglandschaften für zehn Welten, professioneller Mix, speziell gestaltete Karten und inventarbezogene Illustrationen.

## v1.0 – Release-Kandidat

Physische Android-Geräte (ARMv7/ARM64), verschiedene Seitenverhältnisse, Touch/Resume/Back, Speicherunterbrechung und Langzeitsessions prüfen; Windows ausführen; Framezeiten und Speicher messen; APK-Größe optimieren; Accessibility und rechtliche Pflichttexte; privater Release-Schlüssel außerhalb des Repositories; reproduzierbare signierte Release-Builds und abschließende QA. Erst danach als Release-Kandidat kennzeichnen.
