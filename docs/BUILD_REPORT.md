# Build- und Prüfbericht · v0.1.0

Datum: 26. Oktober 2026. Arbeitsumgebung: Linux x86-64, Godot 4.6.3.stable.official, OpenJDK 21.0.12.1, Android SDK Build Tools 35.0.1, offizielle SHA-512-geprüfte Godot-Exportvorlagen.

## Tatsächlich ausgeführt

- Godot-Ressourcenimport und Scriptprüfung ohne Parse-/Scriptfehler.
- **314 Assertions bestanden, 0 fehlgeschlagen.** Alle 100 Level werden deterministisch erzeugt und mit ihrer Physikgeometrie geladen; 48 Upgrades verändern Werte; zwölf Waffen verursachen Schaden, verbrauchen Munition und laden nach; zehn Bossvarianten kündigen Angriffe an und wechseln in Phase zwei; Physikkugeln passieren Gates und erreichen den Sammler; `10 × 3 × 5 = 150` bleibt beim repräsentativen Splitting exakt; 1.000 Emissionsversuche überschreiten 128 Körper nicht; Gegner greifen an, Sieg schaltet Level frei, Niederlage wird ausgelöst, Savegame und Backup-Wiederherstellung funktionieren.
- **Tutoriallevel 1, 2 und 3 ohne veränderte Kampfwerte vollständig durchgespielt.** Physikabwurf, Munition, Schüsse, alle fünf Wellen, Upgrade-Buttons und abschließender Sieg. Jeweils 30 Abschüsse; simulierte Durchlaufzeiten stehen in `builds/test-campaign.log`. Diese automatisierte Strategie ersetzt keine menschlichen Spieltests.
- Grafische Linux-Ausführung mit OpenGL Compatibility / Mesa llvmpipe. Hauptmenü, Kampfdarstellung und Upgrade-Auswahl visuell geprüft. Screenshots im Ordner `docs/screenshots/` stammen aus dem laufenden Spiel.
- Android-Debug-APK tatsächlich lokal exportiert. `apksigner verify --verbose` bestätigt V2- und V3-Signatur. `zipalign -c -P 16 -v 4` bestätigt die ZIP-Ausrichtung. Manifest: `com.rfworlds.deadwaveheroes`, Version 0.1.0 / Code 1, Minimum API 24, Target API 36, ARMv7 und ARM64, Hochformat, keine Internetberechtigung.
- Windows-x64-Debug-EXE mit eingebetteten Ressourcen tatsächlich exportiert und als ZIP verpackt. Keine Windows-Ausführung in dieser Linux-Umgebung.
- Frische Toolinstallation in einem zweiten leeren Toolverzeichnis erfolgreich ausgeführt, einschließlich heruntergeladener und SHA-512-geprüfter Godot-Linux-Binärdatei, Exportvorlagen, Android CLI und SDK-Pakete.
- Wiederholbarer Ablauf: `python3 scripts/bootstrap.py`, erzeugte `env.sh` laden, `scripts/build.sh`. Buildprotokolle und SHA-256/Dateigrößen stehen in `builds/` und `builds/manifest.json`. APK-/Windows-Dateien bleiben generierte Ausgaben und werden nicht ins Git-Repository aufgenommen.

## Behobene Probleme

- Android-Export erforderte zusätzlich aktivierte ETC2/ASTC-Importunterstützung; im Projekt gesetzt.
- Schreibgeschützte Standardverzeichnisse für Editor- und Buildzustand: Godot-/SDK-/Cache-Verzeichnisse unter `/workspace/tools` konfiguriert. Die optionale automatische ADB-Gerätesuche versucht weiterhin `~/.android` anzulegen; in dieser eingeschränkten Maschine erscheint deshalb beim Editorbeenden eine ADB-Meldung. Sie verhindert weder Export, Signaturprüfung noch ZIP-Ausrichtungsprüfung. Ein echtes Android-Gerät ist hier ohnehin nicht angeschlossen. Es wurde keine Sicherheitsprüfung abgeschaltet.
- Schneller Testprozess beendete Godot vor Freigabe laufender Audio-Playbacks. Audio wird explizit gestoppt; die Tests lassen dem Mixing-Thread vor dem Beenden Zeit. Die finalen Tests beenden sich ohne Ressourcenleckwarnungen.
- Beschädigtes JSON wird ohne Scriptabbruch erkannt; der gültige Backupstand wird geladen.

## CI und Bereitstellung

`.github/workflows/build.yml` baut bei Push auf `main`, Pull Requests und manueller Ausführung Android und Windows und lädt APK, Windows-ZIP und Prüfprotokolle als Actions-Artefakte hoch. Der Workflow verwendet nur `contents: read`, die üblichen GitHub-Actions-Runtimeberechtigungen für Artefakte und keine benutzerdefinierten Secrets. Eigene Release-Signierschlüssel sind für Debug nicht erforderlich.

Der erste GitHub-Lauf wurde ausgelöst, scheiterte aber vor Jobstart an einem unzulässigen `runner.temp`-Kontext in der Job-Umgebung. Der Workflow verwendet jetzt einen festen temporären Toolpfad; der Folge-Lauf wird separat geprüft. `actionlint` 1.7.7 hat die korrigierte Workflowdefinition anschließend ohne Fehler geprüft. **Bestätigter GitHub-Erfolg:** [Build #2 / Commit 2387eb2](https://github.com/Whiskymitschuss/New-Game/actions/runs/40367847222), Status **Success**, Gesamtdauer 1m 19s. Die öffentliche GitHub-Zusammenfassung bestätigt drei erzeugte Artefakte:

| Artefakt | Größe laut GitHub | SHA-256 des Artefaktarchivs |
|---|---|---|
| `DeadwaveHeroes-v0.1-debug` | 54.3 MB | `163d2c9554a9ea93aa4dbc8842533cb97165303b1306e31e9b5cd2870b8ea9ae` |
| `DeadwaveHeroes-v0.1-windows` | 32.8 MB | `290c8ecac71771a792c9ef73097b4e749c8e4f07af4906cc0ebba8594cc6f447` |
| `deadwave-build-evidence` | 9.19 KB | `8ef0774287c0d21b2ae2a4a5cd56a2e6aabb96c989adb52620432bb41e006727` |

Für den Download bei GitHub anmelden und im verlinkten Lauf unter **Artifacts** den gewünschten Eintrag wählen. Das Android-Archiv enthält die installierbare Debug-APK und das Dateimanifest. Diese GitHub-Archivprüfsummen unterscheiden sich von den SHA-256-Werten der enthaltenen Dateien und von lokalen Builds, deren Debug-Schlüssel separat erzeugt wurde. Der Remote-Erfolg ist über Status und Artefaktliste bestätigt; die archivierten Remote-Protokolle wurden nicht separat heruntergeladen. Zwei Hinweise zu älteren offiziellen Actions-Majorversionen sind nicht blockierend; vor dem Release die Actions-Versionen aktualisieren.

Keine eigenen Secrets und keine zusätzliche Freigabe waren zum Ausführen dieses Debug-Workflows nötig. Weitere Pushes auf `main` starten automatisch neue Builds; manuell ist **Actions → Build DEADWAVE HEROES → Run workflow** möglich. GitHub-Artefakte unterliegen der Aufbewahrungsfrist des Repositories.

## Nicht durchgeführt / noch offen

Keine APK-Installation und Ausführung auf einem physischen Smartphone oder Android-Emulator; keine Touch-/Geräte-/Thermal-/Akkutests, keine FPS-Messung auf Android, kein Windows-Lauf, keine vollständigen Spielbalance-Durchläufe über 100 Level und alle Klassen/Waffen. Tests zu Bossphasen sind Funktionsprüfungen, keine vollständigen Boss-Sieg-Durchläufe. 60 FPS sind ein Ziel, kein gemessenes Versprechen. Kein sicher signierter Release-Build und keine Store-Veröffentlichung. Umfangreiche weitere Produktarbeit ist unter `ROADMAP.md` beschrieben.


## Direkter Smartphone-Download

Die unveränderte APK aus Build #2 wurde zusätzlich als ausdrücklich markierte Debug-Vorabversion veröffentlicht: [v0.1.0-debug](https://github.com/Whiskymitschuss/New-Game/releases/tag/v0.1.0-debug). [Veröffentlichungsworkflow #1](https://github.com/Whiskymitschuss/New-Game/actions/runs/40371689015): **Success**, Gesamtdauer 13s. Der Workflow prüft Größe und SHA-256 gegen das Manifest des ursprünglichen Build-Artefakts vor dem Hochladen.

[Direkte APK-Datei](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.1.0-debug/DeadwaveHeroes-v0.1-debug.apk), ohne GitHub-Anmeldung und ohne ZIP-Umweg. Der öffentliche Download wurde anschließend vollständig heruntergeladen, gegen die veröffentlichten SHA-256-Prüfsummen geprüft und erneut mit `apksigner verify` validiert. Dies bestätigt den funktionierenden Download und die APK-Integrität, weiterhin keinen Gerätetest.


## v0.1.1 – sichtbarer Kugelstrom

Nutzerbefund: Auf Android steigt nach ABWERFEN der Munitionszähler, ohne dass die Kugeln erkennbar sind. Die lokale OpenGL-Reproduktion zeigte funktionierende Physik und gezeichnete, aber kleine, fast überlagerte Kugeln mit sehr kurzer Flugzeit. Die genaue Ursache auf dem Smartphone wurde ohne Zugriff auf das Gerät nicht separat nachgewiesen.

Korrektur: eigene foreground-Zeichenebene (`BallVisuals`, z_index 20), unabhängig vom Sichtbarkeits-/Redrawzustand gepoolter RigidBody2D-Knoten; größere kontrastreiche Kugeln, Lichtkante und kurze Spur; gestaffelte Freigabe alle 65 ms statt einer überlagerten Sofortemission; reduzierte Kugelgravitation; begrenzte Emissionswarteschlange und explizites Ausblenden in modalen Menüs. Virtuelle Kugelwerte, Poolgrenze und Munitionszuordnung bleiben erhalten.

Lokal bestanden: 314 Spiel-/Physik-/Speicherprüfungen, vollständige Tutorial-Durchläufe 1–3 sowie **14 neue Prüfungen mit echtem OpenGL-Rendering**, darunter helle Bildpunkte an statischen und bewegten Physikpositionen, sichtbare virtuelle Repräsentanten, Queue-Zeitverlauf, Sammler und Pause. Screenshot: `builds/balls-v0.1.1.png`. Der GitHub-Build führt diese Grafikprüfung ebenfalls unter Xvfb aus; der Veröffentlichungsworkflow wird erst nach erfolgreichem Build ausgelöst.

APK-Version 0.1.1 / Versionscode 2. Die direkte Downloadadresse ist `https://github.com/Whiskymitschuss/New-Game/releases/download/v0.1.1-debug/DeadwaveHeroes-v0.1.1-debug.apk`. Gegenüber dem ursprünglichen GitHub-APK wurde ein neuer Debug-Schlüssel erzeugt; Installation über die alte Version kann deshalb abgewiesen werden. Eine Deinstallation entfernt den lokalen Spielstand. Ab diesem Build wird der Debug-Schlüssel im Actions-Cache wiederverwendet, solange dieser Cache erhalten bleibt. Die Savegame-Struktur selbst wurde nicht geändert. Ein Gerätetest der neuen Version steht aus.
