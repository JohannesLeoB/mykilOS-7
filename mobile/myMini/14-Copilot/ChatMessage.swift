import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    enum Rolle: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let rolle: Rolle
    let text: String

    init(id: UUID = UUID(), rolle: Rolle, text: String) {
        self.id = id
        self.rolle = rolle
        self.text = text
    }
}
