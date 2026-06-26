public enum SevdeskConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected
    case error(String)
}
