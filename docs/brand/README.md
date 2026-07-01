# Marken-Assets für generierte Firmendokumente

Ablage-Zone + Spezifikation für Briefpapier, Logo, Schrift und Layout-Vorlagen.
Damit erzeugt `MykPDFRenderer` (Sources/MykilosApp/Export/) künftig gebrandete
Dokumente statt der aktuellen programmatisch gezeichneten Rohversion.

Betrifft: **Küchenfragebogen-PDF** (existiert schon) und **Abnahmeprotokoll**
(Block F, geplant) — beide teilen denselben Renderer, also einmal branden = überall schön.

---

## Was du mir gibst (Prioritätenliste)

### 1. Briefpapier / Letterhead  ⭐ wichtigstes Teil
**Am liebsten als A4-PDF (vektor)**, sonst hochauflösendes PNG (A4 @ 300 dpi ≈ 2480×3508 px).
Enthält den **konstanten** Rahmen jedes Dokuments:
- **Kopf:** Logo + Firmenname/Claim
- **Fuß:** Pflichtangaben (Anschrift, Kontakt, USt-ID, Handelsregister, Geschäftsführung, Bank)
- Definierte **Ränder / Schutzzone**, in die der dynamische Inhalt fließt (oben unter dem Kopf, unten über dem Fuß).

→ Ich lege es als Hintergrund-Ebene an, der variable Inhalt (Kundendaten, Positionen,
Unterschriftsfeld) wird darüber in die Schutzzone gerendert. So bekommst du designer-saubere
Ergebnisse, ohne dass ich den Kopf/Fuß nachbaue.

### 2. Logo
**SVG (vektor, ideal)** oder transparentes PNG in hoher Auflösung. Auch wenn es im
Briefpapier steckt — separat brauche ich es für Icon-Größen/Varianten.

### 3. Marken-Schrift
Die echten **Font-Dateien** (ihr nutzt „ABC Monument Grotesk"). Der Renderer nimmt aktuell
System-Schrift. Für echte Marken-Typografie muss die Schrift ins App-Bundle — **nur wenn die
Lizenz das Einbetten erlaubt** (bitte kurz bestätigen).

### 4. Layout-Vorlagen / Beispiele
1–2 **bestehende, schöne Firmendokumente als PDF** (ein echtes Angebot, ein Brief, eine
Rechnung). Daran lese ich Hierarchie, Abstände, wo was steht — damit die generierten
Dokumente sich anfühlen wie von euch, nicht wie von einer Software.

### 5. Pflicht-Fußtext (exakt)
Der genaue Text der Geschäftsdokument-Pflichtangaben (Firmierung, Anschrift, USt-ID,
Handelsregister-Nr, Geschäftsführer, Bankverbindung, Kontakt). Rechtlich vorgeschrieben —
gib ihn mir wörtlich, ich rate nichts.

### 6. Farben
Habe ich schon (MYKILOS-Palette: Brand-Orange `#EA5B25`, Terrakotta `#C26B4A` …). Falls die
Dokumente andere/zusätzliche Farben nutzen: nenn sie als Hex.

---

## Wie du mir die Dateien gibst — drei Wege

1. **Direkt hier in diesen Ordner legen** (`docs/brand/`) — einfachster Weg, ich finde sie sofort.
2. **Im Chat anhängen** — ich kann PDFs und Bilder direkt ansehen. Gut für den schnellen Start.
3. **In einen Drive-Ordner** legen und mir sagen welchen — ich lese ihn über den Drive-Zugang.

Runtime-relevante Assets (Briefpapier, Logo, Schrift) wandern beim Einbauen nach
`Sources/MykilosApp/Resources/Brand/` (ins App-Bundle). Referenz-/Quellmaterial
(Beispiel-Dokumente, Design-Dateien) bleibt hier in `docs/brand/`.

---

## Was ich dann baue

- `MykPDFRenderer` um eine **Briefpapier-Ebene** + Logo + Marken-Schrift erweitern; der
  variable Inhalt rendert in die Schutzzone. Mehrseitigkeit, falls Dokumente länger werden.
- Küchenfragebogen-PDF ist damit automatisch gebrandet.
- Für das **Abnahmeprotokoll** kommt zusätzlich: Unterschriftsfelder (Kunde/Monteur),
  Mängelliste, Datum/Ort — sobald die Feldstruktur steht (Block F).

---

## Gefundene Assets + abgeleiteter Marken-Spec (2026-07-02)

Quelle: Drive → `MYKILOS Team/mykilOS/Briefpapier/`. Von Johannes freigegeben, gesichtet.

**Logo:** `MYKILOS Logokoffer/` — als **SVG** (ideal), plus PNG/JPG/EPS/AI, je in
**Web(RGB)/Print(CMYK) × White/Black**. Für die App: `Web/Black/…_RGB_Black.svg` +
`Web/White/…_RGB_White.svg`.

**Schrift:** **ABC Monument Grotesk** (kompletter Satz Regular/Medium/Bold/Italic/**Mono**/
Semi-Mono) — liegt fertig als **woff/woff2/ttf/eot** MIT `stylesheet.css` (`@font-face`) +
`demo.html`. → direkt einsetzbar in der HTML/CSS→PDF-Engine, kein Font-Basteln nötig.
⚠️ **Lizenz-Check offen:** Einbetten ins App-Bundle nur, wenn die Monument-Grotesk-Lizenz
das erlaubt — bitte kurz bestätigen (Web-Font-Lizenz ≠ App-Embedding-Lizenz).

**Stil:** minimal, typografisch, viel Weißraum. Wortmarke in Monument Grotesk **Mono**,
Akzent **Brand-Orange `#EA5B25`** auf Papier-Weiß. Claim: „Defining new classics".

**Pflicht-Fußtext (wörtlich, aus der Firmensignatur):**
```
MYKILOS GmbH · Defining new classics
Shanghaiallee 3a · 20457 Hamburg
+49 (0) 40 20 90 50 06 · www.mykilos.com
VAT ID: DE296130120
Registergericht: Amtsgericht Charlottenburg, HRB 160307
Geschäftsführer: Dr. Daniel Klapsing
```

**Referenz-Dokumente vorhanden:** Visitenkarten (PDF), Moodboard (InDesign .indd/.idml +
PDF), Entwurfspräsentation (PDF). → Design-Quelle ist **Adobe InDesign**; ich übersetze den
visuellen Stil in HTML/CSS-Vorlagen (die InDesign-Dateien selbst sind nicht app-automatisierbar).

**Ablage-Status:** ✅ Assets lokalisiert (Drive). Nächster Schritt beim Bauen: die nötige
Teilmenge (Logo-SVG, Font-woff2 + stylesheet.css, Fußtext) nach
`Sources/MykilosApp/Resources/Brand/` kopieren — **nach** Font-Lizenz-OK.
