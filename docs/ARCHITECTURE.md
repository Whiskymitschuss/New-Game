# Architektur

`game.gd` verbindet die Zustände menu/map/armory/character/settings/play/upgrade/pause/victory/defeat, die eigens gezeichneten Vektorgrafiken, UI, Kampf und Physikproduktion. Die Node2D-Zeichenfläche ist 540 × 960 und wird mit Godots canvas_items skaliert. Native Buttons und Slider unterstützen Touch und Maus. Keine Netzwerkzugriffe im Spiel.

`content.gd` hält Inhaltsdefinitionen und erzeugt mit einem pro Level festgelegten Seed `734219 + level × 104729` Layouts. `profile.gd` speichert die erzeugten vollständigen Layouts, damit eine spätere Generatoränderung vorhandene Layouts nicht stillschweigend verändert. Alle zehn Level wird in der letzten Welle ein Boss erzeugt.

`ball_visuals.gd` zeichnet die aktiven Körper auf einer eigenen Vordergrundebene, unabhängig von Sichtbarkeits- und Redraw-Zuständen der wiederverwendeten Physikknoten. Größere Kugeln, kontrastreiche Glanzpunkte und begrenzte Bewegungsspuren machen den Strom lesbar. Pro Abwurf werden die Einheiten über eine begrenzte Warteschlange im Abstand von 65 ms freigegeben; die Emission pausiert mit dem Spiel und erhält die Menge bei vollem Pool.

`ball.gd`: Vorab angelegte RigidBody2D-Poolobjekte mit CircleShape2D und kontinuierlicher Kollision. Die Collision-Layer vermeiden Kugel-zu-Kugel-Kollisionen. Jede sichtbare Kugel repräsentiert eine positive ganzzahlige Menge. Ein Bit pro Gate verhindert doppelte Multiplikation beim Zurückspringen. Splits teilen das ganzzahlige Gewicht exakt auf zwei Repräsentanten auf. Der Pool erzeugt keine Instanz pro virtueller Einheit. Nach sieben Sekunden wird eine festhängende Kugel kollisionsfrei freigegeben, nach spätestens zehn Sekunden dem Sammler zugeführt. Gates bleiben dabei logisch aktiv. Kollision, Aufprall und Rollen bis dahin sind echte Godot-Physik. Mengen- und Kapazitätszähler sind getrennt.

`audio.gd`: maximal zehn Effektplayer und ein Musikplayer. Original-WAV-Dateien werden mit `generate_audio.py` reproduzierbar erzeugt; nicht beim Spielstart. Stilboxen werden wiederverwendet. Gegneranzahl, Partikel, Text-Popups und Physikobjekte sind begrenzt. Eine belastbare 60-FPS-Aussage setzt Gerätetests voraus.

`profile.gd`: Schema v1 mit Standardwerten, JSON-Parserprüfung, temporärem Schreiben, Backupkopie und Umbenennung im selben Verzeichnis. Kein Konto und keine Cloud. Fortschritt wird bei Levelstart, Endergebnis, Änderungen und App-Pause persistiert. Der laufende Kampfeinsatz wird nicht als Snapshot gespeichert. Savegames sind lokal bearbeitbar; für ein Offline-Spiel wird das akzeptiert.

`tests/run.gd` prüft Inhaltsgenerator, Laden, Upgrades, Waffen, Bossphasen, echte Physik und Savegames. `tests/campaign.gd` spielt Tutoriallevel 1–3 mit normalen Werten durch und klickt echte Upgrade-Buttons per Signal. Tests verwenden isolierte User-Datenverzeichnisse. Die grafische Sitzung und lokale Builds prüfen zusätzliche, ausdrücklich protokollierte Aspekte.

`tests/render_balls.gd` benötigt einen echten OpenGL-Renderer (lokal X11, CI Xvfb). Es prüft sichtbare Pixel an den Positionen statischer, virtueller und bewegter Kugeln sowie Zeichenreihenfolge, Deaktivierung, Abwurfdauer und Sammler. Ein reiner Headless-Physiktest reicht hierfür nicht.
