import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - WidgetContainer
// Hülle für jedes Widget: Quellen-Chip, Quellen-Zeile unten, Hover-Schatten,
// projektweite Mitfärbung (linke Kante wenn Projekt im Fokus), Renderstates.
public struct WidgetContainer<Content: View>: View {
    public let kind: WidgetKind
    public let sourceLabel: String
    public let renderState: WidgetRenderState
    public let projectID: String
    @ViewBuilder public let content: () -> Content

    @Environment(StudioContext.self) private var context
    @State private var isHovered = false

    public init(
        kind: WidgetKind,
        sourceLabel: String,
        renderState: WidgetRenderState = .content,
        projectID: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.kind = kind
        self.sourceLabel = sourceLabel
        self.renderState = renderState
        self.projectID = projectID
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainContent
            sourceLine
        }
        .background(MykColor.card.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.line.color, lineWidth: 1)
        )
        // Projektweite Mitfärbung: feine linke Kante
        .overlay(alignment: .leading) {
            if context.isFocused(projectID) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(kind.source.accentColor)
                    .frame(width: 3)
                    .padding(.vertical, MykRadius.md)
                    .transition(.opacity)
            }
        }
        .shadow(
            color: .black.opacity(isHovered ? 0.08 : 0.03),
            radius: isHovered ? 20 : 4,
            x: 0, y: isHovered ? 6 : 1
        )
        .scaleEffect(isHovered ? 1.007 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isHovered)
        .animation(.easeInOut(duration: 0.25), value: context.isFocused(projectID))
        .onHover { isHovered = $0 }
    }

    // MARK: Haupt-Inhalt je Renderstate
    @ViewBuilder
    private var mainContent: some View {
        switch renderState {
        case .content:
            content().padding(MykSpace.s6)
        case .loading:
            loadingView
        case .empty:
            emptyView
        case .permissionRequired:
            permissionView
        case .offline(let since):
            offlineView(since: since)
        case .error(let msg):
            errorView(message: msg)
        }
    }

    // MARK: Quellen-Zeile
    private var sourceLine: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 5, height: 5)
            Text(sourceLabel)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(MykColor.line.color)
        }
    }

    // MARK: Zustands-Views
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView().tint(MykColor.muted.color).padding(MykSpace.s8)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: "tray")
                .foregroundStyle(MykColor.faint.color)
            Text("Noch leer")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
        }
        .frame(maxWidth: .infinity)
        .padding(MykSpace.s8)
    }

    private var permissionView: some View {
        VStack(spacing: MykSpace.s4) {
            Image(systemName: "lock")
                .foregroundStyle(MykColor.faint.color)
            Text("Berechtigung nötig")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
        }
        .frame(maxWidth: .infinity)
        .padding(MykSpace.s8)
    }

    private func offlineView(since: Date) -> some View {
        VStack(spacing: MykSpace.s3) {
            Image(systemName: "wifi.slash").foregroundStyle(MykColor.faint.color)
            Text("Verbindung schläft")
                .font(.mykCaption).foregroundStyle(MykColor.muted.color)
            Text("Letzter Stand \(since.formatted(.relative(presentation: .named)))")
                .font(.mykMono(9.5)).foregroundStyle(MykColor.faint.color)
        }
        .frame(maxWidth: .infinity).padding(MykSpace.s8)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: MykSpace.s3) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(MykColor.faint.color)
            Text(message).font(.mykCaption).foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(MykSpace.s8)
    }

    // MARK: Helfer
    private var stateColor: Color {
        switch renderState {
        case .content:           MykColor.positive.color
        case .offline:           MykColor.tasks.color
        case .error:             MykColor.critical.color
        case .loading:           MykColor.muted.color
        case .empty:             MykColor.faint.color
        case .permissionRequired:MykColor.cash.color
        }
    }
}

// MARK: - WidgetKind Extensions (Quellen-Mapping)
extension WidgetKind {
    var source: WidgetSource {
        switch self {
        case .drive:     .drive
        case .tasks:     .tasks
        case .contacts:  .people
        case .cash:      .cash
        case .calendar:  .calendar
        case .notes:     .notes
        case .assistant: .assistant
        case .focus:          .assistant
        case .projectFaves:   .tasks
        case .mail:           .mail
        case .clockodo:       .tasks
        case .recentActivity: .drive
        }
    }
}

extension WidgetSource {
    var accentColor: Color {
        switch self {
        case .drive:             MykColor.drive.color
        case .people, .calendar: MykColor.people.color
        case .tasks:             MykColor.tasks.color
        case .cash:              MykColor.cash.color
        case .notes, .mail:      MykColor.personal.color
        case .assistant:         MykColor.ink.color
        }
    }
}
