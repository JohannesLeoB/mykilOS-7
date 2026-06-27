# HANDOFF — Konversationeller Assistent · Release 6.1.0 & Vision

> Geschrieben am Ende einer außergewöhnlich produktiven Session. Branch
> `feat/conversational-assistant`, 18 Commits vor `main`, **155 Tests grün**,
> Build sauber, Version **6.1.0** markiert. Push erfolgt.

---

## 1. Reality-Check — was *wirklich* steht (ehrlich, ungeschönt)

### ✅ Gebaut, getestet, **live verifiziert**
- **Phase 0 — Persistenz-Fundament.** `ChatMessage`-Domäne (MykilosKit, rein),
  `ChatStore` (GRDB, `@MainActor @Observable`, throws + sichtbarer SaveState),
  Migration `v2_chat`. Cold-Start/Scope-Isolation/Streaming-/Fehler-Turn-Verträge bewiesen.
- **Phase 1 — Multi-Turn-Chat (MVP).** `ClaudeChatClient` (tool-aware `respond()`),
  `AssistantGrounding` (Datum löst „Montag" auf, Fokusprojekt, Signale, Anti-Halluzination),
  `ConversationEngine`, Chat-UI (`AssistantChatView`) mit allen Zuständen + Markdown-Rendering.
  **Live mit echtem Claude (Sonnet) verifiziert:** der Assistent listete korrekt alle 6
  Projekte, kannte das Datum, und lehnte ehrlich ab, was er (noch) nicht weiß. Genau wie entworfen.

### ✅ Gebaut + unit-getestet, **aber noch NICHT live verifiziert**
- **Phase 2 — Tool-Use (read-only).** Agentische Schleife (`tool_use` → Tool → `tool_result`
  → erneut, max. 6 Runden). `SearchGmailTool` + `ListCalendarTool`, `AssistantToolRegistry`
  (Whitelist, default-deny). **Sevdesk strukturell ausgeschlossen + Negativtest.**
  Gmail-„Wo abgelegt?" über Label→Ablageort (Phase 2c). Datenschutz-Opt-in (Default AUS,
  persistent) als Gate vor dem ersten Live-Zugriff.
  → **Warum nicht live:** die **App-eigene Google-OAuth-Sitzung ist nicht verbunden**
  (Settings: „NICHT VERBUNDEN"). Bis ein Testuser Google in der App verbindet, liefern die
  Tools `notConnected` (sauber als lesbarer Hinweis, kein Crash). Die MCP-Gmail/Kalender-Tools
  dieser Claude-Sitzung sind **nicht** die der App.

### ⛔ Bewusst NICHT gebaut (kein Versehen)
- **Phase 4 — echter Kalender-Write.** Braucht neuen Scope `calendar.events` (Re-Consent aller
  Google-Nutzer) + **ausdrückliche schriftliche Erlaubnis** (NO-GO-Regel). Korrekt aufgeschoben.

### 🕳 Lücken / übersprungen (für die nächste Session)
1. **Tool-Transparenz im UI fehlt.** Die Engine persistiert nur den finalen Antworttext —
   der Nutzer *sieht nicht*, dass Gmail/Kalender durchsucht wurde. Der Plan wollte
   „Quelle ist immer sichtbar" via `ToolCallRow`. **Offen.**
2. **Streaming (SSE) fehlt.** MVP ist non-streaming („denkt nach …" → ganze Antwort).
   `respond()`/Engine sind dafür vorbereitet, der SSE-Decoder fehlt. (Plan: Phase 1e)
3. **Tool-Umfang.** Nur Gmail + Kalender. Contacts/Drive/ClickUp-Tools sind im Plan, nicht gebaut.
4. **Phase 3 — Multimodal + Entwurf-Action-Card.** Domäne (`.image`/`.document`) existiert,
   aber kein Datei-Upload, keine Wire-Kodierung, keine `ChatActionCard` für Frage 3.
5. **User-Onboarding / Profil.** Es gibt keine geführte Login-/Profilseite — nur verstreute
   Settings-Schalter pro Integration. (Siehe §3, die direkte Antwort des Users.)

---

## 2. Die Vision (fest) — wofür das hier gebaut wird

Ein Studio-Cockpit, in dem **eine einzige Konversation** das ganze Werkzeug ersetzt.
Der/die Designer:in fragt in natürlicher Sprache — *„Wo habe ich die Mail an Gesa abgelegt?"*,
*„Was steht im Montagsmeeting an?"*, *„Mach Jilliana einen Termin"* — und der Assistent
liest (read-only) über Gmail, Kalender, Drive, ClickUp, fasst zusammen mit **sichtbarer Quelle**,
und schlägt Schreibaktionen als **bestätigungspflichtige Karte** vor. Nie autonom. Nie laut.
Farbe ist Sprache, Quelle immer sichtbar, externe Daten heilig.

Der innere Film: die Assistent-Seite öffnet sich, Chat füllt den Raum, Composer unten verankert.
Eine Frage getippt — eine Zeile „durchsucht Gmail …" erscheint mit Terrakotta-Quellpunkt,
dann die Antwort mit dem **Ablageort** der Mail. Bei *„Termin mit Jilliana"* faltet sich eine
Entwurfskarte auf — Titel, Zeit, Teilnehmer, Meet-Link — Knopf **Bestätigen → buchen** /
**Bearbeiten** / **Verwerfen**. Erst der Klick schreibt, und der Audit-Eintrag fällt leise dazu.

Das haben wir heute **bewiesen, dass es geht**: der Live-Chat erdete sich an echten Projektdaten
und blieb ehrlich. Der Rest ist, dieselbe Disziplin auf die Tool- und Write-Pfade zu legen.

---

## 3. Direkte Antwort: „Wann laufen Testuser-Login + volle Google/Claude/Assistent?"

**Ehrlich: du bist *eine verbundene Google-Sitzung* davon entfernt — plus eine Onboarding-Seite.**
- Claude + Assistent **laufen heute** (Key im Keychain, live verifiziert).
- Google: der **OAuth/PKCE-Flow steht** (Akt 3, S1) und die Tools sind gebaut + getestet.
  Sobald ein Testuser in *Einstellungen → Google* verbindet, gehen Gmail/Kalender im Assistenten
  live (nach Opt-in). **Noch nie live durchgespielt** — der erste echte Connect ist der Test
  (offener Punkt: ob Googles „Desktop App"-Client ein `client_secret` verlangt → dann in
  `GoogleOAuthPKCEService` nachziehen).
- Was für „reibungslosen Testuser-Login" **fehlt**: eine **geführte Onboarding-/Profilseite**
  statt verstreuter Schalter — ein Schritt-für-Schritt „Verbinde Google → Claude → fertig",
  und ein sichtbares Profil (Name, Identität, verbundene Konten). Das ist der empfohlene
  **erste große Block der nächsten Session.**

---

## 4. Nächste Session — fester Plan (Reihenfolge nach Wert)

1. **Onboarding & Profil** (beantwortet die Testuser-Frage direkt): geführter Connect-Flow
   (Google → Claude), Profilkarte, „Alles verbunden?"-Statusanzeige. Erst hierdurch wird die App
   für einen frischen Testuser ohne Anleitung benutzbar.
2. **Google live verifizieren** (Screen, kurz): echten Google-Connect durchspielen → Gmail-/
   Kalender-Tools im Assistenten live testen (Frage 2 „wo abgelegt?" wörtlich beantworten).
   Den `client_secret`-Punkt klären.
3. **Tool-Transparenz `ToolCallRow`**: sichtbar machen, welches Tool mit welcher Quelle lief.
4. **Streaming (Phase 1e)**: SSE-Decoder + `streamChat`, damit Antworten live tropfen.
5. **Phase 3**: Datei-Upload (Bild/PDF) + Entwurf-Action-Card für Frage 3 (Termin-Entwurf +
   Render-Link, **kein** echter Write).
6. Optional/auf Wunsch: weitere read-only Tools (Drive/Contacts/ClickUp).

**Offene Entscheidungen für den User** (aus dem Plan, weiter gültig): Kalender-WRITE ja/nein
(Phase 4, braucht schriftliche Erlaubnis); Verlaufs-Persistenz roher Drittinhalte vs.
Kurzfassung; Modell-Umschalter (Sonnet/Opus) im UI; Tool-Umfang V1.

---

## 5. Harte Limits (nicht verhandelbar, immer)
- **Sevdesk** nie lesen/schreiben (strukturell aus der Tool-Whitelist; Negativtest schützt das).
- **Airtable**-Base & **Drive**-Ordner `0AOeReQBQKkKBUk9PVA` **read-only** — kein write/edit/delete/move.
- Secrets nur Keychain. Externe Daten heilig; bei Datenverlust-Gefahr **warnen**.
- Schreibaktionen nur via Action-Card → Bestätigung → Audit. Nie autonom.

---

## 6. START-PROMPT für die nächste Session (copy-paste)

```
Wir arbeiten an mykilOS 6, Branch feat/conversational-assistant (18+ Commits vor main,
155 Tests grün, Build sauber, Version 6.1.0). Lies docs/handoffs/HANDOFF_POST_AKT5_13_
ASSISTANT_RELEASE.md — da steht der ehrliche Stand.

Der konversationelle Assistent (Chat + Tool-Use read-only + Opt-in) ist gebaut und
unit-getestet; Phase 1 ist live mit echtem Claude verifiziert. Phase 2 (Gmail/Kalender-
Tools) ist gebaut, aber NICHT live, weil die App-eigene Google-OAuth-Sitzung nicht
verbunden ist.

Ziel dieser Session (in dieser Reihenfolge):
1. Onboarding & Profil: geführter Connect-Flow (Google → Claude) + Profil-/Statusseite,
   damit ein frischer Testuser ohne Anleitung volle Google-Workspace- + Claude- +
   Assistent-Funktionalität bekommt.
2. Google live verifizieren (kurz Screen): echten Connect durchspielen, Gmail-/Kalender-
   Tools im Assistenten testen ("Wo ist die Mail an Gesa?"), client_secret-Frage klären.
3. ToolCallRow (Tool-Transparenz im Chat), dann Streaming (SSE), dann Phase 3
   (Datei-Upload + Termin-Entwurf-Action-Card OHNE echten Write).

Harte Limits: Sevdesk nie, Airtable/Drive read-only, Secrets nur Keychain, externe
Daten heilig, Writes nur via Action-Card→Bestätigung→Audit. Arbeite autonom in
kleinen build+test-Schritten bis ich STOP sage; committe lokal, Push erst auf Ansage.
```

---

*Letzter Stand: alles committet + gepusht, App auf 6.1.0 markiert, übergabefertig.*
