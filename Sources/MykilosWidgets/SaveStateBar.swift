import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - SaveStateBar
// Der sichtbare Speichern-Vertrag. Erscheint unten wenn relevant.
// idle → nichts zu sehen. saving → Spinner. saved → grüne Bestätigung mit Timestamp.
// failed → roter Hinweis mit "Erneut versuchen".
// So sieht aus, wenn Daten wirklich gespeichert werden — nicht stilles Nichts.
public struct SaveStateBar: View {
    public let state: SaveState
    public var retryAction: (() -> Void)?

    public init(state: SaveState, retryAction: (() -> Void)? = nil) {
        self.state       = state
        self.retryAction = retryAction
    }

    public var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .saving:
                bar {
                    ProgressView().scaleEffect(0.7).tint(MykColor.muted.color)
                    Text("Speichern…").font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            case .saved(let date):
                bar {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MykColor.positive.color)
                        .font(.mykCaption)
                    Text("Gespeichert \(date.formatted(.dateTime.hour().minute().second()))")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            case .failed(let msg):
                bar {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(MykColor.critical.color)
                        .font(.mykCaption)
                    Text("Nicht gespeichert — \(msg)")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.critical.color)
                        .lineLimit(1)
                    if let retry = retryAction {
                        Spacer()
                        Button("Erneut versuchen", action: retry)
                            .font(.mykMono(10))
                            .foregroundStyle(MykColor.critical.color)
                            .buttonStyle(.plain)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: stateKey)
    }

    // MARK: Helfer
    private func bar<C: View>(@ViewBuilder content: @escaping () -> C) -> some View {
        HStack(spacing: 8) {
            content()
            Spacer()
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s3)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().overlay(MykColor.line.color)
        }
    }

    private var stateKey: String {
        switch state {
        case .idle:    "idle"
        case .saving:  "saving"
        case .saved:   "saved"
        case .failed:  "failed"
        }
    }
}
