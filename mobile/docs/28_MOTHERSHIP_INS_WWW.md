# 28 — GEMERKT: Mothership ins WWW (Johannes, 05.07., "das müssen wir machen")

*Grosse Richtungsidee. Hier festgehalten, damit sie ueberall praesent ist
und nicht verloren geht. Noch KEINE Umsetzung — bewusste Entscheidung
ausstehend (kippt die local-first-Doktrin).*

## Die Idee

Das **Mothership ins Netz holen** — eine Web-Version, erreichbar von ueberall
im Browser. Nicht nur die native Mac-App, sondern das Cockpit **im WWW**.

## Wuerde das gehen? — Ehrlich: JA, und leichter als die iOS-App.

Grund: Das Mothership ist im Kern ein **Cockpit ueber Cloud-Daten**, nicht
ein Geraet voller Sensoren. Es hat KEINE der Web-Bremsen der Satelliten
(kein AR, kein LiDAR, kein Laser, kein Pencil). Und der Clou:

- **Airtable ist ohnehin schon das System-of-Record.** Die Projekte, Kunden,
  Kalkulationen, Clockodo-Tabellen liegen bereits in der Cloud.
- Ein Web-Mothership waere also grossteils ein **neues Frontend ueber
  bereits vorhandene Cloud-Daten** (Airtable/Google/Clockodo/ClickUp-APIs),
  plus die Logik. Das ist gut machbar.

## Der elegante Bonus

Ein Web-Mothership loest nebenbei das **Kopplungs-/Shared-Credentials-
Problem** (docs/25/26): Sobald das Schiff im Netz erreichbar ist, KANN der
Satellit es fragen — der Traum "Keys bleiben am Hub, Geraete briefen sich
leicht" wird real, weil es endlich einen erreichbaren Hub gibt. Der Kosmos
(eine Firma, eine Mothership) lebt dann buchstaeblich an einer URL.

```
Heute:   Mac-Mothership (lokal)  --Zip/Drive/Airtable-->  Satelliten
Vision:  Web-Mothership (URL)    <---- live ---->         Satelliten + Browser
```

## Die ehrlichen Haken (bewusst entscheiden)

1. **Neuer Bau, kein Port.** Der macOS-Swift-Code laeuft nicht im Web. Ein
   Web-Mothership ist ein neues Projekt (Web-Stack: z. B. TypeScript +
   React/Svelte, ggf. schlankes Backend oder serverless). Die *Konzepte*
   und Vertraege (docs/23-27) bleiben, der Code ist neu.
2. **Kippt local-first.** Die eiserne "kein Sync-Backend in V1"-Regel war
   Absicht. Ein Web-Hub ist per Definition online. Das ist eine bewusste
   Strategie-Entscheidung, kein Nebenbei.
3. **Sicherheit waechst.** Ein erreichbarer Hub mit allen Keys braucht echte
   Auth (Login, Rollen — die kennt das Mothership ja schon), HTTPS, sauberes
   Secret-Handling serverseitig. Machbar, aber ernst zu nehmen.
4. **NO-GOs bleiben:** Clockodo nutzer-privat, Airtable nie loeschen,
   Sevdesk tabu — im Web genauso.

## Empfohlene erste Stufe (falls wir loslegen)

**Web-Mothership als reines Lese-/Cockpit-Frontend** ueber die vorhandenen
Cloud-Daten (Airtable read) — genau wie die Safari-Cockpit-Demo, nur voll:
Projekte, Kunden, Kalkulationen, Dashboards. Read-only zuerst, Schreiben
(mit Bestaetigung) als Stufe 2. So entsteht Wert ohne sofort die ganze
Backend-/Auth-Frage zu loesen.

## Status

GEMERKT. Gehoert in die Mothership-Welt (Mac-Session / eigenes Web-Repo).
Naechster Schritt waere ein Konzept-/Architektur-Dokument, wenn Johannes
gruenes Licht gibt.
