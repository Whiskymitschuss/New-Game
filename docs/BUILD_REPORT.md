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

Der erste GitHub-Lauf wurde ausgelöst, scheiterte aber vor Jobstart an einem unzulässigen `runner.temp`-Kontext in der Job-Umgebung. Der Workflow verwendet jetzt einen festen temporären Toolpfad; der Folge-Lauf wird separat geprüft. `actionlint` 1.7.7 hat die korrigierte Workflowdefinition anschließend ohne Fehler geprüft. Ein lokal erfolgreicher Build bestätigt keinen GitHub-Actions-Lauf. Der tatsächliche Status der Remote-Bereitstellung wird im Abschlussbericht genannt. Falls Actions im Repository deaktiviert sind, unter **Settings → Actions → General** die offiziellen `actions/checkout`, `setup-java`, `cache` und `upload-artifact` erlauben. Danach **Actions → Build DEADWAVE HEROES → Run workflow** verwenden. Der Quellcode samt Workflow muss dafür zuerst auf GitHub vorliegen.

## Nicht durchgeführt / noch offen

Keine APK-Installation und Ausführung auf einem physischen Smartphone oder Android-Emulator; keine Touch-/Geräte-/Thermal-/Akkutests, keine FPS-Messung auf Android, kein Windows-Lauf, keine vollständigen Spielbalance-Durchläufe über 100 Level und alle Klassen/Waffen. Tests zu Bossphasen sind Funktionsprüfungen, keine vollständigen Boss-Sieg-Durchläufe. 60 FPS sind ein Ziel, kein gemessenes Versprechen. Kein sicher signierter Release-Build und keine Store-Veröffentlichung. Umfangreiche weitere Produktarbeit ist unter `ROADMAP.md` beschrieben.
