# DEADWAVE HEROES / Neon Update 0.2.0

Ziel: eine eigenständige futuristische Sci-Fi-Comic-Präsentation mit detaillierten Figuren, lesbarer Ressourcenproduktion und einer ruhigen, hochwertigen Benutzeroberfläche. Dunkles Marineblau bildet die Basis; Cyan kennzeichnet Technik, Mint Energie/Produktion, Violett Evolution und Amber Belohnungen. Der Soldat in warmer orangefarbener Rüstung bleibt vor der kühlen Stadt gut erkennbar.

Neu integriert: hochauflösendes Stadtbild, drei getrennte Heldenporträts, sechs eigenständige Gegner-Silhouetten als Atlasbasis für die vorhandenen Gegnertypen, animierte Lichter und Regenspuren, modulierte Zustands-/Treffereffekte, neue Gates und Injektionskopf, Typografie mit Space Grotesk/JetBrains Mono sowie zwölf eigens gezeichnete SVG-Upgradeglyphen. Alle 48 Karten wählen eine passende Symbolkategorie und zeigen die echten Spieleffekte. Native Touch-/Mauskontrollen bleiben aktiv.

Die Originalatlanten liegen unverändert unter `assets/art/`. `atlas_regions.py` liest lediglich die Alpha-Grenzen pro Zelle und schreibt JSON-Quellrechtecke; es ändert keine Bildpixel. Optionales Entwicklungswerkzeug: Python mit Pillow. Das Spiel und CI brauchen diese Python-Abhängigkeit nicht, weil Assets und Quellrechtecke eingecheckt sind. `generate_ui.py` erzeugt die skalierbaren Originalglyphen deterministisch.

Die Rasterquellen haben folgende native Größen: Stadt 1672 × 941, Helden 2172 × 724, Gegner 1536 × 1024. Die Stadtdatei kann bei anderen originalen Generatorausgaben abweichen; maßgeblich sind die eingecheckten Bildabmessungen. Große Einzelkörper werden aus den jeweiligen Atlasteilen skaliert. UI, Glyphen, Panels, Gates und Schrift werden dagegen in Zielauflösung gerendert. Wir bezeichnen die Rasterassets deshalb nicht als durchgängig native 4K-Texturen.

Echte 4K-Hochformat-Ausgaben (2160 × 3840) des laufenden Godot-Renderers liegen unter `docs/screenshots/neon-*-4k.png`. Die Capture-Szene platziert einige tatsächliche Gegner für eine reproduzierbare Ansicht und hält den automatischen Kampf an; die Kugelphysik und Menüfunktionen bleiben echte Spielsysteme. Es sind keine nachträglich montierten UI-Mockups.

Für Android bleibt die logische 9:16-Spielfläche 540 × 960; CanvasItems skaliert auf die Geräteausgabe. 4K-Vorschauen sind ein visueller Qualitätsnachweis und keine Behauptung einer gemessenen 4K/60-FPS-Leistung auf dem Smartphone. Die Qualitätsstufe beschränkt sichtbare Physikkörper auf 64 bzw. 128. Rasterfiguren haben derzeit prozedurales Bobbing, Recoil, Trefferfärbung und Zustandsanimation, aber noch keine vollständigen handgezeichneten Lauf-/Schuss-Framefolgen. Weltunterschiede sind teilweise weiterhin Paletten-/Overlayvarianten derselben Stadtbasis.

## Reaktorschmiede 0.2.3

Die neue Originalkulisse `assets/art/reactor_forge.png` (1402 × 1122) zeigt eine vertiefte Metallkammer mit Induktionskern, Lichtleitern und Sammelrinne. Sie ist als Spielfeldhintergrund in die tatsächliche Godot-Szene eingebunden; Tore, Kugeln, Kollisionen und Bedienung bleiben echte Spielobjekte. Drei helle, segmentierte Lasertore haben beleuchtete Elektroden und deutlich größere Zahlen. Neutrale ×1-Wege sind gedämpft. Der Injektor reagiert auf jede tatsächlich emittierte Kugel. Aufpralle, Multiplikation und Sammlung lösen lokale additive Flares mit kurzen Lichtkernen, Ringen und Funken aus. Eine Energieleitung verbindet den Sammler sichtbar mit dem echten Munitionszähler.

`ReactorFX` begrenzt Ereignisse auf 24/10 und Funken auf 96/24 für hohe/niedrige Qualität. Es gibt eine gemeinsame additive CanvasItem-Passage mit einer wiederverwendeten radialen Gradiententextur, keinen Vollbild-Bloom-Postprozess. Physikkörper und virtuelle Mengen behalten ihre bisherigen Grenzen. Der visuelle Zufallsgenerator ist vom Spiel getrennt; Pause friert die Effekte ein und verbirgt sie hinter dem Menü.

UX: Die große Reaktor-Touchfläche und der Positionsregler sind synchronisiert. Ein laufender Abwurf blockiert weitere Abwürfe bis zur Sammlung. Lagerfüllstand, knappe Munition, fließende Einheiten, tatsächlicher Ertrag und Überlauf sind verschiedene sichtbare Zustände. Die gerade Route wird als Orientierung mit ausdrücklichem Hinweis auf Abpraller dargestellt. Die Impulsanzeige benennt die tatsächliche Aktivierungsschwelle von 50 Energie. Upgrade-Karten nennen die nächste Horde und den neuen Abwurf; der Ressourcenstreifen bleibt vollständig sichtbar.

`tests/capture_reactor.gd` erzeugt neue Ansichten aus einem normalen Level-3-Lauf mit echten Eingaben, Kampf und Physik, ohne Gegner zu platzieren oder Kampfwerte zu ändern. `-- --4k` rendert optional nativ 2160 × 3840. Die alten `neon-*-4k`-Ansichten bleiben als historische Layout-Fixtures erhalten.


## Arsenal 0.2.4

Alle zwölf Waffen besitzen eigene SVG-Silhouetten mit Stahlbevels und Cyan-Akzenten. Sammlung, aktuelle Auswahl und tatsächlich ausgerüstete Waffe sind visuell getrennt; gesperrte Waffen bleiben als Vorschau anklickbar, während Equip/Upgrade gesperrt sind. Klassenkarten sind kompakter, sodass die ganze Sammlung ohne Scrollen erreichbar ist. Der Detailbereich erklärt Rolle, Schaden, Feuerrate, Magazin, Nachladezeit und die konkrete Freischaltung. Lange Waffennamen werden vollständig angezeigt und automatisch geprüft. Alle Ziele sprechen von Einsätzen/Sektoren; Heldenlevel wird ausdrücklich als HELD LV bezeichnet.

Ergebnis- und Kartenoberflächen blenden kurz ein; Eingaben werden nicht künstlich verzögert. Keine Kaufzwänge, Serienverluste, zeitlich begrenzten Angebote oder Zufallskäufe. Die Bindung entsteht aus sichtbaren Zielen, dauerhaften Freischaltungen, sinnvollen Entscheidungen und klarer Rückmeldung. Screenshots aus Godot unter `docs/screenshots/progression-*-v0.2.4.png`, jeweils 2160 × 3840.
