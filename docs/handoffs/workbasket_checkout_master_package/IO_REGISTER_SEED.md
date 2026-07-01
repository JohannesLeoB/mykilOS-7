# I/O Register Seed — WorkBasket Checkout

Status: Seed fuer S1. Muss im echten `docs/IO_REGISTER.md` weitergefuehrt werden.

## Schema

```text
IO-ID
Modul
Aktion
Quelle
Ziel
Operation
Trigger
Rolle
Preview Pflicht
Review Pflicht
Audit Pflicht
Fehlerfall
Testfall
Live-Gate
```

## Seed

### IO-001 DataObject aus Katalog lesen

Quelle: Airtable oder lokaler Katalog.
Ziel: mykilOS UI.
Operation: read.
Safety: keine externe Veraenderung.
Test: Katalog oeffnet, DataObjects entstehen nur als Referenz.

### IO-002 DataObject in Warenkorb legen

Quelle: DataObject.
Ziel: WorkBasketItems.
Operation: create staging/local.
Trigger: Nutzer klickt `In Warenkorb` oder Drag and Drop.
Safety: kein externer Write ausser definierter Basket-Staging-Write.
Test: Cold-Start, Audit-Hook.

### IO-003 CheckoutRun anlegen

Quelle: WorkBasket.
Ziel: CheckoutRuns.
Operation: create.
Trigger: Checkout starten.
Safety: kein Checkout ohne Preview.
Test: CheckoutRunCreatedForEveryCheckout.

### IO-004 Schaetzung erzeugen

Quelle: BasketItems, Preisanker, Archivangebote, Geraete.
Ziel: EstimatePackage.
Operation: create.
Safety: Preisanker werden nicht automatisch promoted.
Test: EstimatePreview, ReviewWarnings, Audit.

### IO-005 Vergleichspaket erzeugen

Quelle: Angebote, Positionen, Zeichnungen, Base Units.
Ziel: ComparisonPackage.
Operation: create.
Safety: unsichere Positionen bleiben Review.
Test: Outlier/Review warnings.

### IO-006 Angebots-Template erzeugen

Quelle: Kunde, Projekt, Waren, Dienstleistungen, Schaetzpreise.
Ziel: SevdeskTemplates als Staging/Handoff.
Operation: create staging.
Safety: kein produktiver Sevdesk Write.
Test: Template entsteht, Zielsystem bleibt unveraendert.

### IO-007 Projektanlage vorbereiten

Quelle: Formular, Kunde, Adresse, Projektleiter.
Ziel: ProjectCreationRequests.
Operation: create staging.
Safety: Dublettenpruefung, Review bei Unklarheit.
Test: ProjectCreationRequest visible.

### IO-008 Waren in Projekt schreiben

Quelle: BasketItems.
Ziel: ProjectGoods.
Operation: create staging.
Safety: kein Artikelstamm-Overwrite, kein Angebots-Write.
Test: ProjectGoods only.

### IO-009 CAD-Handoff erzeugen

Quelle: Projekt, Zeichnung, Base Units, Geraete, Materialien.
Ziel: CADHandoffs.
Operation: create/export.
Safety: kein CAD Direktwrite.
Test: Preview und Exportpaket.

### IO-010 Bildasset indexieren

Quelle: Drive Bilder, Moodboards, Herstellerbilder, Projektbilder, Texturen.
Ziel: ImageAssets.
Operation: create reference.
Safety: keine Originaldatei veraendern.
Test: RightsStatus default, Drive unchanged.

### IO-011 Moodboard Generator ausfuehren

Quelle: WorkBasket, ImageAssets, MoodboardTemplate, LayoutTemplate.
Ziel: MoodboardGeneratorRun und MoodboardPackage.
Operation: create preview.
Safety: Rechtewarnungen, keine externe Bildgenerierung.
Test: Preview required, unresolved slots visible.

### IO-012 Firefly Prompt erzeugen

Quelle: MoodboardPackage, ImageAssets, Materialien, Projektkontext.
Ziel: FireflyPromptPackage.
Operation: create prompt package.
Safety: kein Generate-Aufruf.
Test: Prompt with sources and warnings.

### IO-013 Standarddokument anwenden

Quelle: StandardDocument, Projekt, Kunde, Warenkorb.
Ziel: DocumentPackage.
Operation: create preview/export after approval.
Safety: Variablen sichtbar, Review bei Luecken.
Test: TemplateVariableResolver.

### IO-014 Standardmail anwenden

Quelle: StandardMailTemplate, Projekt, Kunde, Adressaten, Attachments.
Ziel: MailDraftPackage.
Operation: create preview.
Safety: Empfaenger- und Attachment-Pruefung.
Test: no auto send.

### IO-015 Gmail Draft erzeugen

Quelle: MailDraftPackage.
Ziel: Gmail Draft.
Operation: create draft after approval.
Safety: Versand nicht Teil dieses Schritts.
Test: Draft exists, no sent mail.

### IO-016 Protokollpaket erzeugen

Quelle: Projekt, Teilnehmer, Notizen, Entscheidungen, Aufgaben, Bilder, Produkte.
Ziel: ProtocolPackage.
Operation: create.
Safety: Empfaengerpruefung bei Mailausgang.
Test: Protocol preview.

### IO-017 Auftragsbestaetigung erzeugen

Quelle: Kunde, Projekt, Angebot/Schaetzung, Waren, Leistungen.
Ziel: OrderConfirmationPackage.
Operation: create.
Safety: Preisstatus, Leistungsumfang, Empfaenger sichtbar.
Test: requires customer and project.

### IO-018 Mass Operation pruefen

Quelle: geplanter WriteIntent.
Ziel: WritePolicyEngine.
Operation: policy check.
Safety: Batch-Aktionen koennen Review oder Admin-Freigabe verlangen.
Test: MassMutationDetector.
