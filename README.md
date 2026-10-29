# DEADWAVE HEROES · RF Worlds

Spielbarer Godot-4.6.3-Prototyp **v0.2.10**, Android und Windows, Hochformat 540 × 960. Eigenständige generierte Sci-Fi-Illustrationen und skalierbare Vektoroberfläche mit „Endless Survival“ als Hintergrundmusik. Vollständig offline, keine Werbung, keine In-App-Käufe.

## Live Ops 0.2.10

Der Kampf läuft mit 125 % Tempo: Gegner, Schüsse, Nachladen und Kampfstatus werden gemeinsam beschleunigt; Kugeln behalten ihre normale Physik. Waffenanzeigen berücksichtigen das effektive Tempo.

Während des Kampfes erscheinen freiwillige Bonusangebote. Drei Wischrichtungen liefern bis zu 24 normale Munition (bei vollem Lager bis zu zwölf Energie), ein vierstelliger Code aus den Tasten 1–4 liefert 18 dauerhaft gespeicherte Credits. Ein Angebot bleibt zehn Sekunden verfügbar; nach Öffnen bleiben sieben Sekunden. Fehler setzen die Eingabefolge zurück, ohne Ressourcen abzuziehen. Pause hält die Frist an. Höchstens zwei Angebote pro Welle, abwechselnde Aufgaben, einmalige Belohnungen. Der Kampf läuft währenddessen weiter und das Kugelfeld bleibt bedienbar.

[Bonusaktion im Spiel](docs/screenshots/live-ops-v0.2.10.png). Der Screenshot stammt aus einem gezielten Eingabetest. Aktueller Build- und Downloadnachweis im [Buildbericht](docs/BUILD_REPORT.md).

## Elemental 0.2.9

**Brand, Kryo und EMP** erhalten eigene, deutlich sichtbare Schuss-, Einschlags- und Statuseffekte. Brand verbindet glühende Geschossspuren mit Flammen und Funken am getroffenen Gegner. Kryo setzt auf kalte Leuchtspuren, Eissplitter und Reif; EMP auf elektrische Bögen und kurze Impulsringe. Die vorhandene Munition und die echten Statuswerte steuern die Darstellung. Lesbare Typanzeigen im Waffenstreifen und klarere Veredelungsaperturen helfen bei der Wegwahl.

Die **Unterstützungsdrohne** bekommt ein kompaktes gepanzertes Gehäuse mit zwei Antrieben, Kamera und eigener Waffe. Schweben, Rückstoß und der sichtbare Schuss folgen ihrer tatsächlichen Position. Die Effekte verwenden feste Budgets und berücksichtigen reduzierte Bewegung sowie die sparsame Qualitätsstufe.

[Brand](docs/screenshots/elemental-fire-v0.2.9.png) · [Kryo](docs/screenshots/elemental-frost-v0.2.9.png) · [EMP](docs/screenshots/elemental-emp-v0.2.9.png) · [Drohne](docs/screenshots/support-drone-v0.2.9.png) · [Bewegte Vorschau](docs/previews/DeadwaveHeroes-v0.2.9-motion.mp4)

Die veröffentlichten Elemental-Aufnahmen sind gezielte Darstellungstests im laufenden Godot-Spiel mit kontrollierten Testzuständen, echten Schüssen und realen Statuseffekten. Sie zeigen keinen erspielten Kampagnenfortschritt. Tatsächlich ausgeführte Prüfungen, erzeugte Dateien und veröffentlichte Downloads werden im [Buildbericht](docs/BUILD_REPORT.md) dokumentiert. Die verifizierte Vorgängerversion steht weiterhin im Abschnitt Forge 0.2.8.

## Forge 0.2.8

Eine echte **Weiche** macht den Abwurf steuerbarer: Während laufender Kugelproduktion lässt sie sich genau einmal pro Abwurf umstellen. Der erste physische Prallkörper schwenkt zur anderen Seite und lenkt die tatsächlichen Kugelbahnen um. Die Taste zeigt Richtung und Verfügbarkeit; beim Pausieren hält auch die Bewegung an. Ein neuer akzeptierter Abwurf lädt die Weiche wieder auf.

Der gewählte Weg erzeugt **Spezialmunition**. Ein benutztes Portal prägt EMP ein; ein aktiver Multiplikator der mittleren Reihe prägt links Brand und rechts Kryo ein. Die erste Prägung bleibt erhalten. Freie Durchgänge veredeln nichts. Der Sammler macht höchstens zwölf tatsächlich eingelagerte Einheiten pro Abwurf zu Spezialladungen, bei maximal 36 Spezialladungen im Vorrat. Sie sind Teil des angezeigten Munitionsbestands: kein Zusatzvorrat, kein Gewinn durch Überlauf und keine Vervielfachung durch sichtbare Repräsentanten. Die Waffe nutzt vorhandene Ladungen automatisch; das HUD zeigt Typ und Menge. Brand verursacht kurzen Folgeschaden, Kryo verlangsamt und EMP unterbricht kurz mit Abklingzeit. Bosse erhalten schwächere Kontrollwirkungen.

Die **Werkbank** im Hauptmenü bietet drei dauerhaft gespeicherte Ausbaureihen: Munitionsgürtel (+40 Kapazität je Rang), Schutzpanzer (+1 Rüstung je Rang) und Waffenmodul (+5 % Basisschaden je Rang, bis +15 %). Jede Reihe besitzt drei Ränge für 180 / 540 / 1.080 Credits. Rang 1 verlangt einen wirklich abgeschlossenen Einsatz 1, Rang 2 Einsatz 5 und Rang 3 den Boss aus Einsatz 10. Helden-XP und bloß freigeschaltete Einsätze ersetzen diesen Siegnachweis nicht. Die Vorschau zeigt die tatsächliche Ausrüstung vor dem Kauf; Gürtel, Panzer und Waffenmodul bleiben beim nächsten Einsatz am Helden sichtbar und wirksam. Run-Karten kommen weiterhin für den jeweiligen Einsatz hinzu.

Beim ersten tatsächlichen Bosskontakt gibt es einmal pro Begegnung **einen zusätzlichen Notfall-Abwurf**. „BOSSKONTAKT · +1 NOTFALL-ABWURF“ macht ihn sichtbar. Er liefert keine direkte Munition: Abwurfposition, Wegwahl und Sammlung bleiben notwendig.

[Spielansicht](docs/screenshots/forge-gameplay-v0.2.8.png) · [Werkbank](docs/screenshots/forge-workshop-v0.2.8.png) · [Bewegte Vorschau (MP4)](docs/previews/DeadwaveHeroes-v0.2.8-motion.mp4)

Die öffentliche APK, das Spielvideo und beide 4K-Ansichten wurden vollständig heruntergeladen und geprüft. Tests, Prüfsummen und Update-Signatur stehen in [BUILD_REPORT.md](docs/BUILD_REPORT.md).

## Circuit & Gear 0.2.7

Das Kugelfeld ist als offener physischer Circuit überarbeitet: durchlässige, beleuchtete Multiplikatorlinsen statt großer Statuskarten, plastische Prallkörper, rotierende Metallhindernisse und ein sichtbares Portalpaar. Aktive Multiplikatoren beginnen bei **×2**. Neutrale Wege sind echte freie Durchgänge ohne ×1-Beschriftung, Torhardware, Multiplikationslicht oder Multiplikationssound; sie verändern die Kugelmenge nicht. Die Werte wechseln weiterhin reproduzierbar zwischen den Wellen und bleiben während eines Abwurfs fest.

Jedes Layout enthält drei feste/rotierende Hindernisse und einen Portaleingang mit sichtbarem Ausgang; ab Einsatz 50 kommt ein viertes physisches Hindernis dazu. Das Portal versetzt eine berührende Kugel einmal auf die gegenüberliegende Seite oberhalb der zweiten Multiplikatorreihe. Damit ändern sich tatsächliche Wege und mögliche Erträge. Bestehende gespeicherte Layouts erhalten einmalig Circuit-Version 2: Hindernisliste und Circuit-Versionsfeld werden erneuert, Seed, ursprüngliche Gates, Fortschritt und übrige gespeicherte Daten bleiben erhalten. Die neue Wegeführung ist eine begründete Layoutänderung, keine Zusage identischer Erträge oder perfekter Balance aller 100 Einsätze.

In Welle 2, 5, 8 und danach jeder dritten Welle erscheint höchstens eine optionale **Powerzelle**. Eine echte Kugel aktiviert sie einmalig innerhalb ihres Radius von 30 Pixeln. Je nach Zelle gibt es +12 Spezialenergie bis maximal 100, fünf aktive Spielsekunden **Overdrive** mit +25 % Feuerrate oder +12 Schildpunkte bis zu 75 % Maximalleben. Ein bereits stärkerer Schild bleibt erhalten. Repräsentiert eine sichtbare Kugel viele virtuelle Einheiten, gibt die Zelle trotzdem nur eine Belohnung.

Verbesserungen sind am Helden sichtbar: Kapazitäts-, Magazin- und Abwurf-Upgrades ergänzen Munitionsgürtel und Träger; Rüstung setzt zusätzliche Platten an, Dornen erzeugen Spitzen, Regeneration ein medizinisches Modul. Waffenrang und Schadensverbesserungen erweitern das Waffenmodul. Schild, zusätzlicher Drohnensupport und aktiver Overdrive erhalten passende Anzeigen am Körper. `HeroGear` leitet alles aus tatsächlichen Werten ab und folgt der animierten Körperhaltung. Run-Ausrüstung beginnt im nächsten Einsatz neu; dauerhaft gekaufte Waffenränge bleiben bestehen. Es gibt dafür keinen zusätzlichen Kosmetikshop.

[Circuit im Spiel](docs/screenshots/circuit-live-v0.2.7.png) · [Powerzelle](docs/screenshots/circuit-power-v0.2.7.png) · [Sichtbare Aufrüstung](docs/screenshots/circuit-gear-v0.2.7.png) · [Bewegte Vorschau (MP4)](docs/previews/DeadwaveHeroes-v0.2.7-motion.mp4)

Aufnahmebedingungen, automatisierte Tests und tatsächlich verifizierte öffentliche Builds stehen in [BUILD_REPORT.md](docs/BUILD_REPORT.md). Insbesondere wird dort zwischen normalen Spieleingaben und einer gegebenenfalls gezielt aufgebauten Gear-Testansicht unterschieden. Ein Aufnahmevideo belegt keine gemessene Smartphone-Leistung.

Die ersten beiden Upgrade-Auswahlen in den Tutorial-Einsätzen 1–3 bieten noch nicht gewählten Gürtel und Panzer gezielt an. Es bleiben freiwillige Karten mit ihrer regulären Wirkung; spätere Angebote bleiben zufällig und berücksichtigen den Ressourcenbedarf.

## Quarantine 0.2.6

Eigenständige Sci-Fi-Horror-Oberfläche: dunkler Stahl, eingelassene Konsolen, kalte Cyan-Hologramme, warmes Schriftweiß und bernsteinfarbene Warnungen. Startmenü, HUD, Reaktor, Arsenal, Karte, Upgrade-Auswahl, Pause und Ergebnisansichten verwenden dieselbe Formsprache. Feine Rasterlinien, beleuchtete Kontakte und lokale Lichtläufe bleiben zurückhaltend; Touchflächen und Text bewegen sich beim Drücken nicht. Die neue Originalillustration `assets/art/quarantine_terminal.png` bildet den Einstieg. Die gewünschte Horror-Stimmung ist eine gestalterische Referenz; es wurden weder Oberfläche noch Grafiken, Logos oder Figuren aus *Dead Space* kopiert.

Die vorhandenen Figurenillustrationen werden jetzt als texturierte Segmente mit getrennten Schritten für Beine, Knie und Füße verformt. Läufer, schwere Gegner, Kriecher und vierbeinige Gegner besitzen unterschiedliche Gangarten. Der Held macht beim Einsatzbeginn einen kurzen, 0,68 Sekunden langen Antritt und geht anschließend in eine stehende Schusshaltung mit Atmung und Rückstoß über. Das sind prozedurale Cutout-Animationen bestehender Rastergrafiken, keine vollständigen handgezeichneten Einzelbildfolgen und keine neue frei steuerbare Laufmechanik.

Treffer und Abschüsse erzeugen gerichtete Blutspritzer, Tropfen und unregelmäßige Bodenflecken, die abdunkeln und ausblenden. Roboter geben stattdessen Öl/Kühlmittelfeedback. Heldenblut erscheint nur bei tatsächlich erlittenem Lebensschaden. Unter Optionen sind **Bluteffekte** abschaltbar und **Bewegung reduziert** wählbar. Effekte bleiben auf das Schlachtfeld begrenzt, pausieren mit dem Spiel und verändern keine Kampfwerte, Kugelmengen oder Spielzufallsentscheidungen. Partikel und Flecken haben feste Budgets pro Qualitätsstufe.

[Startansicht](docs/screenshots/quarantine-menu-v0.2.6.png) · [Spielansicht](docs/screenshots/quarantine-gameplay-v0.2.6.png) · [Arsenal](docs/screenshots/quarantine-arsenal-v0.2.6.png) · [Upgrades](docs/screenshots/quarantine-upgrades-v0.2.6.png) · [Karte](docs/screenshots/quarantine-map-v0.2.6.png) · [Optionen](docs/screenshots/quarantine-settings-v0.2.6.png) · [Bewegte Vorschau (MP4)](docs/previews/DeadwaveHeroes-v0.2.6-motion.mp4)

Build-, Aufnahme- und Veröffentlichungsnachweise stehen in [BUILD_REPORT.md](docs/BUILD_REPORT.md). Eine MovieMaker-Aufnahme mit festem Zeitschritt ist keine FPS-Messung auf einem Smartphone. Waffenfreischaltungen, Hintergrundmusik und das bisherige Savegame bleiben integriert.

## Cinema & Motion 0.2.5

Neuer bildfüllender Einstieg mit eigener Action-Illustration, Kamerafahrt, Lichtimpulsen und schwebenden Partikeln. Dieselbe Illustration ist als Startbild eingebunden. Die Oberfläche verwendet runde Flächen, warme Coral-Akzente, kräftigere Titel und klare Touchflächen. Druckfedern, Ripples und Lichtläufe bewegen nur die gezeichnete Oberfläche; die eigentliche Trefferfläche bleibt stabil. Seiten blenden kurz ein und bleiben sofort bedienbar.

Der Kampf besitzt zusätzliche prozedurale Atem-, Rückstoß-, Lauf- und Trefferanimationen, Hülsen, kurze Todesanimationen und Impulswellen. Effekte sind begrenzt, auf den Kampfbereich zugeschnitten und verwenden einen getrennten visuellen Zufall. Unter Optionen kann die Bewegung reduziert werden. Die ersten drei Einsätze staffeln drei vorhandene Gegner näher an den Helden; der erste echte Schuss fällt innerhalb einer Sekunde. Gegnerzahl, Schaden, Munition und Freischaltungen bleiben reguläre Spielwerte.

[Neue Startansicht](docs/screenshots/cinema-menu-v0.2.5.png) · [Spielansicht](docs/screenshots/cinema-gameplay-v0.2.5.png) · [Bewegte Vorschau (MP4)](docs/previews/DeadwaveHeroes-v0.2.5-motion.mp4)

## Arsenal und Fortschritt 0.2.4

Die Maschinenpistole wird nach Einsatz 3 freigeschaltet, das Sturmgewehr nach Einsatz 6. Bosswaffen verlangen den jeweiligen Bosssieg. Helden-XP umgeht diese Bedingungen nicht. Das Arsenal zeigt alle zwölf Waffen mit eigenen SVG-Illustrationen, Rollen, Werten und konkreten Voraussetzungen. Gesperrte Waffen lassen sich ansehen; Ausrüsten und Aufwerten sind zusätzlich in der Spiellogik gesperrt. Neue Freischaltungen erscheinen auf dem Siegbildschirm und im Arsenal.

Fünf Aufwertungsränge pro Waffe, jeweils +10 % Basisschaden. Kosten: 120, 480, 1.080, 1.920 und 3.000 Credits. Gespeicherte Altränge bleiben erhalten; ihre aktive Wirkung ist auf Rang 5 begrenzt. Bestehende Währung, Sterne, Einstellungen und Layouts bleiben erhalten.

Upgrade-Karten zeigen vorher/nachher-Werte für zentrale Attribute. Bei niedrigem Munitionsvorrat ist mindestens eine Produktions-/Nachschubkarte im Angebot; volle Heilung, volle Energiebatterien und bereits ausgeschöpfte Chancen werden vermieden. Ergebnisse zeigen Credits, XP, Abschüsse, Heldenaufstieg und das nächste Waffenziel. Doppelte Abschluss-Callbacks geben keine doppelten Belohnungen.

Balance: Der Revolver trifft ein einzelnes Ziel; die Maschinenpistole und das Maschinengewehr sind munitionseffizienter. Sekundärtreffer beachten die Waffenreichweite. Flächenschaden trifft bis zu fünf zusätzliche nahe Gegner; der Impuls hat eine Reichweite von 360 und kann seinen eigenen Schildvorrat bis auf 75 % des Maximallebens aufbauen. Größere Ausrüstungsschilde bleiben erhalten. Die frühen Einsätze behalten ihre 105 Gegner.

[Neues Arsenal](docs/screenshots/progression-arsenal-v0.2.4.png) · [Gesperrte Waffe](docs/screenshots/progression-locked-v0.2.4.png) · [Freischaltung](docs/screenshots/progression-unlock-v0.2.4.png)

## Reaktorschmiede 0.2.3

Neue detaillierte Reaktorkulisse, animierte Laser-Tore, echte Aufprallfunken, Kugelschweife und additive Light Flares bei Multiplikation und Sammlung. Energie fließt sichtbar zum Munitionszähler. Eine große Touchfläche und der Regler steuern dieselbe Abwurfposition. Die Anzeige unterscheidet fließende virtuelle Einheiten, tatsächlich gutgeschriebene Munition und Überlauf; ein Füllbalken macht knappe Munition erkennbar. Während einer laufenden Produktion verhindert die Abwurfsperre versehentliche Doppeltipps. Die angezeigte gerade Route ist ausdrücklich kein Versprechen des tatsächlichen Wegs nach Kollisionen. Der Impuls zeigt seine tatsächliche Schwelle von 50 Energie.

Sammelboni erhalten Bruchteile über alle Repräsentanten: vier einzelne Kugeln mit +25 % liefern wie eine Gruppe von vier Kugeln exakt fünf Munition. Flare- und Partikelzahlen sind pro Qualitätsstufe begrenzt; die Effekte verwenden einen getrennten Zufallsgenerator und pausieren zusammen mit dem Spiel.

[Echte Spielansicht](docs/screenshots/reactor-v0.2.3.png) · [4K-Ausgabe](docs/screenshots/reactor-v0.2.3-4k.png) · [Upgrade-Auswahl](docs/screenshots/reactor-upgrades-v0.2.3.png)

## Horden und Multiplikatoren

Die ersten drei Einsätze enthalten 105 Gegner in fünf Wellen (15, 18, 21, 24, 27) statt insgesamt 30. Gegner kommen häufiger und ab Welle 2 in Gruppen; maximal 40 sind gleichzeitig aktiv. Anfangs gibt es drei Abwürfe und danach einen weiteren pro Welle. Das Basis-Munitionslager wächst mit dem Einsatz (Level 1: 248, Level 3: 264), Kapazitäts-Upgrades bleiben wirksam. Bei vollem Lager werden keine Abwurfversuche verschwendet.

Multiplikatoren wechseln reproduzierbar pro Level/Welle. Aktive Gates verwenden ×2 oder mehr; neutrale Wege sind offene Durchgänge ohne ×1-Anzeige und ohne Mengenänderung. Größere Faktoren werden in späteren Welten eingeführt. Werte bleiben während laufender Kugelabwürfe fest: Eine Welle endet erst nach vollständigem Einsammeln. Circuit-Version 2 aktualisiert einmalig die Hindernisgeometrie gespeicherter alter Layouts; der ursprüngliche Seed und der Fortschritt bleiben erhalten.

## Hintergrundmusik

Die vom Nutzer bereitgestellte Originaldatei „Endless Survival.mp3“ ist unverändert als lokale Hintergrundmusik eingebunden. Sie läuft im Hauptmenü, bei normalen Wellen und Bossen in Schleife weiter; der Wechsel zwischen diesen Zuständen startet den Song nicht neu. Sieg/Niederlage behalten ihre musikalischen Abschlüsse. Musik und Effekte haben getrennte Lautstärkeregler; Musik kann vollständig stummgeschaltet werden. Keine Streamingverbindung erforderlich.

## Spielen

1. Einsatz starten. Oben kämpft der Held automatisch und verbraucht echte Munition.
2. Direkt im Reaktor oder den Schieberegler über dem Spielfeld ziehen und **ABWERFEN** drücken. Die Abwurfversuche sind begrenzt; jede neue Welle gewährt einen weiteren.
3. Echte Physikkugeln passieren unterschiedlich starke Multiplikatoren. Links/rechts gewählte Wege ändern die Produktionsmenge. Der Sammler schreibt die repräsentierte Menge als Munition gut, bis zur Kapazität.
4. Während des Abwurfs bei Bedarf einmal die **WEICHE** umstellen. Portal und aktive mittlere Tore veredeln einen begrenzten Teil der gesammelten Munition zu EMP, Brand oder Kryo. Zwischen Wellen eine kostenlose Verbesserung wählen. **IMPULS** verbraucht 50 Energie, trifft Gegner und erzeugt einen Schutzschild. Bei Bosswarnungen einsetzen.
5. Einsätze abschließen, Sterne und Münzen verdienen. Im Arsenal Waffen ausrüsten und dauerhaft verbessern; in der Werkbank Gürtel, Panzer und Waffenmodul ausbauen. Alle drei Klassen sind im Prototyp sofort verfügbar.

Die Levelkarte enthält 100 feste, gespeicherte Layouts in zehn Welten. Waffen werden über den Fortschritt freigeschaltet; an Bosslevel gebundene Waffen erfordern den Sieg über diesen Boss. Aufgeben ist über Pause möglich. Laufende Einsätze werden beim Verlassen nicht wiederaufgenommen; dauerhafte Belohnungen und Freischaltungen bleiben erhalten.

## Android installieren

**[Android-APK v0.2.10 herunterladen](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.10-debug/DeadwaveHeroes-v0.2.10-debug.apk)** · [Downloadseite](https://github.com/Whiskymitschuss/New-Game/releases/tag/v0.2.10-debug). Download, Prüfsumme und Update-Signatur sind verifiziert; Details stehen im [Buildbericht](docs/BUILD_REPORT.md).

Bereits verifiziert: **[APK v0.2.8 herunterladen](https://github.com/Whiskymitschuss/New-Game/releases/download/v0.2.8-debug/DeadwaveHeroes-v0.2.8-debug.apk)**. Der öffentliche Download benötigt keinen GitHub-Login und kein Entpacken eines Actions-Archivs.

Die neue Exportkonfiguration erzeugt `builds/DeadwaveHeroes-v0.2.9-debug.apk` für Android 7/API 24 oder neuer, ARMv7/ARM64. Die APK aufs Smartphone übertragen, öffnen und bei Bedarf die Installation aus dieser Quelle erlauben. Es ist eine **Debug-Testversion**. Release-Signierschlüssel liegen nicht im Repository; CI verwendet den im Actions-Cache gespeicherten Debug-Schlüssel.

Das Savegame-Format bleibt kompatibel. Die heruntergeladene öffentliche v0.2.9 besitzt dieselbe Signieridentität und dasselbe Paket wie v0.2.8 bei höherem Versionscode. Die Update-Bedingungen sind geprüft; ein Test auf einem physischen Android-Gerät steht noch aus.

APK, Windows-ZIP und Prüfprotokolle der v0.2.9 stehen im erfolgreichen [GitHub-Actions-Lauf 40847844687](https://github.com/Whiskymitschuss/New-Game/actions/runs/40847844687) unter **Artifacts**.

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
- Ein Modulkatalog mit zehn Mechaniken und jeweils drei Konfigurationen: Rampen, Pins, Rotoren, Wände, Portale, Beschleuniger, Bonusfelder, Falltüren, Richtungswechsler und zerstörbare Balken. Das sind 30 Kombinationen, keine 30 völlig unterschiedlichen Mechaniken. Der aktuelle Circuit-Generator setzt drei physische Hindernisse plus ein Portalpaar ein, ab Einsatz 50 vier Hindernisse plus Portalpaar. Seltene Powerzellen ergänzen einzelne Wellen.
- Eine umstellbare physische Weiche pro Abwurf, begrenzte wegabhängige Brand-/Kryo-/EMP-Ladungen und drei permanente Werkbank-Ausbaureihen mit sichtbarer Ausrüstung.
- Drei Klassen, zwölf konfigurierbare Waffen mit unterschiedlichen Schadens-/Reichweiten-/Nachlade-/Effektwerten und Sounds, 48 funktionale Upgrade-Karten einschließlich klassenspezifischer Karten.
- 15 Gegnertypen; Angriffe, Statusschaden, Panzerung, Fernangriffe ab Level 20. Zehn parametrisierte Bossbegegnungen mit unterschiedlicher Spezialfähigkeit, Warnung und zweiter Phase.
- 100 reproduzierbare und gespeicherte Level, fünf bis vierzehn Wellen, Progression, Waffenverbesserung, Klassen-/Waffenauswahl, Outfits, Charakterwerte, Pause, Sieg, Niederlage, Musik-/Effektregler.
- Versionierter JSON-Spielstand mit temporärer Datei, Backup und Wiederherstellung. Level-Layouts, Seeds, Sterne, XP, Münzen, Entdeckungen, Klassen, Waffenverbesserungen, Statistiken und Einstellungen werden gespeichert. Abgeworfene Run-Upgrades gelten für den aktuellen Einsatz.

## Design und Regressionstests

`tests/reuse.gd` prüft das wiederholte Recycling derselben Physikkörper. `tests/ui_layout.gd` prüft alle 48 Upgrade-Karten, Klassenporträts und Waffennamen. `tests/render_balls.gd` prüft echte sichtbare Bildpunkte und vier aufeinanderfolgende gerenderte Abwürfe; hierfür ist eine grafische Sitzung erforderlich. Hinzu kommen Eingabe-/Shaderprüfungen für `InterfaceMotion`, die Gelenk-/Standphasen von `ActorRig`, die Grenzen und Zustände von `BloodFX`, die Circuit-Layout-/Portal-/Powerzellenlogik, die statabhängige Ausrüstung von `HeroGear` die einmal pro Abwurf bedienbare `ReactorSwitch`, die mengenbegrenzte `SpecialAmmo`, die dauerhaft gespeicherte `Workshop` und ihre echte Spielintegration sowie vollständige Kampagnen-/Waffenprobeläufe. Tatsächlich ausgeführte Suiten, Ergebnisse und verbleibende Gerätetestlücken werden pro Version im Buildbericht festgehalten.

```bash
# In einer vorhandenen grafischen Sitzung, nachdem env.sh geladen wurde:
"$GODOT_BIN" --path . --audio-driver Dummy --fixed-fps 60 --script res://tests/render_balls.gd
"$GODOT_BIN" --path . --audio-driver Dummy --fixed-fps 60 --script res://tests/capture.gd -- --4k
```

Die historische `tests/capture.gd` stellt Gegner für reproduzierbare UI-Aufnahmen auf. Neuere Capture-/Film-Skripte dokumentieren reguläre Spielabläufe; deren Eingaben und Aufnahmebedingungen stehen im Buildbericht. Details zu Assetauflösungen und visuellen Grenzen: `docs/ART_DIRECTION.md`.

## Bewusster Entwicklungsstand

Dies ist **kein fertiges v1.0-Spiel**. Die Inhaltszahl ist technisch vorhanden; das beweist nicht, dass alle 100 Level unter menschlichen Spielbedingungen ausbalanciert oder alle Bossbegegnungen ausreichend abwechslungsreich sind. Die Waffen verwenden direkte Treffer mit sichtbaren Schussspuren und Status-/Flächeneffekten; physikalisch fliegende Raketen und Granaten sind weitere Arbeit. Gegner und Bosse nutzen gemeinsame Animations-/Spritebausteine. Die Quarantine-Präsentation verwendet texturierte Cutout-Gelenke und prozedurale Effekte; die Rasterfiguren haben weiterhin keine vollständig gezeichneten Animationssequenzen. Audio und einzelne Weltvarianten benötigen weitere Art-Produktion. Eine separate Ausrüstungsbeute-/Skinfreischaltungsökonomie, mehr Boss-Angriffsmuster, Welt-Ambiences, detaillierte Tutorialführung, Gerätemessungen und Releasevorbereitung fehlen noch. Keine Android-Gerätetests und keine Windows-Ausführung sind durch den Linux-Export allein nachgewiesen.

Siehe `docs/ROADMAP.md`, `docs/BUILD_REPORT.md` und `docs/ARCHITECTURE.md`.

## Lizenzen

Spielcode und eigens erzeugte Spielgrafiken/-töne: RF Worlds, alle Rechte vorbehalten. Schriften: Space Grotesk und JetBrains Mono (SIL Open Font License), DejaVu-Lizenz zusätzlich erhalten; Lizenzdateien unter `assets/fonts/` und im Offline-Creditsmenü. Godot und Android-Buildwerkzeuge behalten ihre jeweiligen Lizenzen; Godot-Hinweise unter https://godotengine.org/license/ und in `docs/THIRD_PARTY.md`.
