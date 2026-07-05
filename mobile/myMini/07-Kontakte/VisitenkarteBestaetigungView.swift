import SwiftUI

/// Karte→Bestätigung fürs Visitenkarten-Fangen. OCR liefert nur Vorschläge —
/// jedes Feld bleibt editierbar, nichts wird automatisch übernommen, nichts
/// automatisch gespeichert.
struct VisitenkarteBestaetigungView: View {
    let bild: UIImage
    let onFertig: () -> Void

    @State private var vorname = ""
    @State private var nachname = ""
    @State private var firma = ""
    @State private var telefon = ""
    @State private var email = ""
    @State private var laedt = true
    @State private var fehler: String?
    @State private var gespeichert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: bild)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Section {
                    TextField("Vorname", text: $vorname)
                    TextField("Nachname", text: $nachname)
                    TextField("Firma", text: $firma)
                    TextField("Telefon", text: $telefon).keyboardType(.phonePad)
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Erkannt — bitte kurz prüfen")
                } footer: {
                    Text("Texterkennung ist ein Vorschlag, kein Fakt — bitte gegenlesen, bevor du anlegst.")
                }
                if let fehler {
                    Text(fehler).foregroundStyle(MykColor.crit)
                }
                if gespeichert {
                    Label("Als Kontakt angelegt", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(MykColor.ok)
                }
            }
            .navigationTitle("Visitenkarte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Verwerfen", role: .destructive) { onFertig() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Als Kontakt anlegen") { anlegen() }
                        .disabled((vorname.isEmpty && nachname.isEmpty) || gespeichert)
                }
            }
            .overlay {
                if laedt {
                    ProgressView("Text wird erkannt…")
                        .padding(16)
                        .background(MykColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .task {
            let erkennung = await VisitenkartenOCR.erkenne(in: bild)
            vorname = erkennung.vorname
            nachname = erkennung.nachname
            firma = erkennung.firma
            telefon = erkennung.telefon
            email = erkennung.email
            laedt = false
        }
    }

    private func anlegen() {
        Task {
            fehler = nil
            guard await KontaktSchreiber.berechtigungAnfragen() else {
                fehler = KontaktFehler.keineBerechtigung.errorDescription
                return
            }
            do {
                try KontaktSchreiber.anlegen(
                    vorname: vorname, nachname: nachname, firma: firma, telefon: telefon, email: email
                )
                gespeichert = true
                try? await Task.sleep(for: .seconds(1))
                onFertig()
            } catch {
                fehler = Fehlertext.deutsch(error)
            }
        }
    }
}

#Preview {
    VisitenkarteBestaetigungView(bild: UIImage(systemName: "person.crop.rectangle") ?? UIImage(), onFertig: {})
}
