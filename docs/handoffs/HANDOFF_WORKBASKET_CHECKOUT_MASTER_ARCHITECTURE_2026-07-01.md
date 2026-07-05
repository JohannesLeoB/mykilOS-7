# HANDOFF — WorkBasket & Dynamic Checkout Masterarchitektur

Datum: 2026-07-01
Branch: handoff/workbasket-checkout-architecture-2026-07-01
Typ: docs-only Architekturübergabe

Die mykilOS App bleibt Master. Neue Module ordnen sich AppState, MainActor, bestehender UI/CI/UX, Review-first, Audit-first und der bestehenden Datenarchitektur unter.

Kernmechanismus:

DataPoint → DataObject → WorkBasketItem → WorkBasket → CheckoutRun → Preview → Review → definierter Output → Audit.

Schwerpunkte:

1. DataObject Core für Kunden, Projekte, Angebote, Artikel, Geräte, Dienstleistungen, Bilder, Dokumente, Mails, Zeichnungen, Gerätelisten, Layouts und Vorlagen.
2. Dynamischer Warenkorb als neutraler Sammelkorb.
3. Checkout-Orchestrator für Schätzung, Vergleich, Projektanlage, Projektwaren, CAD-Handoff, Angebots-Template, Moodboard, Firefly-Prompt, Dokumentpaket, Mailentwurf, Protokoll und Auftragsbestätigung.
4. Airtable als Status-, Zahlen-, Staging-, Review- und Audit-Schicht.
5. Drive als Beleg-, Medien-, Ordner- und Vorlagenraum.
6. Bildkatalog aus alten Moodboards, Herstellerbildern, Projektbildern und Materialtexturen.
7. Moodboard Generator mit LayoutTemplates, TemplateSlots, MoodboardTemplates, DrawingHeads, DeviceLists, BrandProfiles und PromptProfiles.
8. Standarddokumente- und Standardmail-Katalog.
9. IntegrationHandshake mit Discover, Identify, Capability Manifest, Scope Check, Dry Run, Preview, Policy Check, Approval, Execute, Audit und Postflight Verification.

Implementierungsreihenfolge:

S0 System Truth Map
S1 I/O Register
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

Definition of Ready:
I/O-ID, DataObject-Typ, Checkout-Type, erlaubte Inputs, Output-Tabelle, gesperrte Operationen, Preview, Review-Regel, Audit-Regel, Tests und Live-Gate sind definiert.

Definition of Done:
Build, Tests, Safety-Negativtests, ggf. Cold-Start, Integration Contract, Preview, Audit, Handoff und Live-Gate sind bestanden.

Schlussregel:
mykilOS bereitet kontrolliert vor, prüft, dokumentiert und übergibt. Die Main App bleibt Chef.
