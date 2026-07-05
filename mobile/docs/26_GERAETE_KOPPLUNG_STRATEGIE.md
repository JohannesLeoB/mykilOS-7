# 26 — Geraete-Kopplung: Strategie iOS / iPadOS / macOS

**Stand:** 04.07.2026. Denk-Notiz fuer die To-do-Liste (Johannes' Frage:
Mothership traegt alle APIs, die mobilen Geraete sollen leicht "zu briefen"
sein). Noch KEINE Umsetzung ausser der bereits gebauten V1 (QR/AirDrop+PIN,
docs/25).

## Leitbild

- **Mothership (Mac) = Tresor.** Traegt alle Keys/Logins, ist Quelle der Wahrheit.
- **Mobile (iPhone/iPad) = agil, leicht zu briefen.** Kein muehsames
  Einzel-Login, idealerweise Null-Aufwand.
- **Identitaet:** Johannes' **Apple ID** ist auf Mac + iPhone + iPad
  dieselbe. Genau das ist der elegante Hebel (siehe Stufe 3).

## Das Spektrum (von manuell zu magisch)

### Stufe 1 — QR/AirDrop + PIN  ✅ GEBAUT (docs/25)
Mothership erzeugt ein verschluesseltes Paket, Mobile nimmt es per
AirDrop/QR + PIN. **Vorteile:** funktioniert sofort, kein iCloud, keine
spezielle Provisionierung, oekosystem-offen (koennte spaeter auch ein
Android-Geraet briefen). **Nachteil:** ein manueller Schritt pro Geraet,
und bei Key-Wechsel neu koppeln.
-> Bleibt als universelle V1 und Fallback.

### Stufe 2 — Bluetooth-Handshake  ⛔ NICHT empfohlen
Technisch moeglich (lokales BLE-Pairing), aber auf iOS fummelig
(Hintergrund-BLE, Kopplungs-UX) und **kein echter Vorteil gegenueber
AirDrop** - AirDrop IST bereits der elegante lokale Transfer. Custom-BLE
fuer Credential-Transfer waere mehr Risiko fuer nichts.

### Stufe 3 — iCloud-Keychain (shared group, synchronizable)  ⭐ ZIEL
Der Null-Aufwand-Weg, den Johannes' Apple-ID-Beobachtung ermoeglicht:
- Alle drei Apps (Mac/iOS/iPad) unter **demselben Apple Developer Team**,
  mit einer **gemeinsamen Keychain Access Group** + Eintraege als
  `kSecAttrSynchronizable = true`.
- Dann synchronisiert **iCloud Keychain** die Keys automatisch ueber alle
  Geraete derselben Apple ID - **ohne jede Kopplungs-UI.** Mothership legt
  den Key einmal ab, er erscheint auf iPhone + iPad.
- **Key-Rotation & Widerruf gratis:** Aenderung/Loeschung am Mac
  propagiert automatisch.
- **Grenzen:** nur Apple-Geraete (= genau Johannes' Set), braucht ein
  **bezahltes Apple Developer Program** + korrekte Entitlements
  (Keychain-Group, iCloud). Solange die Apps nur mit der kostenlosen
  7-Tage-ID signiert sind, geht das noch nicht.

### Stufe 3b — CloudKit Private DB  (Alternative zu 3)
Mothership legt einen verschluesselten Bundle-Datensatz in den privaten
CloudKit-Container des Users; Mobile zieht ihn. Auch Apple-ID-gebunden,
mehr expliziter Kontrolle ("Geraete-Status", Widerruf pro Geraet), etwas
mehr Code. Ebenfalls nur Apple.

## Empfehlung / Reihenfolge

1. **Jetzt:** Stufe 1 (gebaut) nutzen - sofort briefbar, kein Blocker.
2. **Sobald bezahltes Apple Developer Program + gemeinsames Team steht:**
   Stufe 3 (iCloud-Keychain synchronizable) als Standard - dann ist
   "briefen" = gar nichts tun, die Keys sind einfach da. Stufe 1 bleibt als
   Fallback / fuer Fremd-Geraete.
3. **Identitaet:** optional "Sign in with Apple" fuer eine explizite
   mykilOS-Anmeldung; technisch reicht die gemeinsame Apple ID schon.
4. **Bluetooth:** verwerfen.

## Eleganter UX-Rahmen (fuer beide Enden)

- **Ship (Mac) -> Einstellungen -> "Geraete":** Liste der gekoppelten
  Mobilgeraete. "Geraet hinzufuegen" zeigt QR + PIN (Stufe 1). Wenn iCloud
  aktiv: Umschalter "Automatisch ueber iCloud briefen" (Stufe 3).
- **Mobile -> Verbindungen -> "Satellit koppeln":** heute Stufe 1; bei
  aktivem iCloud-Weg entfaellt der Schritt (Keys schon da), Ansicht zeigt
  nur noch "Von der Mothership gebrieft, Stand X".

## Doktrin-Wachposten (gilt fuer jede Stufe)

- **Clockodo bleibt nutzer-privat** - nie teamweit briefen, nur die
  eigenen Credentials des angemeldeten Users.
- **Google** bleibt eigener Sign-in (OAuth geraetegebunden) - nicht ueber
  Keychain-Sync verteilen.
- Widerruf muss ein Geraet wirklich entwaffnen (Keychain-Eintrag entfernen /
  iCloud-Item loeschen).

## Geraete-Typen (Johannes, 04.07. - "MOMENT"): nicht jeder hat ein Firmengeraet

Wichtige Realitaet: manche User haben KEIN Firmen-iPhone/-iPad, oder ein
iPad ist fuer ALLE Nutzer da (Werkstatt-Geraet). Das bricht die Annahme
"ein Geraet = ein Nutzer" - und damit die iCloud-Auto-Sync-Eleganz (Stufe 3)
fuer geteilte Geraete.

Darum bekommt jedes Geraet einen **Modus** (`GeraeteModus` in `Sicherheit.swift`):

| Modus | Situation | Kopplung | Private Daten (Clockodo) |
|---|---|---|---|
| **persoenlich** | 1 Nutzer, eigenes Geraet | einmal koppeln, bleibt gebrieft; iCloud-Auto-Sync (Stufe 3) moeglich | duerfen bleiben |
| **geteilt** | Werkstatt-Geraet, viele Nutzer | **Login/Logout je Sitzung**: bei Ankunft per QR/PIN briefen, arbeiten, abmelden | werden beim Abmelden **geloescht** |
| **keins** | kein Firmengeraet | - | - |

Regeln fuers **geteilte** Geraet:
- **KEIN iCloud-Keychain-Auto-Sync** (wuerde einen Nutzer fest verdrahten) -
  hier ist Stufe 1 (QR/PIN) genau richtig, weil bewusst pro Sitzung.
- **Login = sich briefen**, **Logout = private Credentials wipen**
  (Clockodo zuerst; Team-Instrumente wie Airtable/Drive duerfen bleiben,
  sind ohnehin teamweit).
- Beim Wechsel von Nutzer A zu B: A meldet sich ab (wipe), B koppelt neu.
- `MothershipBindung.abmelden()` erledigt den Wipe.

Auf einem **persoenlichen** Geraet ist der Besitzer-Wechsel dagegen die
Ausnahme (siehe Bindung unten) und wird gewarnt.

## Bindung: ein Satellit gehoert genau EINER Mothership (Johannes, 04.07.)

- Meine Satelliten (Phone + Pad) sind **immer nur mit MEINER Mothership**
  gesynced. Ich beame nicht in Fraukes Account.
- Umsetzung: beim ersten Koppeln merkt sich der Satellit den **Besitzer**
  (benutzerName/email aus dem Paket) als Bindung. Ein spaeteres Paket mit
  einem ANDEREN Besitzer wird nicht still uebernommen - es braucht eine
  ausdrueckliche Bestaetigung "Wirklich zu <anderer Name> wechseln?"
  (Schutz gegen versehentliches Fremd-Briefing).
- Auch der Rueckkanal (docs/24) geht implizit nur an die eigene Mothership.
- Gebaut: `MothershipBindung` (siehe `Sicherheit.swift`), Check in der
  Kopplungs-Ansicht.

## Gestufte Bestaetigung: "Immer erlauben" bei mittlerer Sicherheit

Alles, was der Satellit RAUSSENDET, ist bestaetigungspflichtig
(Karte->Bestaetigung). ABER nicht jede Aktion braucht denselben Zeremoniell -
darum drei Stufen (`SicherheitsStufe` in `Sicherheit.swift`):

| Stufe | Bedeutung | "Immer erlauben"? | Beispiele |
|---|---|---|---|
| **hoch** | irreversibel / Geld / Vertrag / fremde Systeme / privat | NEIN, immer einzeln | Clockodo-Buchung, Mail an Kunden, Airtable-Write, Vertrag siegeln, Loeschen |
| **mittel** | reversibel, kleiner Radius | JA, pro Aktionstyp merkbar | Feld-Foto in Projekt-Drive, Feld-Bericht an Mothership, Scan hochladen |
| **niedrig** | rein lokal, kein Aussen-Effekt | kein Prompt | lokale Reads, Vorschau |

- `FreigabeStore` merkt die "immer erlauben"-Entscheidungen pro Aktionstyp
  (widerrufbar in den Einstellungen - "Alle Freigaben zuruecksetzen").
- **hoch** kann NIE auf "immer erlauben" gestellt werden - der Toggle wird
  dort gar nicht angeboten.

## Offene To-dos

- [ ] Bezahltes Apple Developer Program klaeren (Voraussetzung fuer Stufe 3
      UND fuer stabile Geraete-Installation ohne 7-Tage-Ablauf).
- [ ] Gemeinsames Team + Keychain Access Group fuer Mac/iOS/iPad festlegen.
- [ ] Ship-seitige "Geraete"-Einstellung (Mothership-Aufgabe).
- [ ] Entscheidung Stufe 3 vs. 3b (iCloud-Keychain vs. CloudKit).
