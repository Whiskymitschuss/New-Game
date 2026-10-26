# DEADWAVE HEROES · RF Worlds

Spielbarer Godot-4.6.3-Prototyp **v0.2.0**, Android und Windows, Hochformat 540 × 960. Eigenständige generierte Sci-Fi-Illustrationen und skalierbare Vektoroberfläche und synthetisierte Originalmusik. Vollständig offline, keine Werbung, keine In-App-Käufe.

## Spielen

1. Einsatz starten. Oben kämpft der Held automatisch und verbraucht echte Munition.
2. Den Schieberegler über dem unteren Spielfeld ziehen und **ABWERFEN** drücken. Die Abwurfversuche sind begrenzt; jede neue Welle gewährt zwei weitere.
3. Echte Physikkugeln passieren unterschiedlich starke Multiplikatoren. Links/rechts gewählte Wege ändern die Produktionsmenge. Der Sammler schreibt die repräsentierte Menge als Munition gut, bis zur Kapazität.
4. Zwischen Wellen eine kostenlose Verbesserung wählen. **IMPULS** verbraucht 50 Energie, trifft Gegner und erzeugt einen Schutzschild. Bei Bosswarnungen einsetzen.
5. Einsätze abschließen, Sterne und Münzen verdienen. Im Arsenal Waffen ausrüsten und dauerhaft verbessern. Alle drei Klassen sind im Prototyp sofort verfügbar.

Die Levelkarte enthält 100 feste, gespeicherte Layouts in zehn Welten. Waffen werden über den Fortschritt freigeschaltet; an Bosslevel gebundene Waffen erfordern den Sieg über diesen Boss. Aufgeben ist über Pause möglich. Laufende Einsätze werden beim Verlassen nicht wiederaufgenommen; dauerhafte Belohnungen und Freischaltungen bleiben erhalten.

## Android installieren

**[APK direkt herunterladen](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.0-debug/DeadwaveHeroes-v0.2.0-debug.apk)** · [Downloadseite](https://github.com/Whiskymitschuss/New-Game/releases/tag/v0.2.0-debug). Dieser öffentliche Download benötigt keinen GitHub-Login und kein Entpacken eines Actions-Archivs.

Die erzeugte Datei ist `builds/DeadwaveHeroes-v0.2.0-debug.apk` (Android 7/API 24 oder neuer; ARMv7/ARM64). APK aufs Smartphone übertragen, öffnen und bei Bedarf die Installation aus dieser Quelle erlauben. Das ist eine **Debug-Testversion**, keine Veröffentlichungsversion. Keine Release-Signierschlüssel liegen im Repository. Für Updates muss derselbe lokale Debug-Schlüssel verwendet werden; CI verwendet den im Actions-Cache gespeicherten Debug-Schlüssel erneut. Geht dieser Cache verloren, kann ein späterer Testbuild eine Deinstallation erfordern. Dabei geht der lokale Spielstand verloren.

**Neon Update 0.2.0:** Der wiederholte Abwurf wird im Physikserver korrekt zurückgesetzt; 24 Abwürfe mit denselben Poolkörpern werden in beiden Qualitätsstufen geprüft. Neue detaillierte Helden-/Gegnergrafiken, eigene Sci-Fi-Stadt, futuristisches HUD, Reaktor-Labyrinth, Klassenporträts und dreispaltige Upgrade-Karten sind integriert. Die Oberfläche skaliert als Vektor-/Canvas-UI; echte Vorschauen mit 2160 × 3840 Pixeln stehen unter `docs/screenshots/neon-*-4k.png`. Das ist ein Nachweis der hochauflösenden Darstellung, keine Zusage von 4K/60 FPS auf einem Smartphone.

Das Savegame-Format ist unverändert. Debug-Schlüssel werden seit v0.1.1 im Buildcache wiederverwendet; der Zertifikatsvergleich der veröffentlichten APKs bestätigt für v0.2.0 dieselbe Signieridentität wie v0.1.1. Das neue APK kann als Update installiert werden; nicht vorher deinstallieren.

Nach einem erfolgreichen GitHub-Actions-Lauf steht die APK unter **Actions → Build DEADWAVE HEROES → letzter erfolgreicher Lauf → Artifacts → DeadwaveHeroes-v0.2.0-debug**. Ein vorhandener Workflow ist kein Nachweis eines erfolgten Remote-Laufs; siehe `docs/BUILD_REPORT.md`.

## Entwicklung und Builds (Linux)

Voraussetzungen: Python 3.11+, curl, JDK 17/21, Godot 4.6.3 oder Netzwerkmöglichkeit zum Herunterladen. Rund 4 GB freier Speicher für Tools, Vorlagen und Builds.

```bash
python3 scripts/bootstrap.py
source /workspace/tools/env.sh
./scripts/build.sh
```

Andere Toolverzeichnisse: `DEADWAVE_TOOLS=/gewünschter/pfad python3 scripts/bootstrap.py`, anschließend die dort erzeugte `env.sh` laden. Bootstrap prüft die Godot-Downloads anhand der offiziellen SHA-512-Liste und die Android-CLI anhand der offiziellen Google-Archivprüfsumme. Es verändert keine Projektdateien und verlangt keine Root-Rechte. Vorhandene Abhängigkeiten werden wiederverwendet. Das Skript akzeptiert die Android-SDK-Lizenzen für die benötigten Werkzeuge; deren Bedingungen stehen in der SDK-Ausgabe und im SDK-Verzeichnis `licenses/`.

```bash
source /workspace/tools/env.sh
"$GODOT_BIN" --path .                 # Spiel starten, grafische Sitzung erforderlich
"$GODOT_BIN" --editor --path .        # Editor
./scripts/check.sh                    # isolierte automatisierte Tests
```

`build.sh` importiert Ressourcen, prüft Scripts, führt die Spieltests aus, exportiert eine Debug-APK und eine Windows-x64-EXE, prüft APK-Signatur und 16-KB-ZIP-Ausrichtung und erzeugt Prüfsummen. Die Windows-ZIP enthält die EXE mit eingebettetem PCK. Der getestete Linux-Exporter verwendet das offizielle Android-Template ohne Gradle-Neubau.

## Implementierte Systeme

- Gleichzeitiger Kampf und Physikproduktion; feste Pools mit höchstens 128 Physikobjekten (64 in Sparqualität), keine Kugel-zu-Kugel-Kollisionen. Exakte ganzzahlige virtuelle Gewichte, Splitting ohne Mengenverlust, bis zu drei Gates pro Layout. Alle geforderten Multiplikatoren vorhanden. Kapazitätsüberschuss wird bewusst nicht als Munition übernommen.
- Zehn Labyrinthmechaniken mit je drei Konfigurationen: Rampen, Pins, Rotoren, Wände, Portale, Beschleuniger, Bonusfelder, Falltüren, Richtungswechsler und zerstörbare Balken. 30 kombinierbare Konfigurationen, nicht 30 vollständig unterschiedliche Mechaniken. Ab Level 50 fünf statt drei Module.
- Drei Klassen, zwölf konfigurierbare Waffen mit unterschiedlichen Schadens-/Reichweiten-/Nachlade-/Effektwerten und Sounds, 48 funktionale Upgrade-Karten einschließlich klassenspezifischer Karten.
- 15 Gegnertypen; Angriffe, Statusschaden, Panzerung, Fernangriffe ab Level 20. Zehn parametrisierte Bossbegegnungen mit unterschiedlicher Spezialfähigkeit, Warnung und zweiter Phase.
- 100 reproduzierbare und gespeicherte Level, fünf bis vierzehn Wellen, Progression, Waffenverbesserung, Klassen-/Waffenauswahl, Outfits, Charakterwerte, Pause, Sieg, Niederlage, Musik-/Effektregler.
- Versionierter JSON-Spielstand mit temporärer Datei, Backup und Wiederherstellung. Level-Layouts, Seeds, Sterne, XP, Münzen, Entdeckungen, Klassen, Waffenverbesserungen, Statistiken und Einstellungen werden gespeichert. Abgeworfene Run-Upgrades gelten für den aktuellen Einsatz.

## Design und Regressionstests

`tests/reuse.gd` prüft das wiederholte Recycling derselben Physikkörper (120 Assertions). `tests/ui_layout.gd` prüft alle 48 Upgrade-Karten und die Klassenporträts (228 Assertions). `tests/render_balls.gd` prüft echte sichtbare Bildpunkte und vier aufeinanderfolgende gerenderte Abwürfe (17 Assertions, grafische Sitzung erforderlich). Die bestehende Suite enthält weitere 314 Assertions; dazu kommen drei vollständige Tutorial-Durchläufe.

```bash
# In einer vorhandenen grafischen Sitzung, nachdem env.sh geladen wurde:
"$GODOT_BIN" --path . --audio-driver Dummy --fixed-fps 60 --script res://tests/render_balls.gd
"$GODOT_BIN" --path . --audio-driver Dummy --fixed-fps 60 --script res://tests/capture.gd -- --4k
```

Die Capture-Szene stellt Gegner für reproduzierbare UI-Aufnahmen auf. Sie verwendet echte Spielressourcen, Physik und Menüs. Details zu Assetauflösungen und visuellen Grenzen: `docs/ART_DIRECTION.md`.

## Bewusster Entwicklungsstand

Dies ist **kein fertiges v1.0-Spiel**. Die Inhaltszahl ist technisch vorhanden; das beweist nicht, dass alle 100 Level unter menschlichen Spielbedingungen ausbalanciert oder alle Bossbegegnungen ausreichend abwechslungsreich sind. Die Waffen verwenden direkte Treffer mit sichtbaren Schussspuren und Status-/Flächeneffekten; physikalisch fliegende Raketen und Granaten sind weitere Arbeit. Gegner und Bosse nutzen gemeinsame Animations-/Spritebausteine. Das Neon-Design ist ein umfassender visueller Ausbau, aber die Rasterfiguren haben noch keine vollständig gezeichneten Animationssequenzen. Audio und einzelne Weltvarianten benötigen weitere Art-Produktion. Eine separate Ausrüstungsbeute-/Skinfreischaltungsökonomie, mehr Boss-Angriffsmuster, Welt-Ambiences, detaillierte Tutorialführung, Gerätemessungen und Releasevorbereitung fehlen noch. Keine Android-Gerätetests und keine Windows-Ausführung sind durch den Linux-Export allein nachgewiesen.

Siehe `docs/ROADMAP.md`, `docs/BUILD_REPORT.md` und `docs/ARCHITECTURE.md`.

## Lizenzen

Spielcode und eigens erzeugte Spielgrafiken/-töne: RF Worlds, alle Rechte vorbehalten. Schriften: Space Grotesk und JetBrains Mono (SIL Open Font License), DejaVu-Lizenz zusätzlich erhalten; Lizenzdateien unter `assets/fonts/` und im Offline-Creditsmenü. Godot und Android-Buildwerkzeuge behalten ihre jeweiligen Lizenzen; Godot-Hinweise unter https://godotengine.org/license/ und in `docs/THIRD_PARTY.md`.
