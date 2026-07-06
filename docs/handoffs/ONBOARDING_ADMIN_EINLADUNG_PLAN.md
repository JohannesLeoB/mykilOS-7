# 🎫 Onboarding ohne Key-Eingabe — Admin-Einladung (Johannes 2026-07-06)

**Ziel:** Ein neuer, „unbeholfener" User soll **NIE** einen API-Key/Client-Secret eingeben, ändern
oder anpassen müssen. Onboarding = schmal, elegant, wasserdicht. Idee (Johannes): **Admin-Einladung
mit Passwortschutz zum einmaligen Setup.**

```
Prinzip: Schaltschrank — der Admin verteilt die geteilten Zugänge als eine steckbare „Einladung",
         der User steckt sie einmal ein. Keys landen im Keychain (OS-geschützt), nie im Chat/Klartext.
```

## Zwei Ebenen (zusammen = das ganze Onboarding)

### Ebene 1 — Google-App-Ausweis EINBACKEN (löst das dringendste Problem sofort)
Die Google **Client-ID + Client-Secret** sind team-weit identisch (der „Firmen-Ausweis" der App).
Für einen **Desktop-OAuth-Client ist das Einbacken in die App der von Google vorgesehene
Standard** — Googles eigene Doku sagt sinngemäß: *„der Client-Secret wird in diesem Kontext nicht
als geheim behandelt"*; **PKCE** schützt den eigentlichen Login-Flow. Für eine interne Studio-App
(kein App Store, kleiner Kreis) ist das sicher genug und **eliminiert die Google-Key-Eingabe komplett.**
→ Neuer User: App installieren → **„Mit Google anmelden"** → fertig. Kein Key, kein Formular.
- Bau: Client-ID/Secret als mitgeliefertes Bundle-Asset (nicht im Klartext-Repo — Build-Zeit-Inject
  wie der Versionsmarker) mit Keychain-Fallback (User-Eingabe bleibt als Notausgang möglich).

### Ebene 2 — Admin-Einladung (für alle geteilten/rotierbaren Zugänge, elegant)
Für Team-Keys (Airtable-PAT, ggf. weitere) — und als saubere Alternative zum Einbacken:

**Der Admin (in mykilOS):** „Kollegen einladen" → mykilOS packt die geteilten Zugangsdaten in eine
**passwortverschlüsselte Datei** `kollege.mykinvite` (AES, aus einem Einmal-Passwort abgeleiteter
Schlüssel). Optional: Ablaufdatum + Bindung an die Empfänger-Mail.

**Übergabe — Zwei-Kanal-Sicherheit:** die **Datei** per Mail, das **Passwort** über einen *getrennten*
Kanal (mündlich / Signal). Wer nur die Datei abfängt, hat nichts; wer nur das Passwort hört, auch nicht.

**Der neue User:** Datei in mykilOS ziehen (oder Doppelklick) → **einmal das Passwort eingeben** →
mykilOS entschlüsselt und legt die Keys automatisch in den **Keychain** (dieselben Slots, die heute
die Settings-Formulare befüllen). Danach nur noch der persönliche **Google-Login**. Ein Passwort,
eine Datei, fertig.

## Warum das wasserdicht + unbeholfen-tauglich ist
- **Kein Key wird je getippt** — der User sieht nie eine Client-ID oder einen `GOCSPX-`-Wert.
- **Keys nie im Klartext unterwegs** — verschlüsselte Datei + getrenntes Passwort; im Ziel nur im
  OS-Keychain.
- **Ein einziger Handgriff** — Datei rein, ein Passwort, Google-Login. Das war's.
- **Rückfall-sicher** — schlägt etwas fehl, bleibt die manuelle Eingabe als Notausgang (versteckt).

## Fundament (was schon da ist)
- `KeychainStore` + alle `KeychainXCredentialsStore` — die Ziel-Slots existieren.
- `GoogleAuthService.startAuthorization(clientID:clientSecret:)` — nimmt die Werte schon entgegen
  (heute aus dem Formular; künftig aus Bundle/Einladung).
- Per-User-Isolation + Device-Primary-Anker (Multi-User) — die Einladung respektiert geteilt vs. persönlich.

## Bau-Reihenfolge (klein)
1. **Ebene 1 zuerst** (schnell, größter Effekt): Google-Client-ID/Secret als Build-Inject + Keychain-
   Fallback → Google-Login ohne Eingabe. Damit ist Daniels heutige Hürde weg.
2. **Ebene 2**: `.mykinvite`-Format (verschlüsseln/entschlüsseln, Cold-Start-Test) + Admin-„Einladen"-
   Aktion + User-„Einladung öffnen"-Sheet. Erst Team-Airtable, dann weitere.

## Offen für Johannes
- Client-Secret einbacken ok? (für Desktop-Client Standard + PKCE-geschützt) — oder lieber nur über
  die verschlüsselte Einladung?
- Welche Keys gehören in die Einladung (nur Airtable-PAT? Claude-Team-Key?) vs. bleiben persönlich.
