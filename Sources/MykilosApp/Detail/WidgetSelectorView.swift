import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosWidgets
import MykilosServices

// MARK: - WidgetSelectorView
// Popover zum Selbst-Konfigurieren der Projekt-Übersicht: pro Widget-Art ein
// Sichtbarkeits-Schalter (aus = ausgeblendet, Position/Größe bleiben erhalten) und —
// wenn sichtbar — eine Größenwahl (S/M/Breit/Voll). Nutzt die vorhandene
// WidgetBoardStore-CRUD (add/toggle/resize); schreibt sofort (SaveState sichtbar).
@MainActor
struct WidgetSelectorView: View {
    let boardStore: WidgetBoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            HStack(spacing: MykSpace.s2) {
                Image(systemName: "square.grid.2x2")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.brand.color)
                Text("Widgets der Übersicht")
                    .font(.mykHeadline)
                    .foregroundStyle(MykColor.ink.color)
            }
            Text("Ein-/ausblenden und Größe wählen. Reihenfolge per Drag im Board.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)

            Divider().overlay(MykColor.line.color)

            VStack(spacing: 0) {
                ForEach(WidgetBoardDefault.projectSelectableKinds, id: \.self) { kind in
                    zeile(for: kind)
                    if kind != WidgetBoardDefault.projectSelectableKinds.last {
                        Divider().overlay(MykColor.line.color.opacity(0.5))
                    }
                }
            }
        }
        .padding(MykSpace.s5)
        .frame(width: 320)
        .background(MykColor.card.color)
    }

    // MARK: - Zeile je Widget-Art

    private func zeile(for kind: WidgetKind) -> some View {
        let instance = boardStore.instances.first { $0.kind == kind }
        let sichtbar = instance?.isVisible ?? false
        return HStack(spacing: MykSpace.s3) {
            Image(systemName: kind.iconName)
                .font(.mykCaption)
                .foregroundStyle(kind.source.accentColor)
                .frame(width: 20)
            Text(titel(for: kind))
                .font(.mykSmall)
                .foregroundStyle(sichtbar ? MykColor.ink.color : MykColor.muted.color)
            Spacer()
            if sichtbar, let instance {
                groessenMenu(for: instance)
            }
            Toggle("", isOn: Binding(
                get: { sichtbar },
                set: { setSichtbar($0, kind: kind, instance: instance) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(kind.source.accentColor)
            .accessibilityLabel("\(titel(for: kind)) \(sichtbar ? "ausblenden" : "einblenden")")
        }
        .padding(.vertical, MykSpace.s3)
    }

    private func groessenMenu(for instance: WidgetInstance) -> some View {
        Menu {
            ForEach(Self.groessen, id: \.0) { (size, label) in
                Button {
                    try? boardStore.resize(id: instance.id, to: size)
                } label: {
                    if instance.size == size {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            Text(groessenLabel(instance.size))
                .font(.mykMono(9))
                .foregroundStyle(MykColor.muted.color)
                .padding(.horizontal, MykSpace.s2)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(MykColor.line.color, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - Aktionen

    private func setSichtbar(_ on: Bool, kind: WidgetKind, instance: WidgetInstance?) {
        if let instance {
            // Vorhanden → nur Sichtbarkeit umschalten (Position/Größe bleiben erhalten).
            if instance.isVisible != on { try? boardStore.toggle(id: instance.id) }
        } else if on {
            // Nie dagewesen → neu anlegen (sichtbar, ans Ende).
            try? boardStore.add(kind: kind, size: standardGroesse(kind))
        }
    }

    // MARK: - Darstellung

    private static let groessen: [(WidgetSize, String)] = [
        (.small, "Klein"), (.medium, "Mittel"), (.wide, "Breit"), (.full, "Voll"),
    ]

    private func groessenLabel(_ size: WidgetSize) -> String {
        switch size {
        case .small:  "S"
        case .medium: "M"
        case .wide:   "Breit"
        case .full:   "Voll"
        }
    }

    private func standardGroesse(_ kind: WidgetKind) -> WidgetSize {
        switch kind {
        case .assistant:              .full
        case .drive, .cash, .warenkorb: .wide
        default:                       .medium
        }
    }

    private func titel(for kind: WidgetKind) -> String {
        switch kind {
        case .drive:     "Dateien (Drive)"
        case .contacts:  "Kontakte"
        case .tasks:     "Aufgaben (ClickUp)"
        case .cash:      "Cash / Umsatz"
        case .calendar:  "Kalender"
        case .notes:     "Notizen"
        case .warenkorb: "Warenkorb"
        case .mail:      "Mail"
        case .assistant: "Assistent"
        default:         kind.rawValue.capitalized
        }
    }
}
