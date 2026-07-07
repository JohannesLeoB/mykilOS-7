import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - ClickUpGoLiveSectionView (ClickUp-Vollintegration S10, 2026-07-07)
// Admin-only: verwaltet die Go-Live-Whitelist (`ClickUpGoLiveWhitelistStore`) — die einzige
// Brücke von reinem Testspace-Schreiben zu echten Produktivlisten. Jede Freischaltung ist ein
// bewusster, einzeln benannter Admin-Akt (kein Bool-Toggle, kein "alles live"). Store-Gate
// sitzt im Store selbst (assertAdmin) — diese View ist nur die Oberfläche darüber.
struct ClickUpGoLiveSectionView: View {
    @Environment(AppState.self) private var appState

    @State private var neueListID = ""
    @State private var neueProjektnummer = ""
    @State private var fehler: String?

    private var identity: ResidentIdentity? { appState.currentIdentity }
    private var tokenPresent: Bool { appState.currentAdminTokenPresent }

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            header
            freischaltenZeile
            if let fehler {
                Text(fehler).font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
            }
            if appState.clickUpGoLive.freigegebeneListen.isEmpty {
                Text("Keine Liste freigeschaltet — alles Schreiben läuft nur im Testspace.")
                    .font(.mykSmall).foregroundStyle(MykColor.muted.color)
            } else {
                VStack(alignment: .leading, spacing: MykSpace.s2) {
                    ForEach(sortierteEintraege, id: \.listID) { eintrag in
                        freigabeZeile(eintrag)
                    }
                }
            }
        }
    }

    private var sortierteEintraege: [(listID: String, projektNummer: String)] {
        appState.clickUpGoLive.freigegebeneListen
            .map { (listID: $0.key, projektNummer: $0.value) }
            .sorted { $0.projektNummer < $1.projektNummer }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ClickUp Go-Live").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("Whitelist konkreter Listen — kein Schalter für \"alles live\". Jede Freischaltung "
                 + "gilt für genau EINE Liste und ist auditiert.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var freischaltenZeile: some View {
        HStack(spacing: MykSpace.s3) {
            TextField("ClickUp-Listen-ID", text: $neueListID)
                .textFieldStyle(.roundedBorder).font(.mykMono(10)).frame(width: 160)
            TextField("Projektnummer (z. B. 2026-015)", text: $neueProjektnummer)
                .textFieldStyle(.roundedBorder).font(.mykMono(10)).frame(width: 180)
            Button("Freischalten") { freischalten() }
                .buttonStyle(.plain).font(.mykSmall).foregroundStyle(MykColor.paper.color)
                .padding(.horizontal, MykSpace.s4).padding(.vertical, MykSpace.s2)
                .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.critical.color))
                .disabled(neueListID.trimmingCharacters(in: .whitespaces).isEmpty
                          || neueProjektnummer.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func freigabeZeile(_ eintrag: (listID: String, projektNummer: String)) -> some View {
        HStack(spacing: MykSpace.s3) {
            Text(eintrag.projektNummer).font(.mykMono(9.5)).foregroundStyle(MykColor.ink.color)
            Text(eintrag.listID).font(.mykMono(9)).foregroundStyle(MykColor.muted.color)
            Spacer()
            Button("Sperren") { sperren(listID: eintrag.listID) }
                .buttonStyle(.plain).font(.mykMono(9.5)).foregroundStyle(MykColor.critical.color)
        }
    }

    private func freischalten() {
        fehler = nil
        do {
            try appState.clickUpGoLive.freischalten(
                listID: neueListID.trimmingCharacters(in: .whitespaces),
                projektNummer: neueProjektnummer.trimmingCharacters(in: .whitespaces),
                ausgeloestVon: identity, tokenPresent: tokenPresent)
            neueListID = ""
            neueProjektnummer = ""
        } catch {
            fehler = error.localizedDescription
        }
    }

    private func sperren(listID: String) {
        fehler = nil
        do {
            try appState.clickUpGoLive.sperren(listID: listID, ausgeloestVon: identity, tokenPresent: tokenPresent)
        } catch {
            fehler = error.localizedDescription
        }
    }
}
