import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - AdminZoneSection (Admin-Ebene S3+S4 — UI-Trennung)
// Bündelt die Admin-only Funktionen (Ordnerschema, Einladungen) hinter appState.istAktuellAdmin.
// UI-Verstecken ist NICHT die Sicherheitsgrenze — jeder Store-Aufruf darunter (NomenklaturStore,
// AppState.einladungErstellen) prüft selbst per assertAdmin (Verstecken ist UX, nie Sicherheit;
// ADMIN_EBENE_BAUPLAN.md Härtung 3: „Store-Gate VOR/mit UI-Verstecken").
struct AdminZoneSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.istAktuellAdmin {
            VStack(alignment: .leading, spacing: MykSpace.s6) {
                header
                TeamMitgliedAnlegenSectionView()
                Divider().overlay(MykColor.line.color)
                OrdnerSchemaEditorView(
                    store: appState.nomenklatur,
                    identity: appState.currentIdentity,
                    tokenPresent: appState.currentAdminTokenPresent
                )
                Divider().overlay(MykColor.line.color)
                MykInviteSectionView()
                Divider().overlay(MykColor.line.color)
                ClickUpGoLiveSectionView()
            }
        } else if istAdminMailOhneGueltigenZugang {
            lockoutLeerzustand
        }
        // Sonst (normaler User): kein Admin-Bereich, kein Hinweis nötig — die Trennlinie ist
        // Struktur/Einladungen (Admin) vs. Projekte anlegen/arbeiten (jeder), s. CLAUDE.md.
    }

    /// Die eingebackene Admin-Mail ist erkannt, aber `istAktuellAdmin` ist trotzdem false —
    /// typisch nach einem Neustart, bevor der Google-Login wieder verbunden ist (Token-Kopplung,
    /// A.3). Zeigt eine erklärende Zeile statt den Bereich stillschweigend verschwinden zu lassen.
    private var istAdminMailOhneGueltigenZugang: Bool {
        AdminAllowlist.gebacken.enthaelt(appState.currentIdentity?.googleEmail)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Admin-Bereich").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
            Text("Ordner-Schema und Kollegen-Einladungen — nur für Admins sichtbar und schreibbar.")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lockoutLeerzustand: some View {
        Label("Admin braucht einmaligen Online-Login auf diesem Gerät.", systemImage: "lock.circle")
            .font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
    }
}
