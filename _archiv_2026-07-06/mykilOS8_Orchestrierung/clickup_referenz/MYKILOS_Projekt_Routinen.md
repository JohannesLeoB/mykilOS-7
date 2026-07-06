# MYKILOS · Projekt-Routinen

*Aus den Slack-Channels (1.1.2025–18.6.2026) abgeleitete Standard-Abläufe und Routinen je Projekttyp. Phasen wurden über Stichwort-Signale in den Nachrichten erkannt; Dauern sind Mediane der Übergänge (nur Projekte, in denen beide Signale auftraten – daher Richtwerte). Stand 29.06.2026.*

## Der kanonische Ablauf (11 Phasen)

Abgeleitet aus den 30 Privatküchen-Vollprojekten, die praktisch jede Phase durchlaufen. Dauer = Median-Wartezeit bis zur jeweils nächsten Phase.

| # | Phase | Median bis nächste Phase | Belegt in Vollprojekten |
|---|---|---|---|
| 1 | Anfrage/Lead | ~46 T (n=16) | 83% |
| 2 | Termin/Aufmaß | ~4 T (n=8) | 87% |
| 3 | Planung/Entwurf | ~1 T (n=20) | 97% |
| 4 | Angebot/Kalkul. | ~27 T (n=28) | 100% |
| 5 | Auftrag/Freigabe ⚠️ | ~40 T (n=16) | 90% |
| 6 | Bestellung | ~20 T (n=13) | 87% |
| 7 | Produktion | ~20 T (n=14) | 67% |
| 8 | Lieferung | ~6 T (n=13) | 83% |
| 9 | Montage | ~44 T (n=21) | 97% |
| 10 | Abnahme/Übergabe | ~31 T (n=7) | 80% |
| 11 | Rechnung/Zahlung | — | 93% |
| 12 | Service/Reklam. | — | 57% |

Typische Gesamtlaufzeit eines Vollprojekts: **Median 251 Tage** (~8 Monate). Über alle aktiven Projekte: Median 132 T. Der größte *steuerbare* Engpass ist die Kundenentscheidung (Angebot → Auftrag, ~27 T).

---

## Routinen je Projekttyp

Verteilung der 169 dekodierten Channels: Privatküche – Vollprojekt (30), Privatküche – Standard/klein (9), Gewerbe/Großprojekt (15), Angebot/Pitch (70), Intern/Showroom/Entwicklung (4), Kleinauftrag/Restpunkt (41).

### Privatküche – Vollprojekt

*Privater Küchen-/Wohnraum-Auftrag mit Planung, Fertigung und Montage. Die Kernroutine des Studios.*

30 Channels, Median-Laufzeit 251 Tage (~8 Monate), Ø 203 Nachrichten. Durchläuft praktisch alle Phasen (Angebot 100%, Montage 97%, Rechnung 93%).

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Anfrage/Lead | Anfrage erfasst, Fragebogen verschickt | Lead/PM (dk·jo·jb·se) | Typeform-Fragebogen, Kontaktanlage | — |
| Termin/Aufmaß | Ortstermin & Aufmaß vereinbart und durchgeführt | Lead/PM | Aufmaß-Skizze + Fotos (Drive) | Vorlauf bis Aufmaß ~46 T – Leads bleiben liegen |
| Planung/Entwurf | Grundriss, CAD-Visualisierung, Moodboard | Planung/Lead | CAD-Datei, Renderings, Moodboard (Drive) | — |
| Angebot/Kalkul. | Kalkulation & Angebots-PDF an Kunde | Lead + Kalkulation | Angebots-PDF (→ Kalkulationslabor) | — |
| Auftrag/Freigabe | Kunde gibt frei / unterschreibt, AB raus | Lead/PM | Auftragsbestätigung, Anzahlungsrechnung | ENGPASS: Entscheidung ~27 T – Kunden-Unentschlossenheit |
| Bestellung | Material & Geräte bei Lieferanten bestellt | Lead/PM + Einkauf | Bestellungen (Weichsel78, Bartels, Geräte) | ~40 T bis Bestellung – Beschaffungsvorlauf |
| Produktion | Korpus/Fronten in Fertigung | Werkstatt/Lieferant | Produktionsstatus (Horatec/Weichsel) | Lieferanten-Verzug |
| Lieferung | Liefertermin koordiniert, Anlieferung | Lead/PM | Liefertermin, Versandinfo | — |
| Montage | Einbau durch Monteur | Montageteam | Montagetermin | — |
| Abnahme/Übergabe | Übergabe & Abnahmeprotokoll | Lead/PM + Kunde | Abnahmeprotokoll, Mängelliste | Restpunkte/Mängel: ~44 T bis Abnahme |
| Rechnung/Zahlung | Schlussrechnung & Zahlungseingang | Buchhaltung (Frauke/Accounting) | Schlussrechnung (Sevdesk) | ~31 T bis Zahlung; Mahnlauf bei Verzug |
| Service/Reklam. | Nachbetreuung, Reklamation falls nötig | Service (#service_reparatur) | Servicefall, Ersatzteil | 57% haben Nachbesserungen |

Beispiel-Channels: `p_hh_amoulong_jj`, `p_ma_pohl_dk`, `p_hh_fuerste_jo`, `p_hh_fuckner_huetter_se`, `p_b_zeisberg_jj`, `p_l_benjamin_jb`

---

### Angebot / Pitch (Vorvertrieb)

*Neue Anfrage in der Angebotsphase (a_-Channel). Ziel: Auftrag gewinnen – oder sauber als Absage schließen.*

70 Channels, Median 60 Tage. Konversion gering: nur ~10% erreichen die Auftragsphase. Der Funnel verlangt aktives Nachfassen und disziplinierte Absage-Doku.

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Anfrage/Lead | Anfrage erfasst, qualifiziert | Lead/PM | Fragebogen, Budget-Indikation | — |
| Termin/Aufmaß | Aufmaß nur bei ernsthaftem Interesse | Lead/PM | Aufmaß (Drive) | Nur 14% kommen bis hier – früh qualifizieren |
| Planung/Entwurf | Erstentwurf / Konzept | Planung/Lead | Entwurf, Moodboard | Aufwand vor Auftrag – Risiko unbezahlter Planung |
| Angebot/Kalkul. | Angebot erstellt & versandt | Lead + Kalkulation | Angebots-PDF | — |
| Nachfassen | Aktiv nachfassen (Anruf/Mail) nach 1–2 Wochen | Lead/PM | Wiedervorlage / Reminder | Ohne Nachfass-Routine versandet der Funnel |
| Auftrag/Freigabe ODER Absage | Auftrag → Wechsel auf Vollprojekt-Routine; sonst Absage dokumentieren | Lead/PM | AB oder Absage-Vermerk + Grund | Nur ~10% konvertieren – Absagegrund festhalten |

Beispiel-Channels: `a_hh_baron-voght-strasse_dk`, `a_hh_heinz_joh`, `a_hh_schmid_dkjlb`, `a_b_masuhr-jonas`, `a_hh_pahmeier_sen`, `a_hh_zitscher_jo`

---

### Gewerbe / Großprojekt (B2B)

*Gewerbliche Auftraggeber: Praxis/Klinik, Gastro, Bank, Office, Studio. Höhere Summen, mehr Beteiligte.*

15 Channels (u.a. Neurologie Vinahl, Loidl-Bank ~260 T€ Angebot, Eurogate, ViaPhysio, Roots Yoga). Median 126 T im Channel – ein großer Teil der Abstimmung läuft offline (Mail/Termine), daher in Slack lückenhaft.

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Anfrage/Lead | Anfrage über Empfehlung/Pitch | GF + Lead (jlb·dk) | Briefing, Anforderungen | — |
| Termin/Aufmaß | Ortstermin, oft mehrere Stakeholder | Lead/PM | Aufmaß, Bestandsplan | Mehrere Entscheider → längere Abstimmung |
| Planung/Entwurf | Entwurf + ggf. Varianten/Vergabe | Planung/Lead | CAD, Varianten | — |
| Angebot/Vertrag | Angebot, oft mit Vertrag/Rahmenbedingungen | GF + Kalkulation | Angebots-PDF, Vertrag, Zahlungsplan | Freigabe über Gremium/Geschäftsführung – langsam |
| Auftrag/Freigabe | Beauftragung, Anzahlung | GF + Lead | AB, Vertrag, Abschlagsplan | B2B-Zahlungsziele, Bürokratie |
| Beschaffung & Fertigung | Bestellung, Produktion, ggf. in Tranchen | Lead + Einkauf | Bestellungen, Produktionsplan | Verzug bei Sondermaßen/Stahl |
| Lieferung & Montage | Gestaffelte Lieferung/Montage nach Bauphase | Montageteam + Lead | Liefer-/Montageplan | Abhängig von Gewerken vor Ort (Bau) |
| Teilabnahmen/Abnahme | Abnahme je Bauabschnitt | Lead + Kunde | Teil-Abnahmeprotokolle | — |
| Rechnung/Zahlung | Abschlags- & Schlussrechnungen | Buchhaltung | Abschlags-/Schlussrechnung | Längere Zahlungsläufe |

Beispiel-Channels: `p_hh_neurologie_vinahl_jlb`, `a_b_loidl-bank_lb`, `p_speakerdesign_dk`, `p_ebs_stahl_entwicklung`, `p_b_langner_group_ff`, `p_hh_roots_yoga_dk`

---

### Service / Reklamation

*Reaktiver Vorgang nach Abschluss: Mangel, Beschädigung, Reparatur, Nacharbeit.*

Zentral in #service_reparatur (44 Problem-Signale – mit Abstand die meisten). Immer mit dem Ursprungsprojekt verknüpfen.

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Meldung | Kunde meldet Mangel/Defekt | Service/PM | Servicefall angelegt | — |
| Erfassung/Diagnose | Foto, Beschreibung, Ursache prüfen | Service/PM | Fotodoku, Diagnose | — |
| Verursacher klären | Eigenleistung vs. Lieferant/Hersteller | Service + Lead | Zuordnung, Gewährleistung | Hersteller-Abwicklung (z.B. Gessi, V-ZUG) |
| Ersatzteil/Nacharbeit | Teil bestellen / Nacharbeit beauftragen | Service + Einkauf | Bestellung Ersatzteil | Lieferzeit Ersatzteil |
| Termin & Behebung | Servicetermin, Behebung vor Ort | Monteur/Service | Servicetermin | Terminfindung mit Kunde |
| Abschluss | Bestätigung, ggf. Berechnung | Service + Buchhaltung | Abschlussvermerk, ggf. Rechnung | Kulanz vs. berechenbar |

---

### Kleinauftrag / Produkt & Gerät

*Reiner Produkt-/Geräteverkauf oder Kleinleistung ohne Planung & Küchenmontage.*

Verteilt über #verkauf, #a_anfragen_produkte und Restpunkt-Channels. Kurzer Durchlauf, kein Aufmaß/keine Planung.

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Anfrage | Produkt-/Geräteanfrage | Verkauf/PM | Anfrage | — |
| Angebot/Bestätigung | Preis/Verfügbarkeit, Bestätigung | Verkauf | Angebot/Bestätigung | — |
| Bestellung | Bestellung beim Hersteller | Einkauf | Bestellung (Quooker, Miele, Gaggenau …) | Lieferzeit Hersteller |
| Lieferung/Abholung | Lieferung oder Abholung | Verkauf/Versand | Versand/Etikett | — |
| Rechnung | Rechnung & Zahlung | Buchhaltung | Rechnung | — |

---

### Intern / Showroom / Entwicklung

*Interne Vorhaben ohne externen Kunden: Showroom-Ausbau, Serienküche, Produktentwicklung.*

4 Channels (Studioausbau, Insel-Showroom, Serienküche, Bauhaus Dessau). Interne Meilensteine statt Kundenfreigabe.

| Schritt | Signal / Auslöser | Verantwortlich | Artefakt | Typischer Engpass |
|---|---|---|---|---|
| Konzept | Idee, Zielbild, Briefing | GF/Team | Konzeptnotiz | — |
| Planung | Entwurf, Material, Budget intern | Team | Entwurf, Budget | — |
| Umsetzung | Bau/Fertigung | Team/Werkstatt | Umsetzungsstatus | Konkurriert mit Kundenprojekten um Kapazität |
| Fertigstellung | Abschluss, Dokumentation | Team | Foto, Doku | — |

Beispiel-Channels: `p_hh_studioausbau_dk`, `p_hh_insel_showroom`, `p_mykilos_serienküche_joh`, `p_b_bauhaus_dessau`

---

## Querschnitt: die wiederkehrenden Engpässe

| Engpass | Beobachtung & Gegenmittel |
|---|---|
| Kundenentscheidung (Freigabe) | Median ~27 T zwischen Angebot und Auftrag; größter steuerbarer Hebel. Gegenmittel: feste Nachfass-Routine + Angebots-Verfallsdatum. |
| Lieferanten-Verzug | ~40 T bis Bestellung + je ~20 T Produktion/Lieferung. Häufige Stichworte: Verzug, Verspätung. Gegenmittel: frühe Bestellung, Pufferzeiten, Status-Tracking je Lieferant. |
| Scope Creep / Nachträge | Nachträge tauchen wiederholt auf (z.B. Fuckner/Hütter mit Nachträgen im Auftrag). Gegenmittel: Änderungen sofort als Nachtrag erfassen und bepreisen. |
| Mängel-/Restpunkt-Auslauf | Median ~44 T von Montage bis Abnahme; Nachbesserungen in 57% der Vollprojekte. Gegenmittel: Abnahmeprotokoll mit Mängelliste + Termin direkt bei Montage. |
| Anfrage-Vorlauf | ~46 T von Anfrage bis Aufmaß – Leads kühlen aus. Gegenmittel: Aufmaß-Termin früh fest verankern. |

---

## Für mykilOS

Die maschinenlesbare Fassung liegt in `mykilos_project_routines.json`: das 11-Phasen-Modell mit Erkennungs-Signalen, die gemessenen Übergangsdauern, die Routinen je Typ als Schritt-Arrays, und pro bestehendem Projekt die erkannte Phasen-Timeline (Channel → erste Datierung je Phase). Damit lassen sich (a) Workflow-Vorlagen je Projekttyp seeden und (b) laufende Projekte automatisch auf ihrer aktuellen Phase verorten. Hinweis: Signal-basiert und damit näherungsweise – vor produktiver Nutzung an einigen Projekten gegenchecken.
