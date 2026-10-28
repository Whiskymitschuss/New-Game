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
