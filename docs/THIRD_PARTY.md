# Fremdkomponenten

- Godot Engine 4.6.3, MIT-Lizenz, https://godotengine.org/license/ . Die offizielle Android-/Windows-Laufzeit enthält weitere Komponenten; die vollständigen Engine-Lizenzhinweise sind über https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt abrufbar. Vor einer Veröffentlichung die dortigen Weitergabepflichten vollständig in den Distributionsunterlagen berücksichtigen.
- DejaVu Sans: Bitstream-/DejaVu-Lizenzen in `assets/fonts/LICENSE-DejaVu.txt`.
- Android SDK: offizielle Google-Entwicklungswerkzeuge, Lizenzen im SDK-Verzeichnis `licenses/`. SDK-Werkzeuge und Schlüssel werden nicht ins Repository aufgenommen.
- Keine Assets aus den Referenzscreenshots wurden kopiert. Originale Grafikbefehle und mathematisch synthetisierte Musik/Sounds liegen im Projekt.

- Space Grotesk und JetBrains Mono: SIL Open Font License, vollständige Texte unter `assets/licenses/SpaceGrotesk.txt` und `assets/licenses/JetBrainsMono.txt`.
- Die neuen Stadt-/Helden-/Gegnerillustrationen und die Reaktorschmiede wurden für dieses Projekt mit Bildgenerierung erstellt und lokal eingebunden. SVG-Interfaceglyphen und Panels sind eigens implementiert. Es wurden keine Grafikbestandteile aus dem Nutzerreferenzspiel übernommen.
- „Endless Survival.mp3“: vom Nutzer für die Hintergrundmusik bereitgestellte Aufnahme, unverändert lokal eingebunden. Keine Behauptung, dass diese Aufnahme aus dem synthetischen Audio-Generator des Projekts stammt.

- Die zwölf Waffenillustrationen und das Schlosssymbol unter `assets/ui/weapons/` sind eigens erstellte SVG-Vektoren; Generator `scripts/generate_weapon_art.py`.

- `assets/art/first_light.png`: neue Original-Startillustration für dieses Projekt per Bildgenerierung erstellt. Die bewegte Vorschau ist eine echte Godot-Aufzeichnung mit der integrierten, vom Nutzer gelieferten Hintergrundmusik.


- Quarantine 0.2.6: `assets/art/quarantine_terminal.png` ist eine neue für dieses Projekt generierte Originalillustration (native Quelle 941 × 1672), unverändert lokal eingebunden. Die Sci-Fi-Horror-Richtung orientiert sich an der gewünschten Stimmung; keine Benutzeroberfläche, Bilder, Figuren, Logos oder sonstigen Assets aus *Dead Space* wurden übernommen.
- `ActorRig`, `BloodFX` und die Quarantine-Konsolenoberfläche sind eigener GDScript-/Shadercode. Texturierte Gangsegmente verwenden die bereits dokumentierten eigenen Helden-/Gegneratlanten; Blut-/Ölformen werden prozedural gezeichnet. Es wurden dafür keine fremden Sprite-Framefolgen, Bluttexturen oder Skelettanimationen eingebunden.
- Die Quarantine-Vorschau verwendet die Spielausgabe und die bestehende, vom Nutzer bereitgestellte Hintergrundmusik. Die Aufzeichnung ist kein zusätzlicher Fremdasset-Zukauf und kein Smartphone-Leistungsnachweis. Tatsächliche Aufnahme-/Buildnachweise stehen im Buildbericht.


- Circuit & Gear 0.2.7 benötigt kein neues externes Artwork. Multiplikatoraperturen, Metallhindernisse, Portalöffnungen, Powerzellen und die sichtbaren `HeroGear`-Anbauteile sind eigener prozeduraler Godot-Zeichencode. Die vorhandenen eigenen Helden-/Reaktorillustrationen und SVG-Symbole werden weiterverwendet; es wurden keine fremden Ausrüstungs-, Portal- oder Multiplikatorgrafiken übernommen.
- Die geplante Circuit-Vorschau nutzt die bestehende Spielausgabe und eingebundene Musik. Aufnahmebedingungen sowie gegebenenfalls gezielt vorbereitete Gear-Testzustände werden im Buildbericht offengelegt; eine Vorschau behauptet weder einen ungeprüften öffentlichen Build noch Smartphone-Messwerte.
