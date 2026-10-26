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


Bestätigter Remote-Abschluss für v0.1.1: [Build 40374258434](https://github.com/Whiskymitschuss/New-Game/actions/runs/40374258434), Status **Success**, Gesamtdauer 1m 30s, drei erzeugte Artefakte. Die automatische Debug-Veröffentlichung ist erfolgt; der direkte APK-Link lieferte HTTP 200. Die gesamte veröffentlichte APK wurde erneut heruntergeladen (57.400.684 Bytes), SHA-256 `f2fde297f90d5c5db62d69bff0f007865338b88113d9554a83ca2dbe246f5331`, `apksigner verify` erfolgreich, Manifest-Version 0.1.1 / Code 2 und `ball_visuals.gdc` im Archiv bestätigt. Der Vergleich der öffentlichen Signierzertifikate mit v0.1.0 bestätigt unterschiedliche Debug-Identitäten.

Zusätzlich bestanden die 14 Grafiktests auch mit den aus der tatsächlich exportierten lokalen APK entpackten Spielressourcen unter dem Linux-OpenGL-Renderer. Das prüft die exportierten Ressourcen, ersetzt aber keine Android-Ausführung. Der neue Screenshot liegt unter `docs/screenshots/balls-v0.1.1.png`.

## v0.2.0 – wiederholbarer Abwurf und Neon-Design

Der Folgefehler wurde reproduziert: Bei v0.1.1 flog der erste Abwurf durch das Feld; ab dem zweiten Abwurf lag die serverseitige Körperposition bereits bei y≈957 hinter dem Sammler. Die Kugeln wurden sofort gesammelt, während die Node2D-Position zuvor nur kurz auf den Start gesetzt worden war. Die vorherige Grafikänderung allein behob diese Ursache nicht.

Korrektur in `AmmoBall`: Transform und Geschwindigkeiten werden auf dem PhysicsServer2D gesetzt und in `_integrate_forces` bestätigt; bis zur Bestätigung verarbeitet der Besitzer keine Gates und keine Sammlung. Teleporter verwenden denselben Resetpfad. Es werden weiterhin dieselben gepoolten Körper/RIDs wiederverwendet, keine neuen Ersatzkörper pro Abwurf.

Lokal verifiziert: 314 bestehende Assertions, 120 neue Pool-/Wiederholungsprüfungen (24 vollständige Abwürfe in beiden Qualitätsstufen, mit Wellenwechseln und Pausen), 228 Layoutprüfungen für alle 48 Upgrade-Karten und die Klassenporträts, 17 Prüfungen mit echtem OpenGL-Rendering einschließlich Abwurf 2–4. Insgesamt **679 bestandene Assertions** und drei vollständige Tutorial-Durchläufe. In der reproduzierbaren Rechtsrouten-Fixture ergeben zwölf Kugeln bei jedem der 24 Abwürfe exakt 216 virtuelle Einheiten.

Design: drei neue illustrierte Helden, sechs eigene Gegneratlas-Silhouetten als Basis der Typvarianten, detaillierte Sci-Fi-Stadt, eigenes Vektor-HUD, Reaktor-Fabrik, zwölf skalierbare Upgradeglyphen, Klassenporträts, neue Typografie und App-Icon. Alle Grafiken werden tatsächlich vom Spiel geladen. Native 2160×3840-Ausgaben des Godot-Renderers wurden für Menü, Kampfansicht, Upgrade-Auswahl, Arsenal und Karte erzeugt und visuell geprüft. Quellen und Einschränkungen: `ART_DIRECTION.md`; die Rasterdateien werden nicht als durchgehend native 4K-Assets bezeichnet. Die Capture-Szene ist für UI-Prüfungen gestellt, nutzt aber die echten Spielsysteme und keine montierten Oberflächen.

Lokale Android-APK v0.2.0 / Code 3 wurde erzeugt; Signatur- und 16-KB-ZIP-Ausrichtungsprüfung erfolgreich. Windows-x64-Export wurde ebenfalls erstellt. Ein physischer Android-Test der neuen Version und Smartphone-FPS-Messungen stehen weiterhin aus. Der Remote-Build, direkte Download und die Signaturkompatibilität werden nach Abschluss separat protokolliert.

Remote bestätigt: [Build 40416073403](https://github.com/Whiskymitschuss/New-Game/actions/runs/40416073403) **Success**, 1m 28s; [automatische Veröffentlichung 40416251258](https://github.com/Whiskymitschuss/New-Game/actions/runs/40416251258). Der direkte v0.2.0-APK-Download wurde vollständig heruntergeladen und geprüft: 63.528.384 Bytes, SHA-256 `511c9d4f10bb90b95a4e896a6d1ed5baa92d2718cbfe05424f439583ae9db960`, gültige APK-Signatur, Manifest 0.2.0 / Code 3. Die neue Art-Klasse und Atlasmetadaten sind im APK enthalten. Der öffentliche Zertifikatsvergleich bestätigt dieselbe Signieridentität wie bei der veröffentlichten v0.1.1; ein normales Update unter Beibehaltung der App-Daten ist damit möglich. Nicht vorher deinstallieren.

Die lokalen exportierten APK-Ressourcen bestanden zusätzlich alle 17 Grafikprüfungen unter dem Linux-OpenGL-Renderer. APK-Download und beide als Release-Dateien veröffentlichten 2160×3840-Designvorschauen lieferten HTTP 200. Ein tatsächlicher Android-Gerätetest bleibt getrennt davon offen.

## v0.2.1 – Endless Survival als Hintergrundmusik

Die Nutzerdatei `Endless Survival.mp3` wurde unverändert als `assets/audio/endless_survival.mp3` übernommen (SHA-256 `39aedc1b57c655266191a8d3df70be27558fa90516f3429886908a501f2f31ab`). Quelle: bereitgestellter Nutzer-Upload. Vollständige FFmpeg-Decodierung ohne Fehler; MP3, Stereo, 48 kHz, ungefähr 169,34 Sekunden. Kein Streaming, keine Umkodierung und keine Veränderung der Originalaufnahme.

Die Datei ersetzt die Hintergrundthemen für Menü, Wellen und Bosskontext. AudioStreamMP3 läuft in Schleife. Die Wiedergabe wird nur beim Wechsel der tatsächlichen Musikdatei neu gestartet; Kontext-/Lautstärkewechsel erhalten den laufenden Player. Sieg und Niederlage behalten ihre kurzen bisherigen Musikstücke. Der Musikregler pausiert bei null die Wiedergabe vollständig, unabhängig vom Effektregler.

Elf neue Audioprüfungen bestanden: MP3-/Längenprüfung, Loop, keine Neustarts bei Menü/Kampf/Boss, getrennte Lautstärke, vollständiges Stummschalten und Wiederaufnahme, Ergebnisstücke und Rückkehr zum Hintergrundsong. Der Build enthält weiterhin sämtliche bisherigen Spiel-, Pool- und Layoutprüfungen. Version 0.2.1 / Code 4; das Savegame-Format bleibt unverändert. Tatsächliche Lautsprecher-/Kopfhörerprüfung auf einem Android-Gerät steht aus.

## v0.2.2 – Horden und Munitionsverhältnis

Zusätzlich zum Musik-Update: frühe Gegnerzahl von 30 auf 105 pro Einsatz erhöht (Wellen 15/18/21/24/27), kürzere Spawnabstände und Gruppen ab Welle 2. Aktive Gegner bleiben auf 40 begrenzt. Abwürfe wurden von fünf plus zwei je Folgewelle auf drei plus einen je Folgewelle begrenzt. Das Basis-Munitionslager beträgt `240 + 8 × Level` statt 5000; bestehende Kapazitäts-Upgrades erhöhen dieses echte Limit. Bei vollem Lager ist Abwerfen gesperrt, auch Salvage respektiert das Limit. Energie pro Abschuss sinkt auf 0,65, um bei größeren Horden keinen unmittelbaren Impuls-Kreislauf zu erzeugen.

Die Gatewerte wechseln deterministisch mit Level und Welle; ×1 ist neutral, spätere Welten erhalten größere Einzelfaktoren mit neutralen Folgetoren. Kein Zahlenwechsel mitten in einer laufenden Kugelgruppe: Wellenwechsel wartet auf leere Physik-/Abwurfqueues. Die gespeicherte Geometrie wird nicht überschrieben. Die Pool-Recycling-Fixture verwendet bewusst feste x3/x2/x3-Werte, damit sie unabhängig von der neuen Balance weiterhin den ursprünglichen Mengen-/Recyclingfehler erkennt.

Lokale vollständige Durchläufe mit normalen Werten: Level 1–3 jeweils Sieg und 105 Abschüsse. Teststrategie produziert unter 60 Reserve-Munition und verwendet verfügbare Impulse. Ergebnisse: ca. 89/92/84 simulierte Sekunden, maximal 17/22/13 gleichzeitige Gegner, 99/107/52 tatsächlich verbrauchte Munition, 2/2/1 Abwürfe, Restmunition 88/116/65. Zufällige Upgrade-Karten beeinflussen diese Messwerte; das sind reproduzierbare Testdurchläufe, keine universelle Garantie für alle Klassen/Waffen. Alle 100 Level und ihre Wellenpläne werden auf gültige, wechselnde und reproduzierbare Faktoren und begrenzte Gegnerzahlen geprüft. Vollständige Balancing-Durchläufe über 100 Einsätze stehen weiterhin aus.

Remote bestätigt: [Build 40418708573](https://github.com/Whiskymitschuss/New-Game/actions/runs/40418708573) **Success** (1m 55s), [Veröffentlichung 40418931259](https://github.com/Whiskymitschuss/New-Game/actions/runs/40418931259) **Success**. Insgesamt 6395 Assertions im Build einschließlich Audio, Balanceplänen, bestehender Spiellogik und Grafik; drei vollständige Tutorial-Siege. Der direkte APK-Download wurde vollständig geprüft: 67.514.014 Bytes, SHA-256 `920fec6686e45b2f98ae8c7e7fc5ce44b82703a849c95a6356b6b1c4c3027c9a`, gültige APK-Signatur, Version 0.2.2 / Code 5 und enthaltene Endless-Survival-Musikressource. Zertifikatsvergleich mit der veröffentlichten v0.2.0 stimmt überein; normales Update ohne Deinstallation möglich. Windows wurde ebenfalls exportiert, aber nicht unter Windows ausgeführt.

`docs/screenshots/horde-v0.2.2.png` stammt aus einem normalen laufenden Sektor-3-Einsatz, ohne künstliches Erzeugen oder Platzieren von Gegnern und ohne geänderte Kampfwerte: zwölf aktive Zombies bei 72 Reserve-Munition in Welle 2. Testautomatik betätigt Abwurf und Upgrade-Karten; für diese Aufnahme wurde kein Impuls eingesetzt. Physischer Android-Test und umfassende Balanceprüfung aller Klassen/Waffen bleiben offen.
