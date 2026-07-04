# 🌟 Produkt-Nordstern — „mykilOS 2027"

**Erstellt:** 2026-07-04 · **Status:** Vision/Leitplanke, KEIN aktiver Bau.
**Grundhaltung (Johannes, 2026-07-04):** Wir bauen mit diesem Gedanken im Hinterkopf weiter,
**ohne unsere jetzigen Umstände zu ändern**. Aber wir richten ab jetzt alles so aus, dass wir
später auch **mit fremden Bestandssystemen andocken und fliegen** könnten. Tiefe vor Breite.

> Dieses Dokument ist die Landkarte hinter den Kopfgedanken. Es beschreibt, *wohin* mykilOS
> perspektivisch fliegt — nicht was diese Woche gebaut wird. Verbindlich bleibt für den
> Tagesbetrieb weiter [HYPERBUILD.md](../HYPERBUILD.md) + [CLAUDE.md](../CLAUDE.md).

---

## 1 · Die Vision in einem Satz

Ein **vertikaler, voll-gehosteter Werkzeugkasten** für Interior-/Tischlerei-/Küchen-/
Einrichtungsstudios — durchgängiges Projektmanagement über drei Plattformen mit klaren Rollen,
als Abo, mit KI im Paket, EU-gehostet.

**Warum vertikal (nicht horizontal):** Jedes Studio tanzt denselben Tanz —
Lead → Aufmaß → Planung → Kalkulation → Angebot → Beschaffung → Fertigung → Montage → Abnahme →
Rechnung → Nachbetreuung. Wir adaptieren nicht an unendliches Chaos, wir bieten eine
**besser geformte Version eines Ablaufs, den sie schon kennen.** Die Nische *ist* der Burggraben.

---

## 2 · Drei Plattformen, drei Rollen (folgt der Wertschöpfung)

Der Split folgt **wo die Arbeit physisch passiert** — das ist die Produktgeschichte, nicht nur Technik.

| Wertschöpfung | Wo | Plattform | Stand heute |
|---|---|---|---|
| Lead / Erstkontakt / Fragebogen | Studio/unterwegs | iOS Satellit | 🟡 Intake/Fragebogen (Mac) |
| **Aufmaß** (Stift + Bluetooth-Laser ins Foto) | Baustelle | **iPad Worker** | 🔴 fehlt — das Herzstück |
| Planung / CAD | Studio | Mac Mothership | 🟡 Vectorworks geparkt |
| Kalkulation / Preisfindung | Studio | Mac Mothership | 🟢 KalkulationsEngine + Lern-Loop |
| Angebot | Studio | Mac | 🟢 sevDesk-Postbox-Weg (2026-07-04) |
| Beschaffung / Warenkorb | Studio | Mac | 🟢 WorkBasket/Wirbelsäule |
| Fertigung / Werkstatt-Status | Werkstatt | iPad/iOS | 🔴 fehlt |
| Montage / Logistik / Termine | Baustelle | iPad/iOS | 🟡 Kalender, kein Montage-Modul |
| **Abnahme** (Fotos, Mängel, Unterschrift) | Baustelle | **iPad Worker** | 🔴 fehlt |
| Rechnung / Nachbetreuung | Studio | Mac | 🟢 extern (sevDesk), bewusst |

- **Mac Mothership:** Planung, Geld, Koordination — heute stark.
- **iOS Satellit (myMini):** schnelles Erfassen, Status, Kommunikation unterwegs.
- **iPad Worker:** das On-Site-Handwerk (Aufmaß mit Stift+Laser, Abnahme mit Foto+Unterschrift).
  Die große weiße Fläche — und der **differenzierende Produktwert**, den kein generisches
  PM-Tool (Monday/Asana) je liefert, weil es die Branche nicht kennt. **Als eigenes
  Produkt-Herz behandeln, nicht als „Tab dazu"** (hardware-nah, fummelig, offline-kritisch).

---

## 3 · Geschäftsmodell — voll gehostet, Abo, KI im Paket

**Entschiedene Weiche (Johannes, 2026-07-04):** Wir hosten das System selbst. Kunden bekommen je
nach Abo einen Datenbereich (x GB / x Traffic) auf einem mykilOS-Server; **KI ist über uns im
Paket**. Tiers als hochstufbare Service-Pakete.

| | Basic | Start | Premium |
|---|---|---|---|
| Speicher / Traffic | klein | mittel | groß |
| Seats | 1–2 | Team | unbegrenzt+ |
| Plattformen | Mac | +iOS | +iPad Worker |
| KI-Budget/Monat | knapp | fair | großzügig, teure Modelle |
| Konnektoren | 1–2 | mehrere | alle + Prio-Support |

Tier-Grenzen = die **echten Kostenhebel** (Storage, KI-Token, Seats, Plattformen), damit jedes
Tier margensicher bleibt.

### Was wir damit werden (ehrlich)
Wir hören auf, „eine App-Firma" zu sein, und werden **Infrastruktur + Hosting + Compliance +
Support**. Das erbt:
- **DSGVO-Auftragsverarbeitung** (wir halten Kundendaten *über deren* Kunden). AV-Verträge,
  Löschkonzepte, Breach-Meldung. **EU-/Deutschland-Hosting = Verkaufsargument, kein Nachteil.**
- **Mandanten-Isolation** als harte Sicherheitsgrenze — das Eine, das nie falsch sein darf.
- **Betrieb 24/7** (Uptime/SLA/On-Call/Backups). Server hustet → Aufmaß lädt nicht → Churn.
- **Storage-Realität:** die Nische ist medienschwer (Baustellenfotos, PDF, CAD, Moodboards).

### Der eine Margen-Fallstrick: KI im Paket
LLM-Tokens sind die dominante variable Kosten. „KI im Abo drin" ⇒ **pro Mandant metern, pro Tier
deckeln** (Fair-Use, Token-Budget, Modell-Routing: billiges Modell default, teures nur auf Ansage).
Verstärkt die bestehende Eiserne Regel „ökonomisch/lean, Kosten = Design-Kriterium".

---

## 4 · Architektur-Konsequenzen (der Flip)

Heute: local-first, Keychain, persönliches OAuth, **Airtable als System-of-Record**.
Hosted-SaaS heißt: **server-seitige Identität + eigene zentrale DB (z.B. Postgres) als SoR**;
die drei Apps werden **Clients zu unserer einen API**. Das vereinfacht die Clients sogar
(eine API statt N externe Systeme pro User) und degradiert externe Konnektoren
(Drive/sevDesk/Clockodo) vom *Rückgrat* zu *optionalen Integrationen obendrauf*.

### Airtable ist kein Schicksal — hinter einer Naht halten
Ist-Kopplung (2026-07-04, gemessen): **mittel, nicht tief.**
- ✅ Hot-Path liest **lokalen GRDB-Cache** (`CachedProjectRegistry`), Airtable ist nur Sync-Quelle.
- ✅ Zugriff über Protokolle (`AirtableFetching`/`AirtableRecordCreating`/…).
- ⚠️ Schuld: `AirtableFieldValue` leckt in ~12 Dateien, hartkodierte Base-ID in ~11.

**Leitplanke ab jetzt (ohne heute etwas zu ersetzen):**
1. Neue Daten-Weichen möglichst hinter einer **anbieter-neutralen Naht** bauen
   (Ziel-Konzept `RegistryBackend`), nicht direkt gegen `AirtableFieldValue`.
2. **GRDB-Cache bleibt** die lokale Wahrheit.
3. Base-IDs/Ordner-IDs perspektivisch aus dem Code in **Mandanten-Konfiguration** (heute noch
   Konstanten — bewusst, kein Sofort-Umbau).
4. So wächst die Kopplungs-Schuld nicht weiter, und Airtable kann später **eine** Implementierung
   hinter der Naht sein (eure API die zweite). Kein „rausreißen", sondern „zweites Backend anhängen".

Airtable ist für die *jetzige* Phase brillant (Schema-on-the-fly, human-editierbar, null Ops) und
verdient seinen Platz **heute**. Es soll nur nicht *tragend für die Produkt-Zukunft* werden.

---

## 5 · Reihenfolge (De-Risk)

1. **Tiefe vor Breite:** erst am eigenen Studio den vollen vertikalen Ablauf durchfliegen lassen
   (v.a. die weißen Flächen **Aufmaß → Fertigung → Montage → Abnahme**), *dann* fremd-tauglich machen.
2. **Managed single-tenant zuerst:** jeder Kunde eine eigene isolierte Instanz/Container →
   „wir hosten alles" *heute erreichbar*, ohne die harte Multi-Tenant-Isolations-Ingenieurskunst
   (physisch getrennt = trivial isoliert). Erst bei Volumen auf echtes Multi-Tenant konsolidieren.
3. **Ein fremder Pilotkunde** mit möglichst *anderer* Struktur zwingt die App real multi-tenant zu
   werden — legt in Wochen offen, was Monate Planung verstecken.

---

## 6 · Was das für den Alltag heißt (die einzige Handlungsanweisung jetzt)

- **Nichts Bestehendes umbauen.** Weiter wie in HYPERBUILD.md.
- **Bei jeder neuen Naht** kurz fragen: „ließe sich hier später ein fremdes Bestandssystem
  andocken statt nur unseres?" — und die Naht entsprechend neutral ziehen.
- **Personenbezogene/kaufmännische Grenzen** (per-User-Isolation, Belegführung extern,
  sevDesk-BOSSMODE, Aufgaben nur Mensch→Mensch) sind schon jetzt genau die Disziplin, die ein
  Multi-Mandanten-Produkt braucht — beibehalten, nicht verwässern.

_Lebendes Dokument. Bei jeder Grundsatzentscheidung nachschärfen (Free-Climber-Prinzip: aktuell halten)._
