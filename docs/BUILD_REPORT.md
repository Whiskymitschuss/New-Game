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

## 0.2.3 / Reaktorschmiede · 27.10.2026

Neue originale Reaktorkulisse, segmentierte Lasertore, animierter Injektor, Kugelschweife, Aufprallfunken und begrenzte additive Light Flares. Große Touch-/Mausfläche zum Zielen mit synchronisiertem Regler, verständliche Abwurfzustände, Lagerfüllstand und freier Lagerplatz. Der Ressourcenstreifen bleibt in der Upgrade-Ansicht sichtbar. Sammelboni erhalten Bruchteile über alle virtuellen Repräsentanten; angezeigt werden tatsächlich akzeptierte Munition und Überlauf. Während laufender Produktion kostet ein weiterer Tipp keinen Versuch.

Lokaler vollständiger Build erstellt Android-Debug-APK und Windows-ZIP; APK-Signatur und 16-KiB-Zipausrichtung erfolgreich geprüft. 6.417 automatische Einzelprüfungen bestanden: Audio 11, Wellen-/Balancepläne 5.705, Reaktor/Touch/FX/Sammelbonus 19, Systeme 314, wiederholte reale Abwürfe 120, alle Upgrade-Layouts 228, echte OpenGL-Pixel-/Eingabeprüfungen 20. Kein headless Pixel-Ersatz: der Grafiktest verwendet X11 und Mesa llvmpipe.

Zehn vollständige Probeläufe mit unveränderten Kampfwerten und normalen Spieleraktionen bestanden. Frische Profile pro Szenario: Soldat in Level 1, 2, 3 und 10; Techniker und Überlebender jeweils in Level 1, 3 und 10. Frühe Einsätze enthalten genau 105 Gegner; Level 10 insgesamt 120 Gegner plus Boss. Der Soldat schließt Level 10 nach rund 220 Simulationssekunden mit 23 Restmunition ab (342 beobachtete Munitionsabgänge, 323 produzierte Einheiten, sieben Abwürfe). Die übrigen beiden Klassen bestehen denselben Boss ebenfalls. Das ist gezielte Stichprobenprüfung, kein Nachweis einer vollständigen Balancierung aller 100 Einsätze.

`tests/capture_reactor.gd` dokumentiert einen normalen Level-3-Lauf mit echten Eingaben, ohne Gegnerplatzierung oder geänderte Kampfwerte. Neue Bilder unter `docs/screenshots/reactor-*-v0.2.3*.png` beziehungsweise `reactor-v0.2.3*.png`: Gameplay in Welle 2 mit neun aktiven Gegnern, zwölf sichtbaren Physikkugeln und 79 Munition; Upgrade-Ansicht nach der zweiten Welle mit 123 Munition. Varianten mit `-4k` sind tatsächliche Godot-Ausgaben mit 2160 × 3840 Pixeln. Die neue Rasterkulisse selbst ist 1402 × 1122; keine Behauptung durchgehend nativer 4K-Assets.

Nicht durchgeführt: Installation/Touch-/Audioprüfung auf einem physischen Android-Gerät, gemessene Hardware-FPS und Windows-Ausführung. Savegame-Version bleibt 1; laufende Einsätze werden weiterhin nicht wiederaufgenommen. Veröffentlichung und Vergleich der tatsächlich heruntergeladenen APK-Signatur werden nach dem Remote-Build ergänzt.

### Veröffentlichung verifiziert

- Quellstand: `910a954` auf `main`.
- GitHub-Build [40467462642](https://github.com/Whiskymitschuss/New-Game/actions/runs/40467462642): erfolgreich, Buildjob 2 min 40 s, einschließlich aller automatischen Suiten und echter OpenGL-Prüfung.
- Download-Veröffentlichung [40467750744](https://github.com/Whiskymitschuss/New-Game/actions/runs/40467750744): APK aus genau diesem geprüften Build übernommen, Manifest-Prüfsumme vor Veröffentlichung geprüft.
- Tatsächlich öffentlich heruntergeladene APK: [DeadwaveHeroes-v0.2.3-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.3-debug/DeadwaveHeroes-v0.2.3-debug.apk), 69.070.861 Bytes, SHA-256 `fc0df56501652de4ec1ffa80519686a0418f39e695f174b5725f57a0d3016f2a`.
- SHA-256 stimmt mit der veröffentlichten `SHA256SUMS.txt` überein. `apksigner verify --verbose` und `zipalign -c -P 16 4` für die heruntergeladene Datei erfolgreich. Paket `com.rfworlds.deadwaveheroes`, Versionsname 0.2.3, Versionscode 6, Mindest-API 24, Ziel-API 36, ARMv7/ARM64.
- Öffentliches Signierzertifikat stimmt mit der heruntergeladenen v0.2.2 überein. Die APK erfüllt damit Paket-, Versions- und Signaturvoraussetzungen für ein Update; keine vorherige Deinstallation erforderlich. Keine Behauptung eines tatsächlich durchgeführten Installationsversuchs auf einem Gerät.
- Die Release-Anhänge enthalten außerdem die neuen Gameplay-/Upgrade-Bilder in normaler und echter 4K-Ausgabe.

## 0.2.4 / Arsenal, Freischaltungen und Waffenbalance · 27.10.2026

Waffen sind durch eine zentrale Policy geschützt: Maschinenpistole nach Einsatz 3, Sturmgewehr nach Einsatz 6; Waffen an den Marken 10/20/30/40/50/70/90 verlangen den tatsächlichen Bosssieg. Wiederholbare Helden-XP umgeht diese Voraussetzungen nicht. Ausrüsten, Aufwerten, Laden und tatsächlicher Kampf prüfen den Zugang. Vorschau und ausgerüstete Waffe sind getrennt. Ein ungültiger alter Loadout wird zur Pistole korrigiert. Saveformat bleibt v1 und bewahrt Sterne, Credits, Einstellungen, Level-Seeds und Altrangdaten. Aktive Aufwertungswirkung maximal Rang 5; Kosten der fünf Ränge 120/480/1080/1920/3000 CR.

Neues Arsenal mit zwölf eigenen skalierbaren Waffenillustrationen, Schlosszuständen, echten Werten und sichtbaren Voraussetzungen. Resultat zeigt neue Freischaltungen, Credits, XP, Abschüsse und Heldenaufstieg samt nächstem Ziel. Der Ergebnisabschluss und veraltete/deaktivierte Button-Callbacks sind gegen doppelte Belohnungen geschützt. Bergung wird in den tatsächlichen Einsatz-Credits mitgezählt. Zentrale Upgrade-Karten nennen Vorher-/Nachher-Werte; volle Heil-/Energiekarten und ausgeschöpfte Chancen werden nicht angeboten. Bei weniger als 45 Munition enthält das Angebot eine Produktions-/Nachschubkarte.

Balanceänderungen: Maschinenpistole 9 Schaden bei 0,18 Sekunden, Maschinengewehr 13 Schaden, Revolver ohne kostenlose Mehrfachdurchdringung. Sekundärtreffer beachten die Reichweite; Flächenschaden maximal fünf Nachbarn innerhalb 85 horizontal und 60 vertikal. Impuls trifft Gegner bis 360 Einheiten rechts vom Helden und baut seinen eigenen Schild bis maximal 75 % Maximalleben auf; größere vorhandene Upgrade-Schilde werden nicht reduziert. Gegnerquoten bleiben unverändert.

Gezielte Waffenprüfung: sechs vollständige Läufe mit frischem Soldaten, Waffenrang 0 und nötigem Freischaltungsnachweis: Pistole/Einsatz1, Maschinenpistole/4, Sturmgewehr/7, Schrotflinte/11, Maschinengewehr/15 und Scharfschützengewehr/20 als Bosswiederholung. Gewöhnliche Spieleraktionen: ergiebigere sichtbare gerade Route wählen, rechtzeitig produzieren, sinnvolle kostenlose Upgrades wählen, Impuls einsetzen. Alle sechs Pilotläufe bestanden. Maschinengewehr15 benötigte acht reale Abwürfe und endete mit 30 Munition; unbegrenzter Vorrat oder Testschaden wurde nicht gewährt.

Ein fixer Probelauf des Überlebenden mit Sturmgewehr+1 verlor am ersten Boss nach munitionsarmen Wegen. Mit Wahl der ergiebigeren sichtbaren Route und Versorgungs-Upgrades bestand derselbe frische Charakter den Einsatz in ca.166 Sekunden, 121 Abschüsse und 118 Restmunition. Die finale Kampagnenprüfung verwendet diese normalen strategischen Eingaben. Bossfälle aller drei Klassen verwenden ein nachweislich freigeschaltetes Sturmgewehr+1, statt die Pistole als repräsentative Ausrüstung für Einsatz10 vorauszusetzen. Das Spiel bleibt bei ungünstigen Entscheidungen verlierbar.

Neue Vorschauen unter `docs/screenshots/progression-*-v0.2.4.png` sind echte 2160 × 3840 Godot-Ausgaben. Die Freischaltung stammt aus einem vollständig ausgespielten Einsatz3 mit gewöhnlichen Eingaben und einem Startprofil mit Sternnachweisen für 1/2. Arsenalbilder verwenden anschließend genau diesen gespeicherten Fortschritt. Keine Gegner oder Schadenswerte für die Bilder manipuliert. Die Waffen-SVGs sind eigene Vektorgrafiken, reproduzierbar durch `scripts/generate_weapon_art.py`.

Grenzen: Stichproben bis Einsatz20 sind kein Beleg perfekter Balance aller 100 Einsätze. Keine Installation, Touch-/Audioprüfung oder FPS-Messung auf einem physischen Android-Gerät; kein Windows-Ausführungstest. Remote-Build, Download-Prüfsumme und Signaturvergleich werden nach erfolgreicher Veröffentlichung ergänzt.

Lokale Endprüfung: 6.692 Einzelprüfungen bestanden (Audio11, Layout-/Wellenpläne5705, Fortschritt97, Waffen/AoE56, Reaktor19, Systeme314, Pool-Reuse120, UI241, UX109, OpenGL20). Zusätzlich alle 16 vollständigen Kampagnen-/Waffenläufe bestanden: zehn Klassen-/Bossfälle und sechs Waffenmeilensteine. Der abschließende Grafiktest prüft weiterhin echte sichtbare Kugelpixel nach wiederholtem Abwurf sowie native Mauseingaben. Neue Waffen-SVGs zusätzlich in Godot als 128 × 64-Texturen geladen.

### Veröffentlichung 0.2.4 verifiziert

- Quellstand `80090ff` auf `main`.
- [GitHub-Build 40560978858](https://github.com/Whiskymitschuss/New-Game/actions/runs/40560978858) erfolgreich, Job 2 min 39 s: 6.692 Einzelprüfungen, 16 vollständige Szenarien, Android-/Windows-Export und echter OpenGL-Test.
- [Download-Veröffentlichung 40561410627](https://github.com/Whiskymitschuss/New-Game/actions/runs/40561410627) erfolgreich, 18 s. APK unverändert aus genau diesem Build anhand des Manifests geprüft und als Debug-Prerelease veröffentlicht.
- Öffentlich tatsächlich heruntergeladene [DeadwaveHeroes-v0.2.4-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.4-debug/DeadwaveHeroes-v0.2.4-debug.apk): 69.139.258 Bytes; SHA-256 `8098803613cfb129e5e966d7bc533a4bd3c5b5e8165ee7179bc40bb063355bd5`, identisch mit der veröffentlichten `SHA256SUMS.txt`.
- `apksigner verify --verbose` und `zipalign -c -P 16 4` bestanden. Paket `com.rfworlds.deadwaveheroes`, Version 0.2.4, Versionscode 7, Mindest-API24, Ziel-API36, ARMv7/ARM64. Öffentliches Signierzertifikat stimmt mit der heruntergeladenen v0.2.3 überein: Update ohne vorherige Deinstallation möglich.
- Zusätzlich aus der lokal erzeugten APK extrahierte echte Export-Ressourcen geprüft: alle zwölf Waffen-Texturen laden mit 128 × 64, die kompilierten Progression-/Arsenalskripte laden und ein frisches Profil sperrt die Maschinenpistole. Das ist eine Prüfung des Exportinhalts im passenden Godot-Desktop-Runner, kein Android-Gerätetest.
- Öffentliche Release-Anhänge enthalten die neue Arsenalansicht, gesperrte Waffenvorschau und echte Freischaltung in 2160 × 3840.


## 0.2.5 / Cinema & Motion · 27.10.2026

Neue bildfüllende Startillustration mit langsamem Kameraeinschwingen, begrenzten Glutpartikeln und lokalem Mündungslicht. Eigene neu generierte Grafik (941 × 1672); kein Anspruch durchgehend nativer 4K-Assets. Abgerundete Oberflächen, weichere Schatten, wärmere Hauptaktion und neue Texthierarchie ersetzen die kantigen Rahmen. Reaktorbild wird mit gerundeter Kontur gezeichnet. Die Startfläche bleibt direkt bedienbar, ohne blockierende Intro-Sequenz.

Neues `InterfaceMotion` animiert den gezeichneten Buttonhintergrund mit Druckfeder, lokalem Ripple, Fokus und kurzem Glanz. Native Text- und Touch-Rechtecke bleiben stabil. Menüwechsel blenden kurz ein; abgebrochene Übergänge werden beim Wechsel beendet. Der Shader berücksichtigt die vererbte Alpha-Transparenz, geprüft im echten GL-Framebuffer. Das Arsenalportrait atmet bei voller Bewegung leicht. Neue gespeicherte Option „Bewegung reduziert“ dämpft Übergänge und Kamerabewegung.

`CombatMotion` ergänzt Atmen, Schussrückstoß, Lauf-/Trefferreaktionen, begrenzte Hülsen/Funken, eingefrorene fallende Todessilhouetten und Impulswellen. Es sind prozedurale Transformationen bestehender Figurenillustrationen, keine vollständigen handgezeichneten Einzelbild-Animationen. Effekte sind auf das Schlachtfeld begrenzt und bei Pause eingefroren. Eigener visueller Zufall verändert weder Kampfzufall noch Schaden, Physik oder Ressourcen. Obergrenzen für hohe/niedrige Qualität: 20/10 Ereignisse, 90/32 Partikel, 12/5 Todessilhouetten.

In der ersten Welle der ersten drei Einsätze werden die ersten drei bereits vorgesehenen Gegner näher eingeführt, sodass der erste echte Schuss mit tatsächlichem Munitionsverbrauch innerhalb einer Sekunde fällt. Keine zusätzlichen Gegner oder Testschäden; die geplante Gesamtzahl bleibt erhalten. Waffenfreischaltungen, Rangkosten und Saveformat v1 bleiben kompatibel.

Lokaler vollständiger Android-/Windows-Build erfolgreich. Android-APK: 73.334.177 Bytes, SHA-256 `98fb004f6458574e95a0af2f45e999201f4a44f24280e48e4e05b2a07529c669`; Signatur und 16-KiB-Ausrichtung geprüft. Diese lokale Prüfsumme ist kein Nachweis einer späteren CI-Datei: der CI-Build verwendet seine wiederverwendete eigene Debug-Identität.

6.736 headless Einzelprüfungen bestanden: Audio11, InterfaceMotion27, CombatMotion24, erster Spielsekunde13, Wellen-/Balancepläne5705, Fortschritt97, Waffen56, Reaktor19, Systeme314, Pool-Reuse120, UI241, UX109. Zusätzlich 79 echte OpenGL-Prüfungen: Kugelsichtbarkeit/Eingaben20, InterfaceMotion32, CombatMotion27. Damit 6.815 Prüfungsdurchläufe, darunter bewusst erneut unter GL geprüfte Motion-Fälle. Alle 16 vollständigen Kampagnen-/Waffenläufe bestanden: zehn Klassen-/Bossfälle und sechs Waffenmeilensteine. Dies ist kein Beleg perfekter Balance aller 100 Einsätze.

`tests/capture_cinema.gd` erzeugt die drei echten Godot-Ausgaben in 2160 × 3840 unter `docs/screenshots/cinema-*-v0.2.5.png`. Gameplay zeigt einen regulären Level-1-Lauf mit sichtbaren Kugeln und Gegnern. `tests/film_cinema.gd` bedient native Mausereignisse für Starten, Zielen, zweimal Abwerfen, Impuls, Pause und Arsenal. Aufnahme bestätigt 24 abgeworfene Startkugeln, sieben Abschüsse und korrektes Endmenü. Die beigefügte MP4 unter `docs/previews/` dauert 19,1 Sekunden, 540 × 960 bei 30 Bildern/s und enthält die integrierte Hintergrundmusik. Movie-Maker-Ausgabe mit festem Zeitschritt ist keine Hardware-FPS-Messung.

Nicht durchgeführt: Installation, Touch-/Audioprüfung oder FPS-Messung auf einem physischen Android-Gerät; Windows-Ausführung. Veröffentlichung samt tatsächlicher öffentlicher Prüfsumme und Signaturvergleich wird nach erfolgreichem Remote-Build ergänzt.


### Veröffentlichung 0.2.5 nach Wiederherstellung verifiziert · 28.10.2026

Der vorherige Cloud-Ausfall wurde durch die wieder verfügbare Arbeitsumgebung überwunden. Quellstand `c3d86b1`; [GitHub-Build 40566382217](https://github.com/Whiskymitschuss/New-Game/actions/runs/40566382217) erfolgreich (4 min 15 s, Job 4 min 10 s), [Download-Veröffentlichung 40567038314](https://github.com/Whiskymitschuss/New-Game/actions/runs/40567038314) erfolgreich (24 s). Die tatsächlich öffentlich heruntergeladene APK ist 73.334.177 Bytes groß und hat SHA-256 `8fc9e79bb91a199caee40917739e415568c9ad8bb34a9c2f28bad3bf9fb9e767`, identisch zur öffentlichen SHA256SUMS.txt. `apksigner verify --verbose` und 16-KiB-zipalign bestanden; das öffentliche Zertifikat stimmt mit der erneut heruntergeladenen v0.2.4 überein. Der Download und die Update-Signatur sind damit nachträglich bestätigt; kein Geräteinstallationstest.


## 0.2.6 / Quarantine · 28.10.2026

Komplette gemeinsame Sci-Fi-Horror-Formsprache für Startansicht, HUD, Reaktor, Karte, Arsenal, Charakterwerte, Optionen, Upgrade-Auswahl, Pause und Ergebnis: dunkle Stahl-/Glasflächen, Cyan-Holographie, warmes Schriftweiß, bernsteinfarbene Sperren und Warnungen. Beleuchtete Kontaktleisten, ruhige Rasterlinien und dezente lokale Lichtläufe; native Buttonflächen bleiben stabil. Die neue Originalillustration `quarantine_terminal.png` ist unverändert eingebunden (941 × 1672), auch als Splash. Es wurden keine Grafiken, Figuren, Logos oder Layoutdateien aus der gewünschten Stimmungsreferenz übernommen.

`ActorRig` ersetzt das reine Figurenwippen durch texturierte Oberkörper-, Bein-, Knie- und Fußsegmente mit Bodenkontakt- und Schwungphase. Läufer, schwere Gegner, Kriecher und Vierbeiner bewegen sich unterschiedlich; Roboter schweben. Der Held hat einen 0,68 Sekunden langen visuellen Eintrittsschritt, dann einen stabilen Schussstand. Eigener Einsatzzeitgeber friert bei Pause/Upgrade ein und wird bei HUD-Neuaufbau nicht zurückgesetzt. Die Darstellung verformt vorhandene Rasterfiguren, statt vollständige neu gezeichnete Einzelbild-Animationen vorzutäuschen. Hohe Qualität: sieben Quads pro Zweibeiner, 13 pro Vierbeiner; Sparqualität drei/fünf.

`BloodFX` reagiert auf echte Treffer und Abschüsse mit gerichteten Sprays, fallenden Tropfen und unregelmäßigen Bodenflecken samt kurzen Nassglanzpunkten. Blut dunkelt ab und verfällt nach höchstens zwölf Sekunden. Roboter verwenden Öl/Kühlmittel. Heldenblut nur bei tatsächlichem Lebensschaden; komplett absorbierte Schildtreffer und Ausweichen bluten nicht. Hohe/niedrige Budgets: 128/48 Flugtropfen, 36/16 Flecken und 16/8 kurze Sprays. Eigener visueller Zufall verändert keine Kampfentscheidungen. Darstellung strikt auf y121–350 begrenzt; Pause friert sie ein. Neue abschaltbare Bluteffekt-Option und reduzierte Bewegung sind mit alten v1-Spielständen kompatibel. Waffenfreischaltungen, Rangkosten, Gegnerquoten, Munition und Spielwerte unverändert.

Lokaler vollständiger Android-/Windows-Build erfolgreich: Android-Debug-APK 74.665.913 Bytes, SHA-256 `8d2a65858a68149b5d7165b9a4ff5564e511098a3831150f3aea2451b0fc6776`. Signatur und 16-KiB-Zipausrichtung geprüft. Diese lokale Prüfsumme ist kein Nachweis der späteren CI-Datei mit der dort wiederverwendeten Debug-Identität. Versionsname 0.2.6, Android-Versionscode 9.

6.919 Prüfungsdurchläufe bestanden: 6.791 headless (bisherige 6.736 plus ActorRig20, BloodFX24, tatsächliche Horror-Systemintegration11) und 128 echte OpenGL-Prüfungen (Kugelsichtbarkeit/Eingaben20, Interface32, CombatMotion27, ActorRig22, BloodFX27). Enthält bewusst unter GL wiederholte Logikfälle. Zusätzlich alle 16 vollständigen Kampagnen-/Waffenläufe bestanden. Keine Behauptung perfekter Balance sämtlicher 100 Einsätze.

Sechs echte Godot-Ausgaben mit 2160 × 3840 unter `docs/screenshots/quarantine-*-v0.2.6.png`: Menü, gesperrtes Arsenal, Karte, Optionen, Gameplay und Upgrade-Wahl. `tests/capture_quarantine.gd` erzeugt die Spielszenen durch normale Schüsse, Zielwahl und Abwürfe ohne Gegner-/Schadensmanipulation. Gameplay-Moment bestätigt drei Abschüsse, 18 Blutspuren und 16 aktive Physikkugeln; Upgrade-Bild stammt aus einer tatsächlich abgeschlossenen Welle.

`tests/film_quarantine.gd` bedient native Mausereignisse für Start, Zielen, zwei Abwürfe, Impuls, Pause, Arsenal, Karte und Optionen. Aufnahme bestätigt sieben Abschüsse, 24 abgeworfene Startkugeln, 31 gespeicherte Blutspuren und Endzustand Optionen. H.264/AAC-MP4: 25,1 Sekunden, 540 × 960, 30 Bilder/s, 3.744.934 Bytes. Aufzeichnung mit festem Zeitschritt ist kein Geräte-FPS-Benchmark.

Nicht durchgeführt: Installation, Touch-/Audioprüfung oder FPS-Messung auf einem physischen Android-Gerät; Windows-Ausführung. Öffentlicher Download, CI-Prüfsumme und Zertifikatsvergleich folgen nach dem Remote-Build.


### Veröffentlichung 0.2.6 verifiziert

- Quellstand `83dc27a` auf `main`.
- [GitHub-Build 40645847350](https://github.com/Whiskymitschuss/New-Game/actions/runs/40645847350) erfolgreich: 3 min 29 s insgesamt, Buildjob 3 min 24 s. Android-/Windows-Export, alle automatisierten Suiten und fünf echte OpenGL-Suiten abgeschlossen.
- [Download-Veröffentlichung 40646204515](https://github.com/Whiskymitschuss/New-Game/actions/runs/40646204515) erfolgreich in 23 s. APK aus dem geprüften Build übernommen und gegen dessen Manifest geprüft.
- Öffentlich tatsächlich heruntergeladene [DeadwaveHeroes-v0.2.6-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.6-debug/DeadwaveHeroes-v0.2.6-debug.apk): 74.661.817 Bytes, SHA-256 `1937df1e9cadbc13483a6cc6c5e8d081b9df85d02405b0aaa7edfac08bd6705f`. Prüfsumme stimmt mit der veröffentlichten `SHA256SUMS.txt` überein.
- `apksigner verify --verbose` und `zipalign -c -P 16 4` für die heruntergeladene Datei bestanden. Paket `com.rfworlds.deadwaveheroes`, Versionsname 0.2.6, Versionscode 9, Mindest-API 24, Ziel-API 36, ARMv7/ARM64. Öffentliches Signierzertifikat stimmt mit der heruntergeladenen v0.2.5 überein: Paket-, Versions- und Signaturbedingungen für ein Update sind erfüllt. Keine vorherige Deinstallation erforderlich; kein tatsächlicher Gerätetest behauptet.
- Auch die öffentlich heruntergeladene [MP4-Vorschau](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.6-debug/DeadwaveHeroes-v0.2.6-motion.mp4) wurde bytegenau verglichen: 3.744.934 Bytes, SHA-256 `3a625b6abf8238de7888efa92da53988f23c4d5d7e81c451d50d1634a9025da9`, identisch zur im Repository dokumentierten Aufnahme. Die sechs 4K-Ansichten sind ebenfalls Release-Anhänge.


## 0.2.7 / Circuit & Gear · 28.10.2026

Multiplikator-Hardware und Reaktor wurden neu gestaltet: aktive Felder ab ×2 als durchlässige Energieaperturen, offene Spuren ohne ×1-Schilder, Feld-Hardware, Sounds oder Multiplikationsblitze. Eine offene Spur bewahrt die Kugelmenge. Collider und Darstellung der Rampen, Pegs und Rotoren stimmen in Größe und Lage überein. Alte untere Statuskarten verdecken keine Hindernisse mehr; die Sammelanzeige ist in die unterste Schiene integriert. Beginn eines Einsatzes setzt ihre Zähler nun vollständig zurück.

Jeder Einsatz erhält ein echtes Portalpaar und drei physische Hindernisse, ab Einsatz 50 vier. Das Portal transportiert den Physikserver-Körper zwischen sichtbarem Ein- und Ausgang; Menge und bereits besuchte Multiplikatoren bleiben erhalten. Nach einer virtuellen Aufteilung erben alle Vertreter den verbrauchten Portalstatus. Drei Hinderniszonen liegen versetzt bei ungefähr x294/y603, x195/y703 und x405/y802, damit sie auf dem Spielfeld tatsächlich erkennbar und erreichbar sind. Das Feld bleibt frei genug für verschiedene Wege.

Layoutrevision `circuit_version=2`: alte gespeicherte Layouts werden einmalig nur in `pieces` und Revisionsnummer angepasst. Gespeicherter Seed, ursprüngliche Gates, Metadaten, Sterne, Credits und alle anderen Fortschrittsdaten bleiben erhalten. Das überarbeitete Feld verändert mögliche Wege und damit reale Erträge; es ist keine heimliche Neuwürfelung bei jedem Versuch. Wiederholte Migration ist idempotent.

Powerzellen erscheinen deterministisch in Welle 2, 5, 8… und höchstens einmal pro solcher Welle. Ein tatsächlicher Kugelkontakt innerhalb 30 Einheiten sammelt sie einmal ein, unabhängig von virtueller Kugelmenge oder Vertreterzahl. Varianten: bis zu 12 Spezialenergie (Maximalwert 100), 25% höhere echte Feuerrate für fünf aktive Spielsekunden oder bis zu 12 Schildpunkte (eigene Grenze 75% Maximalleben, stärkerer vorhandener Schild wird bewahrt). Overdrive verbraucht weiterhin reguläre Munition, pausiert bei Unterbrechung und verfällt; keine permanente Veränderung der Feuerratenstatistik. Rückmeldung nennt die tatsächlich akzeptierten Energie-/Schildpunkte.

`HeroGear` bildet echte Werte als körpergebundene Ausstattung ab: Kapazitäts-/Magazin-/Abwurf-Upgrades ergänzen Gürtel und Patronentaschen, Rüstung ergänzt Schulter-/Brustplatten, Dornen geben Spitzen. Waffenrang oder Schadenskarten, Regeneration, zusätzliche Drohnen sowie aktiver Schild/Overdrive haben passende weitere Details. Anhänge folgen exakt Rückstoß, Körperverformung und Eintrittsschritt. Gesicht und Visier bleiben erhalten. Reine Einsatz-Upgrades enden am Levelende; echte permanente Waffenränge bleiben auf einer neuen Bereitstellung sichtbar. Keine gekauften oder zufällig gewährten kosmetischen Statistiken.

Die ersten zwei Upgrade-Auswahlen der Tutorial-Einsätze 1–3 bieten noch fehlenden Gürtel und Panzer als normale freiwillige Karten an. Der reguläre Auswahl-Callback verändert die echten Spielwerte; die Verbesserung wird anschließend am Helden sichtbar. Spätere Angebote bleiben zufällig, der bestehende Nachschubschutz bei niedriger Munition bleibt erhalten.

12.437 Prüfungsdurchläufe bestanden: 12.284 headless (einschließlich 5437 Layout-/Migrations-, 36 tatsächlichen Portal-/Power-/Tutorial- und 20 Gear-Prüfungen), 153 echte OpenGL-Durchläufe in sechs Suiten. Darunter bewusst wiederholte Logikfälle. Alle 16 vollständigen Kampagnen-/Waffenprobeläufe bestanden. Portalwege können die ergiebige Seite wechseln; die Pilotsteuerung wertet offene Spuren mit neutralem Faktor aus und wählt für gerade Wege äußere Korridore 85/455 statt versehentlich in eine Portalöffnung zu zielen. Ein zunächst gescheiterter MG15-Pilot mit naiver 125/415-Zielwahl wurde ohne Änderung von Kampfwerten oder Erfolgsbedingungen korrigiert. Finaler vollständiger Pilot: 159 Abschüsse, sieben reale Abwürfe, 97 Restmunition. Keine Behauptung perfekter Balance sämtlicher 100 Einsätze.

Lokaler vollständiger Android-/Windows-Build erfolgreich. Android-Debug-APK: 74.678.354 Bytes, SHA-256 `b080ba627c152fbcc0bd71d9870b8d7f77b91242cac23aca121cd26dd457c9ea`. Signatur und 16-KiB-Zipausrichtung geprüft. Version 0.2.7, Android-Versionscode 10. Diese lokale Prüfsumme ist kein Nachweis der späteren CI-Datei mit der dort wiederverwendeten Signieridentität.

Drei echte 2160 × 3840-Godot-Ausgaben unter `docs/screenshots/circuit-{live,power,gear}-v0.2.7.png` stammen aus einem normalen nativen Eingabeablauf. `tests/capture_circuit.gd` startet über das Menü, zielt, wirft ab, nutzt den Impuls und wählt die tatsächlich angebotenen Karten. Bestätigter Aufnahmeverlauf: Welle 3, 33 reguläre Abschüsse, 44 reale Startkugeln in drei Abwürfen, tatsächlicher Gürtel und Panzer sowie eine eingesammelte Powerzelle. Keine Platzierung von Gegnern, Testschäden, Gratiswährung oder direkte Wertevergabe. Der separate Vergleich `circuit-gear-comparison-v0.2.7.png` ist dagegen ausdrücklich ein isolierter Darstellungstest aller drei Klassen mit realen `apply_upgrade`-Kartenaufrufen, kein behaupteter erspielter Kampagnenstand.

Nicht durchgeführt: Installation, Touch-/Audioprüfung oder FPS-Messung auf einem physischen Android-Gerät; Windows-Ausführung. Native Filmdatei, öffentlicher CI-Build, Download-Prüfsumme und Zertifikatsvergleich werden nach ihrer Prüfung ergänzt.


Die tatsächlich erzeugte native Filmaufnahme ist ebenfalls geprüft: `docs/previews/DeadwaveHeroes-v0.2.7-motion.mp4`, 55,366667 Sekunden, 540 × 960, 30 Bilder/s, H.264/AAC, 8.913.017 Bytes. Derselbe normale Eingabeablauf bestätigt 33 Abschüsse, drei Abwürfe mit 44 Startkugeln, Gürtel, Panzer und eine eingesammelte Powerzelle. Die vollständige Aufnahme zeigt auch die tatsächlich getroffenen Upgrade-Entscheidungen. MovieMaker-Aufzeichnung mit festem Zeitschritt ist keine Smartphone-FPS-Messung.


### Veröffentlichung 0.2.7 verifiziert

- Quellstand `11e0696` auf `main`.
- [GitHub-Build 40686062729](https://github.com/Whiskymitschuss/New-Game/actions/runs/40686062729) erfolgreich: 6 min 1 s insgesamt, Buildjob 5 min 56 s. Android-/Windows-Export, alle headless Suiten und sechs echte OpenGL-Suiten abgeschlossen.
- [Download-Veröffentlichung 40686877703](https://github.com/Whiskymitschuss/New-Game/actions/runs/40686877703) erfolgreich in 31 s. APK aus genau diesem geprüften Build übernommen und vor Veröffentlichung gegen dessen Manifest geprüft.
- Tatsächlich öffentlich heruntergeladene [DeadwaveHeroes-v0.2.7-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.7-debug/DeadwaveHeroes-v0.2.7-debug.apk): 74.678.354 Bytes, SHA-256 `61099f7889748b4016371b3a0821f50e0e00b9262a1fdec1af0e01871936483e`. Identisch zur öffentlichen `SHA256SUMS.txt`.
- `apksigner verify --verbose` und `zipalign -c -P 16 4` für die heruntergeladene Datei bestanden. Paket `com.rfworlds.deadwaveheroes`, Version 0.2.7, Versionscode 10, Mindest-API 24, Ziel-API 36, ARMv7/ARM64. Das öffentliche Signierzertifikat stimmt mit der heruntergeladenen v0.2.6 überein; Paket-, Versions- und Signaturbedingungen für ein Update sind erfüllt. Keine vorherige Deinstallation nötig. Kein tatsächlicher Smartphone-Installationstest behauptet.
- Auch die veröffentlichte [55-Sekunden-Spielvorschau](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.7-debug/DeadwaveHeroes-v0.2.7-motion.mp4) öffentlich heruntergeladen und bytegenau verglichen: 8.913.017 Bytes, SHA-256 `2a6f12bbb5e9bc60b7c2b624e17ea8b0df6d1c94290fbb5e6e6cb721dc3c8f63`, identisch zur geprüften nativen Aufnahme. Release-Anhänge enthalten außerdem die drei echten 4K-Spielansichten und den ausdrücklich gekennzeichneten Drei-Klassen-Ausrüstungsvergleich.


## 0.2.8 / Forge · 28.10.2026

Weiche, wegabhängige Spezialmunition und permanente Werkbank sind implementiert. Quellstand `899a9f8` wurde auf `main` gepusht. Die lokalen Tests und Exporte sind wie unten beschrieben geprüft; die öffentliche Bereitstellung wird getrennt verifiziert.

`ReactorSwitch` verwendet den ersten vorhandenen Prallkörper als echte animierte Physikweiche. Ein akzeptierter Abwurf erlaubt genau einen Richtungswechsel während lebender oder noch wartender Kugeln. Die Kollision schwenkt in 0,18 Sekunden zwischen den beiden Winkeln; Pause friert sie ein. Die Weiche verändert weder virtuelle Gewichte noch Gatefaktoren, Zufallsentscheidungen oder Währung. Gespeicherte Circuit-Version-2-Layouts und Seeds bleiben erhalten.

Eine Kugel kann einmalig veredelt werden: tatsächlicher Portaltransport zu EMP oder Passage eines aktiven mittleren Tores zu Brand links beziehungsweise Kryo rechts. Erstprägung gewinnt, neutrale Wege veredeln nicht. Virtuelle Aufteilung erbt die Prägung, wiederverwendete Poolkörper beginnen normal. Der Sammler kann pro Abwurf höchstens zwölf akzeptierte Munitionspunkte veredeln; höchstens 36 Spezialladungen sind insgesamt gespeichert. Sie sind eine Teilmenge des maßgeblichen Munitionszählers. Überlauf erzeugt keine Ladung. Ein echter Schuss verbraucht eine Ladung mit seiner Munition; Munitionsrecycling bewahrt sie. Vorhandene Arten werden in ihrer Warteschlangenreihenfolge automatisch verwendet, gleichartige Sammlungen werden zusammengefasst. Drei kleine Zähler zeigen Brand, Kryo und EMP, eine Markierung den nächsten Typ.

Brand wirkt zwei Sekunden mit begrenztem Folgeschaden über den normalen Treffer-/Belohnungspfad. Kryo verlangsamt 1,5 Sekunden auf 65 % Geschwindigkeit, bei Bossen auf 82 %. EMP unterbricht für 0,35 Sekunden, bei Bossen 0,12 Sekunden; eine Abklingzeit von 1,2 Sekunden pro Ziel verhindert dauerhafte Unterbrechung. Gegen gepanzerte Gegner und Roboter gibt EMP einen begrenzten Schadensbonus. Die Wirkungen betreffen das primäre Ziel; bestehende Waffen-, Rüstungs- und Statusregeln bleiben wirksam.

Ein gezielter Balancebefund im vollständigen Überlebender-/Einsatz-10-Pilot zeigte 120 Abschüsse, leeren Munitionsvorrat und einen noch lebenden Boss. Die begrenzte Korrektur gewährt beim ersten tatsächlichen Boss-Spawn genau einen zusätzlichen Notfall-Abwurf pro Begegnung, sichtbar als „BOSSKONTAKT · +1 NOTFALL-ABWURF“. Es gibt keine direkte Munition; der Spieler muss weiter produzieren und einen Weg wählen. Globale Gegner-Lebenspunkte und Schadenswerte wurden dafür nicht verändert. Der diagnostische Wiederholungslauf mit dem zusätzlichen Abwurf erreichte 121 Abschüsse einschließlich Boss. Auch die anschließende vollständige Kampagnenserie besteht: Der Überlebender-/Einsatz-10-Fall endet nach 169,6 simulierten Sekunden mit 121 Abschüssen, 247,5 Leben, 58 Restmunition, 528 produzierten Einheiten und acht tatsächlichen Abwürfen. Unterschiede zum isolierten Diagnoselauf sind eigene Testabläufe; sie sind keine allgemeine Balancegarantie.

`Workshop` speichert unter `equipment.workshop` drei permanente Ausbaureihen mit je höchstens drei Rängen. Jeder Rang kostet in seiner Reihe 180 / 540 / 1.080 Credits. Voraussetzungen sind positive gespeicherte Sterne für den echten Abschluss von Einsatz 1, Einsatz 5 und Boss 10; XP oder ein nur freigeschalteter Kartenpunkt genügen nicht. Je Rang +40 Kapazität, +1 Rüstung oder +5 % Basisschaden, mit einmaliger Anwendung auf frisch aufgebaute Einsatzwerte. Die Werkbank prüft Rang und Guthaben beim Kauf erneut und speichert sofort; fehlgeschlagenes Speichern stellt den vorherigen Zustand wieder her. Die Vorschau liest eine unabhängige Profilkopie und vergibt keine Spielwerte. `HeroGear` bildet jeden permanenten Rang zusätzlich zu den tatsächlichen Run-Werten ab. Saveformat 1 und bestehende Fortschrittsdaten bleiben erhalten.

Neue Prüfsuiten: `tests/reactor_switch.gd`, `tests/special_ammo.gd`, `tests/workshop.gd`, `tests/forge_integration.gd` und `tests/boss_supply.gd`. In 25 headless Suiten bestehen **12.537 ausdrückliche Einzelprüfungen, null Fehler**; darin sind 68 separat ausgeführte Boss-Schutzprüfungen enthalten. Alle zehn vollständigen Klassen-/Kampagnenfälle und sechs Waffenmeilensteinläufe enden mit Sieg. Sieben Suiten mit tatsächlichem OpenGL-Rendering bestehen mit **299 Prüfungsdurchläufen, null Fehler**. Die Workshop-GL-Suite enthält 146 Prüfungen: 80 wiederholte Basisfälle und 66 zusätzliche native Eingabe-/Renderprüfungen. Diese Gesamtzahlen enthalten bewusst unter GL wiederholte Logikfälle. Zusätzlich bestehen die optionalen Boss-/Kampagnenprüfungen mit 70 Checks und die Spezialmunition-/Kampfintegration mit 49 Checks; diese gezielten Wiederholungen sind getrennt von den obigen Gesamtzahlen ausgewiesen.

Der lokale Test-Orchestrator wurde während der Ausführung geändert. Nachdem alle Tests abgeschlossen waren, führte das erneute Shell-Lesen der veränderten Datei zu einem EOF-Abbruch; ein vollständig erfolgreicher lokaler `build.sh`-Gesamtlauf wird deshalb nicht behauptet. `bash -n` prüft die endgültigen `check.sh`- und `build.sh`-Dateien ohne Fehler. Eine unveränderte Export-Snapshot-Ausführung wiederholte anschließend Ressourcenimport, Android-/Windows-Export, APK-Signatur- und Ausrichtungsprüfung ohne erneute Ausführung der bereits bestandenen Tests und endete mit Exitcode 0.

Die tatsächliche lokale Android-Debug-APK `builds/DeadwaveHeroes-v0.2.8-debug.apk` umfasst **74.703.564 Bytes**, SHA-256 `c58f6c824ee00a86b0dff90296e5ccf365e04d13a7babb6d974a4579606052f3`. `apksigner verify` und `zipalign -c -P 16 4` bestanden. Manifestprüfung: `com.rfworlds.deadwaveheroes`, Version 0.2.8 / Code 11, Mindest-API 24, Ziel-API 36, ARMv7/ARM64. Windows-ZIP tatsächlich exportiert: **51.520.694 Bytes**, SHA-256 `05fb9cc53a58205549cf2bcd16a8f829aba97b4eda3d76aafe51c75575431a41`. Lokale Prüfsummen sind kein Nachweis einer späteren CI-Datei mit deren wiederverwendetem Debug-Schlüssel.

Tatsächlich erzeugte Medien: `docs/screenshots/forge-gameplay-v0.2.8.png` und `forge-workshop-v0.2.8.png` mit je 2160 × 3840 Pixeln aus dem echten Godot-Renderer. Ein frischer, isolierter Spielstand gewinnt Einsatz 1 mit 547 Credits, kauft über native Pointer-Eingaben Gürtel und Panzer für je 180 Credits und startet Einsatz 2 mit beiden permanenten Ausbauten. Keine künstlichen Credits, Sterne oder Kampfvorteile. Die vollständige native MovieMaker-Aufnahme `docs/previews/DeadwaveHeroes-v0.2.8-motion.mp4` zeigt denselben Ablauf ungekürzt: 124.866667 Sekunden, 540 × 960, 30 Bilder/s, H.264/AAC, 23295458 Bytes, SHA-256 `27cd33a04e194cd8f706ec61d7d85118cfe427814b3d00ae5e476d8a257152c1`. Die Aufnahme bestätigt drei betätigte Weichen, produzierte Spezialmunition und angewendete permanente Werte. Eine Aufnahme mit festem Zeitschritt ist keine Smartphone-FPS-Messung.

Installation, Touch-/Audio-/FPS-Prüfung auf einem physischen Android-Gerät und Windows-Ausführung wurden nicht durchgeführt. Die unten dokumentierte öffentliche Prüfung bestätigt Build, Downloads, Paket und Signatur.

Die separat ausgeführte gezielte Boss-Regression `tests/boss_supply.gd -- --campaign` besteht mit 70 Prüfungen (68 Schutzprüfungen plus zwei Kampagnenbedingungen): Überlebender in Einsatz 10 gewinnt mit 121 Abschüssen und 74 Restmunition nach acht tatsächlichen Abwürfen. Die nachfolgende vollständige Testserie ist oben dokumentiert.


### Veröffentlichung 0.2.8 verifiziert

- Quellstand `899a9f8` auf `main`.
- [GitHub-Build 40774732831](https://github.com/Whiskymitschuss/New-Game/actions/runs/40774732831) erfolgreich: 6 min 1 s insgesamt, Buildjob 5 min 57 s. Der feste eingecheckte Stand durchlief den vollständigen `build.sh`-Lauf mit allen 25 headless Suiten, Android-/Windows-Export sowie anschließend allen sieben OpenGL-Suiten.
- [Download-Veröffentlichung 40775539762](https://github.com/Whiskymitschuss/New-Game/actions/runs/40775539762) erfolgreich: 26 s insgesamt, Veröffentlichungsjob 22 s. Die APK wurde unverändert aus dem erfolgreichen Build übernommen und vor Veröffentlichung gegen dessen Manifest geprüft.
- Tatsächlich öffentlich heruntergeladene [DeadwaveHeroes-v0.2.8-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.8-debug/DeadwaveHeroes-v0.2.8-debug.apk): **74.703.564 Bytes**, SHA-256 `9746750c859007bcb12f848b939f793340696604ead8b34a7c8eeababceefbae`. Identisch zur öffentlichen `SHA256SUMS.txt`.
- `apksigner verify --verbose --print-certs` und `zipalign -c -P 16 4` für die heruntergeladene Datei bestanden. Paket `com.rfworlds.deadwaveheroes`, Version 0.2.8 / Code 11, Mindest-API 24, Ziel-API 36, ARMv7/ARM64. Das öffentliche Zertifikat ist identisch mit v0.2.7: SHA-256 `6ce3f6820da591451121735c9ced6574b9d333c5dc6775cbaa2e6d810c85bfd6`. Paket-, Versions- und Signaturbedingungen für ein Update sind damit erfüllt. Ein tatsächlicher Smartphone-Installationstest wurde nicht durchgeführt.
- Öffentliche [Spielvorschau](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.8-debug/DeadwaveHeroes-v0.2.8-motion.mp4) vollständig heruntergeladen und bytegenau verglichen: **23.295.458 Bytes**, SHA-256 `27cd33a04e194cd8f706ec61d7d85118cfe427814b3d00ae5e476d8a257152c1`. Die ungekürzte Aufnahme dauert 124,866667 Sekunden. Auch beide veröffentlichten 4K-PNGs vollständig heruntergeladen: bytegleich zu den eingecheckten echten Renderaufnahmen und jeweils 2160 × 3840 Pixel.


## 0.2.9 / Elemental · 29.10.2026

Implementiert und lokal geprüft: Die neue Version verstärkt das sichtbare Feedback von Brand, Kryo und EMP sowie die Unterstützungsdrohne. Konfiguration: Godot 4.6.3, Android-Version 0.2.9 / Code 12, Paket `com.rfworlds.deadwaveheroes`, ARMv7/ARM64; Windows wurde ebenfalls exportiert. Die bisherige Spezialmunitionsberechnung, Statusdauer, Schadenswerte und Freischaltregeln gelten weiter. Sichtbare Schussereignisse werden vor der tatsächlichen Schadensvergabe ausgelöst, sodass auch tödliche Treffer einen passenden Einschlag zeigen.

`ElementalFx` zeichnet begrenzte Schuss-, Treffer- und Statuseffekte im geclippten Kampfbereich. Tatsächlich verwendete Spezialmunition löst die Ereignisse aus; auch ein tödlicher Treffer behält kurz seinen sichtbaren Einschlag. Brand nutzt Flammen/Glut, Kryo Eissplitter/Reif und EMP elektrische Bögen/Impulsringe. Waffenstreifen und Veredelungsaperturen erhalten besser unterscheidbare Typanzeigen. `SupportDrone` ersetzt das einfache alte Drohnenprofil durch ein gepanzertes Gehäuse, Kamera, zwei Antriebe und eine sichtbare Mündung. Schweben und Schussrückstoß sind reine Darstellung; die bestehende Drohnen-Schadensberechnung und Feuerrate bleiben unverändert.

Die vier Bilder und die bewegte Vorschau sind unten mit ihren tatsächlichen Aufnahmebedingungen dokumentiert. Es handelt sich um gezielte Darstellungstests mit kontrollierten Testzuständen im tatsächlichen Godot-Spiel.

Der lokale vollständige `scripts/build.sh`-Lauf endete erfolgreich mit Exitcode 0. **28 headless Suiten mit 12.621 ausdrücklichen Prüfungen, null Fehler**, außerdem zehn komplette Klassen-/Kampagnenfälle und sechs komplette Waffenmeilensteinläufe mit Sieg. **Neun echte OpenGL-Suiten mit 373 Prüfungsdurchläufen, null Fehler**; darin sind teilweise bewusst wiederholte Basisprüfungen enthalten. Neu: `elemental_fx` mit 32 Headless-Prüfungen, `support_drone` mit 17 Headless- beziehungsweise 19 GL-Prüfungen und `elemental_presentation` mit 35 Headless- beziehungsweise 55 GL-Prüfungen. Echte Schüsse verbrauchen weiter genau eine passende Ladung; tödliche Treffer behalten ihren Effekt. Private visuelle Zufallszahlen, begrenzte Partikelzahlen, Pause, reduzierte Bewegung und Pixelvergleiche an den Kampffeldgrenzen sind geprüft. Die neuen Funktions- und Grafiksuiten sind im CI eingebunden.

Import, Android-/Windows-Export, `apksigner verify` und `zipalign -c -P 16 4` bestanden. Lokale APK: **74.724.364 Bytes**, SHA-256 `2a0bb19c3a943eaa26c9a5b25aa3fa3f276a981aff848570493daaeca159dab2`. Lokales Windows-ZIP: **51.541.112 Bytes**, SHA-256 `f7deff4ef1ee9097308c4bb972ce431f23f1122b7be01c607254ddc458c9c8eb`. Paket `com.rfworlds.deadwaveheroes`, Version 0.2.9 / Code 12, Mindest-API 24, Ziel-API 36, ARMv7/ARM64.

Installation, Touch-/Audio-/FPS-Prüfung auf einem physischen Android-Gerät und Windows-Ausführung wurden nicht durchgeführt. Die folgenden Nachweise bestätigen den öffentlichen Build und die tatsächlich heruntergeladenen Dateien.

Die Medien wurden tatsächlich erzeugt: vier echte Godot-Renderaufnahmen mit je 2160 × 3840 Pixeln und eine bewegte Vorschau mit 32.100000 Sekunden, 540 × 960, 30 Bildern/s, H.264/AAC, 9933034 Bytes, SHA-256 `dadb3745d37eca0dddca7762e3e2a2609084516578c8d7ec18b312d71e6d4577`. Der kontrollierte Aufbau lädt Spezialmunition, schaltet das Sturmgewehr für den Test frei und setzt drei robuste Ziele. Alle Treffer, Statuswirkungen, Drohnenschüsse und Kugelbahnen laufen durch das tatsächliche Spiel. Jede der vier Phasen bestätigt mindestens einen tatsächlichen Drohnenschuss und einen tatsächlichen Abwurf; die drei Elementarphasen bestätigen passende Spezialschüsse. Für die Standbilder wird ein tatsächlicher Effektmoment während des Renderns kurz angehalten. Die Videovorschau läuft ohne diesen Halt. Die Aufnahmen sind ausdrücklich Darstellungstests, kein erspielter Kampagnenfortschritt und keine Smartphone-FPS-Messung.


### Veröffentlichung 0.2.9 verifiziert

- Quellstand `0fa59f8` auf `main`.
- [GitHub-Build 40847844687](https://github.com/Whiskymitschuss/New-Game/actions/runs/40847844687) erfolgreich: 6 min 40 s insgesamt, Buildjob 6 min 35 s. Alle 28 headless Suiten, Android-/Windows-Export, Signatur-/Ausrichtungsprüfung und alle neun OpenGL-Suiten abgeschlossen.
- [Download-Veröffentlichung 40848719841](https://github.com/Whiskymitschuss/New-Game/actions/runs/40848719841) erfolgreich in 21 s. APK unverändert aus genau diesem erfolgreichen Build übernommen und gegen dessen Manifest geprüft.
- Öffentlich vollständig heruntergeladene [DeadwaveHeroes-v0.2.9-debug.apk](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.9-debug/DeadwaveHeroes-v0.2.9-debug.apk): **74.724.364 Bytes**, SHA-256 `8dcee040f05c73b0681c0db3308a208674c0bf9a60d63d2b99347d675c091424`. Identisch zur öffentlichen `SHA256SUMS.txt`.
- Öffentliche APK: `apksigner verify --verbose --print-certs` und `zipalign -c -P 16 4` bestanden. Paket `com.rfworlds.deadwaveheroes`, Version 0.2.9 / Code 12, Mindest-API 24, Ziel-API 36, ARMv7/ARM64. Zertifikats-SHA-256 `6ce3f6820da591451121735c9ced6574b9d333c5dc6775cbaa2e6d810c85bfd6` stimmt mit der heruntergeladenen v0.2.8 überein. Paket-, Versions- und Signaturbedingungen für ein Update sind erfüllt; ein tatsächlicher Smartphone-Installationstest steht aus.
- Öffentliche [32-Sekunden-Vorschau](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.9-debug/DeadwaveHeroes-v0.2.9-motion.mp4) vollständig heruntergeladen: **9.933.034 Bytes**, SHA-256 `dadb3745d37eca0dddca7762e3e2a2609084516578c8d7ec18b312d71e6d4577`, bytegleich mit der geprüften nativen Aufnahme. Auch alle vier öffentlichen PNGs vollständig heruntergeladen und bytegleich zu den eingecheckten Renderaufnahmen verglichen, jeweils 2160 × 3840 Pixel.


## 0.2.10 / Live Ops · 29.10.2026

Implementiert: freiwillige Wischkombinationen und vierstellige Zahlencodes aus 1–4. Drei korrekte Wischrichtungen geben bis zu 24 Munition, bei vollem Lager bis zwölf Energie (Kapazitäten gelten). Ein Code gibt 18 gespeicherte Credits. Keine Strafe bei Auslassen; maximal zwei Angebote pro Welle, sieben Sekunden Eingabezeit nach Öffnen, Pause hält die Uhr an. Statuswechsel vor Vergabe verhindert doppelte Belohnungen. Fehlgeschlagenes Speichern rollt die Credits zurück. Eigener reproduzierbarer Zufall ohne Verbrauch des Kampfzufalls. Kampf läuft weiter, Kugelfeld bleibt frei.

Kampfzeit wird ausschließlich beim tatsächlichen Kampfupdate mit 1,25 multipliziert. Schüsse, Gegnerbewegung, Nachladen, Spawnzeiten, Regeneration und Statusdauer erhalten denselben Faktor. Keine globale Engine-Zeitskalierung: Kugelphysik und Bonusfrist laufen normal. Effektive Waffenanzeigen angepasst.

Gezielte Prüfungen: 15 Headless-Prüfungen bestanden; zusätzlicher nativer OpenGL-Eingabetest besteht mit 17 Prüfungen, darunter tatsächliche Maus-Wischbewegungen, echte Zahlentasten und gespeicherte Belohnungen. Die erste Gesamttest-Ausführung fand einen UI-Reihenfolgekonflikt mit der Kugel-Eingabefläche. Der leere Bonuscontainer wird jetzt nicht erzeugt; der gezielte Reaktortest besteht wieder mit 19 Prüfungen. Vollständige Regression und Exporte wurden anschließend erfolgreich abgeschlossen; öffentliche Nachweise folgen unten. Keine Smartphone-Gerätetests oder Windows-Ausführung durchgeführt.


### Veröffentlichung 0.2.10 verifiziert

- Quellstand `628378c`. Vollständiger lokaler `build.sh`-Lauf erfolgreich, Android und Windows exportiert. 29 headless Suiten: 12.636 ausdrückliche Prüfungen ohne Fehler. Zehn komplette Klassen-/Kampagnenläufe und sechs Waffenmeilensteinläufe gewinnen ohne Minispielbelohnungen. Soldat/Einsatz 1 erreicht den Sieg nach 71,0 Sekunden statt zuvor 103,7 Sekunden; dies ist ein konkreter Testlauf, keine allgemeine Verkürzungsgarantie.
- [GitHub-Build 40959636276](https://github.com/Whiskymitschuss/New-Game/actions/runs/40959636276) erfolgreich: 5 min 19 s insgesamt, Job 5 min 16 s. Vollständiger Export und alle 29 Funktions-/zehn Grafiksuiten erfolgreich. Die zusätzliche GL-Suite enthält 17 Prüfungen einschließlich nativer Eingaben.
- [Veröffentlichung 40960362123](https://github.com/Whiskymitschuss/New-Game/actions/runs/40960362123) erfolgreich in 20 s.
- Vollständig heruntergeladene öffentliche [APK v0.2.10](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.10-debug/DeadwaveHeroes-v0.2.10-debug.apk): 74728613 Bytes, SHA-256 `d2cb31d4c0b0ea5d30f4a16c1cd262d1995565389832a6c8d1b880febf9d371b`, identisch zu öffentlicher SHA256SUMS.txt. Signatur und 16-KB-Ausrichtung geprüft. Paket com.rfworlds.deadwaveheroes, Code 13, Version 0.2.10. Das Zertifikat ist identisch zu v0.2.9; die Update-Bedingungen sind erfüllt.
- Öffentliches Screenshot-Artefakt vollständig heruntergeladen und bytegleich zur eingecheckten gezielten Eingabeprüfung bestätigt. Keine Smartphone-Installation, Touch-/Audio-/FPS-Messung auf Hardware oder Windows-Ausführung durchgeführt.


## 0.2.11 / Timing Rail · 30.10.2026

Schnelles automatisches Pendel mit 640 px/s, Grenzen x50–490, kontinuierliche Reflexion und korrekte Reststrecke am Rand. Keine Steuerung durch Touch, Maus oder Tastaturfokus auf dem Schieber. ABWERFEN löst unmittelbar beim Drücken aus und fixiert die Salvenposition bis zum Ende der Warteschlange. Anschließend Bewegung trotz noch fallender Kugeln. Pause/Upgrade halten die Phase; neuer Einsatz setzt sie reproduzierbar auf Mitte zurück. Kein Verbrauch des Kampfzufalls und keine Änderung der Kugelmengen oder Poolgrenzen.

Neue Einheitssuite: 13 Prüfungen bestanden. Zusätzlicher echter Timing-Pilot gewinnt Einsatz 1 ohne direktes Setzen der Position: 105 Abschüsse, zwei am Pendelstand ausgelöste Abwürfe, 69,48 simulierte Sekunden, 14 Prüfungen bestanden. Native GL-/Filmprüfung bestätigt Drücken statt Loslassen und sichtbare physische Abwürfe: 15 Prüfungen bestanden. Vorhandene Touch-Steuerungsprüfungen wurden auf die ausdrücklich gewünschte automatische Steuerung aktualisiert; Erhaltung der Mengen und Ballwiederverwendung bleiben geprüft.

Native Vorschau (gezielter Eingabetest im echten Spiel): 12.100000 Sekunden, 540 × 960, 30 Bilder/s, H.264/AAC, 2859959 Bytes, SHA-256 `6d297d490f9c1ef502464aedc08a43a5801f578a75344d26a94e26eb29826062`. Die Aufnahme zeigt automatisches Pendeln und zwei native Tastendrücke. Keine Smartphone-FPS-Messung.

Vollständiger lokaler build.sh-Lauf erfolgreich: 30 headless Suiten, 12.649 ausdrückliche Prüfungen ohne Fehler, zehn Klassen-/Kampagnenläufe und sechs Waffenmeilensteine mit Sieg. Bestandskampagnen verwenden kontrollierte Abwurfrouten; das tatsächliche automatische Timing wird zusätzlich im oben beschriebenen eigenständigen Pilot geprüft. Android-/Windows-Export, Signatur und 16-KB-Ausrichtung bestanden. Die öffentliche Downloadverifikation folgt unten. Keine Installation, Touch-/Audio-/FPS-Prüfung auf einem physischen Android-Gerät oder Windows-Ausführung durchgeführt.


### Veröffentlichung 0.2.11 verifiziert

- Quellstand `73ef258`. [GitHub-Build 41015283049](https://github.com/Whiskymitschuss/New-Game/actions/runs/41015283049) erfolgreich: 5 min 37 s insgesamt, Job 5 min 32 s. Alle 30 Funktionssuiten, Exporte und elf Grafiksuiten erfolgreich.
- [Veröffentlichung 41015838173](https://github.com/Whiskymitschuss/New-Game/actions/runs/41015838173) erfolgreich in 22 s.
- Vollständig öffentlich heruntergeladene [APK v0.2.11](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.11-debug/DeadwaveHeroes-v0.2.11-debug.apk): 74732709 Bytes, SHA-256 `aa4cd4a8906e34b1abc8edf0b58bf28851cee577dd019009b1a8a428ed1343e5`, identisch zu öffentlicher SHA256SUMS.txt. Signatur und 16-KB-Ausrichtung geprüft. Paket com.rfworlds.deadwaveheroes, Code 14, Version 0.2.11; Zertifikat identisch zu v0.2.10. Update-Bedingungen erfüllt.
- Öffentliche MP4-Vorschau und PNG vollständig heruntergeladen und bytegleich zu den geprüften Aufnahmen verglichen. Keine Smartphone-Installation, Touch-/Audio-/FPS-Prüfung auf Hardware oder Windows-Ausführung durchgeführt.
