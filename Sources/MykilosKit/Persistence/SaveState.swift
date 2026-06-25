import Foundation

// MARK: - SaveState
// Der Speichern-Vertrag. Jede speicherbare Fläche zeigt echten Zustand —
// kein stilles Nichts, aber auch kein Spinner-Theater.
public enum SaveState: Equatable, Sendable {
    case idle
    case saving
    case saved(Date)
    case failed(String)   // nutzerlesbare Meldung

    public var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
