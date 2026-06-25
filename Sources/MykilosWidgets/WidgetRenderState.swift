import Foundation

// MARK: - WidgetRenderState
// Jedes Widget hat alle Zustände — jeder schön gestaltet, nie nackt.
public enum WidgetRenderState: Equatable, Sendable {
    case loading
    case content
    case empty
    case permissionRequired
    case offline(since: Date)
    case error(String)
}
