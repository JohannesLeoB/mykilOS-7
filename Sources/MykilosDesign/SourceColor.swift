import Foundation

// Verbindet die Quelle (im Kern) mit ihrer Farbe (im Designsystem),
// ohne dass der Kern SwiftUI kennen muss.
public enum SourceColorKey: String, Sendable {
    case drive, people, calendar, tasks, cash, notes, assistant

    public var token: MykColor {
        switch self {
        case .drive:               .drive
        case .people, .calendar:   .people
        case .tasks:               .tasks
        case .cash:                .cash
        case .notes:               .personal
        case .assistant:           .ink
        }
    }
}
