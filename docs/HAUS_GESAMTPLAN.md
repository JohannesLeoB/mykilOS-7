# 🏠 Das Haus mykilOS — Gesamtplan

**Der eine Rahmen, unter dem alles hängt.** Nicht die Feature-Detailliste (die steht in
[BAUPLAN_FEATURES_2026-07-05.md](BAUPLAN_FEATURES_2026-07-05.md)), sondern der **Grundriss-Fahrplan**:
in welcher Reihenfolge wir das Haus verstehen, zeichnen, in Code gießen und bewohnbar machen.

```
Stand:  2026-07-05
Branch: feat/kamera-barcode-widget
Vision: docs/haus (Memory haus-mykilos-grundriss-metapher) — mykilOS als EIN Haus
Regel:  nichts gepusht ohne Johannes' GO · nur über PR auf main · append-only
```

---

## Der Leitsatz

> **Erst verstehen. Dann zeichnen. Dann in Code gießen. Dann einziehen lassen.**
> Nie blind bauen — immer das Bild vor dem Bau. Schritt für Schritt, nie die ganze Strecke auf einmal.

Das Haus hat vier Dinge, die es zu einem Haus machen: **Türen** (wie Daten fließen),
**Mauern** (die Regeln, die Sicherung), **Kommoden** (wo die Daten liegen) und **Bewohner**
(wer mit welchem Ausweis und Schlüssel darin wohnt). Erst wenn alle vier vermessen sind,
zeichnen wir den Grundriss — und erst dann bauen wir echten Code.

---

## ① VERSTEHEN — das Haus vermessen  *(läuft gerade)*

Vier Pfeiler, jeder ein read-only Späher-Schwarm, der in Klartext kartiert:

| Pfeiler | Was er kartiert | Stand |
|---|---|---|
| **Kommoden** | Die Datenlandschaft — Bases als Kommoden, Tabellen als Schubladen, voll/leer/doppelt | ✅ live (Artifact) |
| **Türen** | Die Routing-Logik — jede Weiche „das ist das → deshalb dorthin → weil" | 🟡 Schwarm fliegt |
| **Mauern** | Die Statik — was ist sturmfest/versichert/offsite gesichert vs. reserviert-leer (Ferienhaus) | 🟡 Schwarm fliegt |
| **Bewohner** | Die Identität — Personalausweis, Meldeadresse, Schlüssel jedes Team-Mitglieds | ⬜ **als Nächstes** |

**Das „wann" für die Bewohner:** der **nächste** Schwarm — aber **sauber nach** den zwei
laufenden, nicht parallel draufgepackt. Erst landen die zwei, ich fange & verifiziere sie
als Torwächter, dann fliegt der Bewohner-Schwarm. Dann ist das Verständnis komplett.

---

## ② ZEICHNEN — der Grundriss  *(wenn ① komplett)*

Der begehbare Master-View: **Türen + Mauern + Kommoden + Bewohner in einem Bild.**
Stockwerke, Zimmer hinter benannten Türen, farbige Kommoden mit Owner + ins/outs, Mauern =
Regeln, Ferienhaus offsite (ehrlich gestempelt wo's nur reserviert ist).
→ Mein Render-/Torwächter-Job, kein Sub. Das ist das Bild, das wir beide sehen, **bevor**
gebaut wird.

---

## ③ FUNDAMENT GIESSEN — Konzept → Code  *(nach dem Bild, GO je Strang)*

Jetzt kippt es vom Verstehen ins echte Bauen. Reihenfolge nach Abhängigkeit:

1. **CHECK-IN-Spine** — das Herzstück. `CheckoutPort + ActionCard + AuditEntry` → **eine**
   `CheckIn`-Naht (propose → confirm → audit, append-only, idempotent, nie überschreiben).
   Design steht ([MASTER_ARCHITEKTUR_CHECKIN.md](MASTER_ARCHITEKTUR_CHECKIN.md)). **Alles hängt daran.**
2. **Bewohner-Schicht** — die fehlenden Layer aus ①:
   - **Personalausweis** = kanonischer Identitäts-Datensatz, der Google + Clockodo + ClickUp +
     Airtable + lokales Profil desselben Menschen zusammenhält (heute zersplittert — dieselbe
     Fragmentierung wie Kunde/Projekt, nur für Menschen).
   - **Meldeadresse** = Einzugs-/Onboarding-Weg (Profil anlegen, im Team-Register melden).
   - **Schlüssel-Inventar** = wer hält welche Credentials (privat vs. geteilt), Übersicht statt verstreut.

*Reihenfolge fest: Spine zuerst (Naht für alles), dann Bewohner (macht das Haus team-fähig).*

---

## ④ EINZUG — Team-Features  *(wenn Fundament steht + Gates offen)*

Erst wenn Bewohner einziehen können, ergeben die Features Sinn. Je nach Gate:

| Feature | Gate |
|---|---|
| Visitenkarte → Kontakt (Selbstheilung, nie löschen) | 🔒 Google-Consent |
| Barcode → Lager aus-/einbuchen, vercheckouten | 🔒 Schreibrechte + Abnabelung Daniel-Base |
| Muster-ID-Schema (Dymo/QR, physischer Check-in) | 🗓️ Montag live mit Johannes |
| Abnabelung Daniel-Base (eigener Spiegel, fortschreiben) | 🔒 Daniel am Tisch |

---

## Das „wann" auf einen Blick

1. **Jetzt** — die 2 Schwärme landen lassen. Nicht stören, nicht überholen.
2. **Direkt danach** — Bewohner-Schwarm (3. Pfeiler). Verständnis komplett.
3. **Dann** — Grundriss zeichnen (das Bild).
4. **Dann** — Code: Spine → Bewohner-Schicht → Features. Jeder Schritt mit eigenem GO.

Kein Schritt überspringt den davor. Der Grundriss darf nicht gezeichnet werden, bevor die
Bewohner vermessen sind; kein Code, bevor der Grundriss steht.

---

## Die Mauern, die für alles gelten (nicht verhandelbar)

- **Bewohner-Isolation:** Mail/Memos/Clockodo/Chat privat, nie teamweit kreuzlesbar. Keys nur im Keychain, pro Nutzer isoliert.
- **Kein Identitäts-Vortäuschen:** der Assistent handelt sichtbar im Auftrag, spricht nie als der Mensch selbst. Ghost-Persona-Grenze.
- **Aufgaben nur Mensch → Mensch:** KI weist nie zu.
- **Append-only überall:** nie löschen/überschreiben, nur Archiv-/Status-Flag. Kein DELETE.
- **Torwächter:** nichts auf `main`, nichts gepusht ohne ausdrückliches GO.

*Verwandt: Memory [[haus-mykilos-grundriss-metapher]], [[team-konten-topologie]],
[[per-user-datenisolation-mail-memos-assistent]], [[user-private-area]] · Docs
[IDENTITY_LOGIN_PLAN.md](IDENTITY_LOGIN_PLAN.md), [MYKILOS_6_TEAM_MODELL.md](MYKILOS_6_TEAM_MODELL.md).*
