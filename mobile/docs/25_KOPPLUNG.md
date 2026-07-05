# 25 — Kopplung: ein Pairing statt Einzel-Logins

**Stand:** 04.07.2026. Entscheidung Johannes: Kopplungs-Code (QR/AirDrop),
kein Backend, local-first.

Statt in der Satelliten-App jeden Zugang einzeln einzutippen (Airtable-PAT,
Claude-Key, Firefly...), erzeugt die **Mothership** einmal ein
**verschluesseltes Paket** + eine **PIN**. Der Satellit uebernimmt es per
AirDrop/QR und schreibt die Zugaenge in seinen eigenen Schluesselbund.

**Die Keys teilen sich Mac und iPhone NICHT automatisch** (zwei Geraete, zwei
Schluesselbunde). Das Pairing ist der eine bewusste Moment, wo sie
ruebergehen. Danach ist der Satellit eigenstaendig; die Mothership bleibt
Quelle der Wahrheit.

## Was der Satellit schon kann (gebaut)

Verbindungen -> **Satellit koppeln**:
1. AirDrop-Paket oeffnen ODER Paket-Text einfuegen.
2. 6-stellige PIN vom Mac eingeben.
3. Zugaenge landen im Keychain (Airtable, Claude/Copilot, Firefly).

## Was die Mothership erzeugen muss (Aufgabe Mac-Seite)

Ein JSON des **Umschlags**:

```json
{ "version": 1, "salt": "<base64>", "daten": "<base64>" }
```

- `salt`: 16 zufaellige Bytes, base64.
- `daten`: AES-GCM **combined box** (nonce + ciphertext + tag), base64,
  ueber dem JSON des **Inhalts** (unten).
- Schluessel: `HKDF<SHA256>(inputKeyMaterial: PIN-UTF8, salt: salt,
  info: "mykilOS-kopplung-v1", outputByteCount: 32)`.

### Inhalt (Klartext vor der Verschluesselung)

```json
{
  "version": 1,
  "firma": "MYKILOS",
  "benutzerName": "Johannes",
  "benutzerEmail": "johannes@mykilos.com",
  "rolle": "Inhaber",
  "airtablePAT": "pat...",
  "claudeKey": "sk-ant-...",
  "fireflyClientID": "...",
  "fireflyClientSecret": "..."
}
```

Nur `benutzerName` ist Pflicht; jeder Key ist optional (nur mitschicken, was
der Satellit haben soll). `firma` = der Kosmos (das Geraet bindet sich daran),
`rolle` = wie die Mothership den Nutzer fuehrt (steuert spaeter Rechte). Der
Satellit blockiert ein Paket mit anderer `firma` (Kosmos-Wechsel) und fragt
bei anderem `benutzerName` auf persoenlichen Geraeten nach (Details docs/26).

### Uebertragung

- **QR:** den Umschlag-JSON als QR-Code am Mac zeigen (passt: ein paar
  hundert Byte). Satellit scannt (oder Text einfuegen).
- **AirDrop:** den Umschlag-JSON als `.json`-Datei aufs iPhone schicken.
- PIN daneben anzeigen (NICHT im selben Kanal wie das Paket, wenn moeglich).

## Bewusst ausgeklammert

- **Google:** OAuth ist geraetegebunden - der Satellit meldet sich separat an
  (eigener Sign-in). Nicht im Paket.
- **Clockodo:** nutzer-privat (Doktrin) - nur die eigenen Credentials des
  angemeldeten Users, nie teamweit.

## Ehrliche Einordnung Sicherheit

Das Paket ist AES-GCM-verschluesselt und braucht die PIN. Die PIN ist kurz
(Komfort), der Uebertragungskanal (AirDrop/QR zwischen deinen eigenen
Geraeten) ist bereits vertrauenswuerdig - das ist ein bequemes Pairing, kein
Hochsicherheits-Tresor. Nach dem Pairing liegen die Keys als Kopie auch auf
dem iPhone (Keychain). Key gewechselt -> einmal neu koppeln.
