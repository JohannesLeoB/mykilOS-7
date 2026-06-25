import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - SignalDemoView
// Sichtbare Demo der Widget-Kommunikation in der Detailseite.
// "Drive meldet Angebot" — der Nutzer sieht, wie das Cash-Widget reagiert.
// In Akt 3 ersetzt durch echte Drive-Webhook-Events.
struct SignalDemoView: View {
    let projectID: String
    @Environment(StudioContext.self) private var context
    @State private var fired = false

    var body: some View {
        HStack(spacing: MykSpace.s5) {
            // Status-Punkt
            Circle()
                .fill(fired ? MykColor.drive.color : MykColor.faint.color)
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: fired)
            Text(fired
                ? "Signal gesendet — Cash-Widget zeigt Review-Vorschlag"
                : "Signal-Demo: Drive erkennt neues Eingangsangebot")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            if !fired {
                Button("Auslösen") {
                    withAnimation {
                        context.emit(.offerDetected(
                            projectID: projectID,
                            label: "Arbeitsplatte Naturstein"
                        ))
                        context.emit(.budgetThresholdCrossed(
                            projectID: projectID,
                            ratio: 0.72
                        ))
                        context.emit(.deadlineNear(
                            projectID: projectID,
                            days: 2
                        ))
                        fired = true
                    }
                }
                .font(.mykSmall).foregroundStyle(MykColor.drive.color)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
        .background(MykColor.paper2.color)
        .overlay(alignment: .bottom) { Divider().overlay(MykColor.line.color) }
    }
}
