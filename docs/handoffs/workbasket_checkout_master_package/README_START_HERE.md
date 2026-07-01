# WorkBasket Checkout Master Package — START HERE

Datum: 2026-07-01
Branch: handoff/workbasket-checkout-architecture-2026-07-01
Status: docs-only, non destructive, safety first

## Zweck

Dieses Paket ist der Startpunkt für die vollständige Integration von DataObjects, dynamischem Warenkorb, Checkout-Orchestrator, Airtable-geführter Datenwahrheit, Bildkatalog, Moodboard Generator, Dokument-/Mailkatalog, CAD-Handoffs und Angebots-Templates in mykilOS 7.

Die Main App hat Masterstatus. Keine neue Funktion darf AppState, MainActor, bestehende UI/CI/UX, Review-first oder Audit-first umgehen.

## Grundfluss

DataPoint -> DataObject -> WorkBasketItem -> WorkBasket -> CheckoutRun -> Preview -> Review -> Output -> Audit -> Postflight.

Ein Datenpunkt ist nie direkt eine Aktion. Der Checkout entscheidet den Ausgang.

## Enthaltene Architekturthemen

1. DataObject Core fuer Kunden, Projekte, Angebote, Artikel, Geraete, Dienstleistungen, Bilder, Dokumente, Mailvorlagen, Zeichnungen, Geraetelisten, Layouts und Vorlagen.
2. Dynamic WorkBasket als neutraler Sammelkorb.
3. Checkout-Orchestrator fuer Schaetzung, Vergleich, Projektanlage, Projektwaren, CAD-Handoff, Angebots-Template, Moodboard, Firefly-Prompt, Dokumentpaket, Mailentwurf, Protokoll und Auftragsbestaetigung.
4. Airtable als Daten-, Status-, Zahlen-, Review- und Audit-Schicht.
5. Drive als Beleg-, Medien-, Ordner- und Vorlagenraum.
6. Bildkatalog aus alten Moodboards, Herstellerbildern, Projektbildern und Materialtexturen.
7. Moodboard Generator mit LayoutTemplates, TemplateSlots, MoodboardTemplates, DrawingHeads, DeviceLists, BrandProfiles und PromptProfiles.
8. Standarddokumente- und Standardmail-Katalog.
9. IntegrationHandshake, WritePolicyEngine, MassMutationDetector, OverrideGuard und Postflight Verification.

## Harte Architekturregel

Guards vor riskanten Features. Handshake vor Integration. Dry Run vor Write. Preview vor Approval. Audit vor Done. Live-Gate vor Fertig.

## Implementierungsphasen

S0 System Truth Map aktualisieren
S1 I/O Register finalisieren
S2 Safety Engine und Guards
S3 DataObject Core
S4 WorkBasket Core
S5 CheckoutRun local
S6 IntegrationHandshake Framework
S7 Airtable Staging
S8 Basket UI
S9 Checkout UI und Preview
S10 erste sichere Outputs
S11 Angebots-Template, CAD-Handoff, ProjectGoods
S12 ImageCatalog, Moodboard, FireflyPrompt
S13 LayoutTemplates, TemplateSlots, MoodboardGenerator
S14 Document/MailCatalog, Protocol, OrderConfirmation
S15 Gmail Draft Export
S16 Live-Gates und Handoff Freeze

## Sofort starten mit

1. HANDOFF_WORKBASKET_CHECKOUT_MASTER_ARCHITECTURE_2026-07-01.md lesen.
2. Dieses README lesen.
3. ROLLING_HANDOFF_AND_SESSION_PROTOCOL.md lesen.
4. IMPLEMENTATION_PROMPT_S0_S1.md ausfuehren.
5. IO_REGISTER_SEED.md in echte Repo-Dokumente ueberfuehren.

## Nicht tun

Nicht direkt UI bauen. Nicht externe Systeme beschreiben. Nicht neue Automatiken aktivieren. Nicht vorhandene Architektur umgehen. Nicht ohne I/O Register starten.
