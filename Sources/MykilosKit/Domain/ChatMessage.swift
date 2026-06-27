import Foundation

// MARK: - Chat-Domäne (Phase 0 — konversationeller Assistent)
// Reine Domänentypen für den Assistenten-Chat. Leben in MykilosKit:
// Codable + Sendable, KEIN SwiftUI, KEIN GRDB, KEINE base64-Wire-Felder.
// Das API-DTO (mit base64 image/document, tool_use/tool_result) lebt getrennt
// in MykilosServices (ClaudeWire…) — Mapping ausschließlich in der Service-Schicht.

// MARK: ChatRole
public enum ChatRole: String, Codable, Sendable, Equatable {
    case user
    case assistant
}

// MARK: ChatTurnStatus
// Lebenszyklus eines Assistenten-Turns. `.streaming` während der Antwort,
// `.complete` nach sauberem Abschluss, `.failed` bei Abbruch/Fehler.
public enum ChatTurnStatus: Codable, Sendable, Equatable {
    case complete
    case streaming
    case failed(String)
}

// MARK: ChatScope
// Ein Chat-Thread je Scope: das Heute-Board („home") oder ein Projekt
// (an die Projektnummer gebunden — konsistent mit board(for:)/notes(for:)).
// `rawKey` ist der stabile Persistenz-Schlüssel und spiegelt WidgetBoardID.
public enum ChatScope: Codable, Sendable, Equatable, Hashable {
    case home
    case project(String)

    public var rawKey: String {
        switch self {
        case .home:               "home"
        case .project(let number): "project:\(number)"
        }
    }

    public init?(rawKey: String) {
        if rawKey == "home" {
            self = .home
        } else if rawKey.hasPrefix("project:") {
            self = .project(String(rawKey.dropFirst("project:".count)))
        } else {
            return nil
        }
    }
}

// MARK: ChatAttachmentRef
// Referenz auf einen Anhang — NUR Metadaten + Pfad, NIE die Bytes selbst.
// Die Bytes liegen unter Application Support/ChatAttachments/<sha256>.
public struct ChatAttachmentRef: Codable, Sendable, Equatable {
    public var fileName: String
    public var mimeType: String
    public var byteCount: Int
    public var relativePath: String
    public var sha256: String

    public init(fileName: String, mimeType: String, byteCount: Int, relativePath: String, sha256: String) {
        self.fileName = fileName
        self.mimeType = mimeType
        self.byteCount = byteCount
        self.relativePath = relativePath
        self.sha256 = sha256
    }
}

// MARK: ChatContentBlock
// Ein Inhaltsblock einer Nachricht. Deckt Text, Tool-Use-Schleife (Phase 2)
// und multimodale Anhänge (Phase 3) ab — die Domäne ist von Anfang an
// vollständig, damit spätere Phasen kein Schema-Bruch sind.
public enum ChatContentBlock: Codable, Sendable, Equatable {
    case text(String)
    case toolUse(id: String, name: String, inputJSON: String)
    case toolResult(toolUseID: String, summary: String, isError: Bool)
    case image(ChatAttachmentRef)
    case document(ChatAttachmentRef)
}

// MARK: ChatMessage
public struct ChatMessage: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var role: ChatRole
    public var blocks: [ChatContentBlock]
    public var status: ChatTurnStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        role: ChatRole,
        blocks: [ChatContentBlock],
        status: ChatTurnStatus = .complete,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.blocks = blocks
        self.status = status
        self.createdAt = createdAt
    }

    /// Bequemer Konstruktor für eine reine Textnachricht.
    public static func text(_ text: String, role: ChatRole, status: ChatTurnStatus = .complete) -> ChatMessage {
        ChatMessage(role: role, blocks: [.text(text)], status: status)
    }

    /// Der zusammengesetzte Klartext aller Text-Blöcke (für UI/Tests).
    public var text: String {
        blocks.compactMap { if case let .text(value) = $0 { return value } else { return nil } }
            .joined(separator: "\n")
    }
}
