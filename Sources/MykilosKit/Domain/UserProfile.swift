import Foundation

// MARK: - UserProfile
// Lokale Identität des/der Nutzer:in (Anzeigename + Rolle). V1: ein lokales
// Profil je Gerät — bewusste Vereinfachung gegenüber dem Team-Identitätsmodell
// (jeder hat sein eigenes mykilOS). Reine Domäne: kein SwiftUI, kein GRDB.
public struct UserProfile: Equatable, Sendable, Codable {
    public var displayName: String
    public var role: String
    public var updatedAt: Date

    public init(displayName: String, role: String, updatedAt: Date = Date()) {
        self.displayName = displayName
        self.role = role
        self.updatedAt = updatedAt
    }

    public static let empty = UserProfile(displayName: "", role: "", updatedAt: .distantPast)

    /// Ein Profil gilt als eingerichtet, sobald ein Anzeigename existiert.
    public var isComplete: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
