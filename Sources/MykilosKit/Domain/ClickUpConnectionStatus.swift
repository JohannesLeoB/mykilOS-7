public enum ClickUpConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected
    case error(String)
}
