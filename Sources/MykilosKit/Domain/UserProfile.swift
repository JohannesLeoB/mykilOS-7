import Foundation

// MARK: - UserProfile
// Lokale Identität des/der Nutzer:in (Anzeigename + Rolle). V1: ein lokales
// Profil je Gerät — bewusste Vereinfachung gegenüber dem Team-Identitätsmodell
// (jeder hat sein eigenes mykilOS). Reine Domäne: kein SwiftUI, kein GRDB.
public struct UserProfile: Equatable, Sendable, Codable {
    public var displayName: String
    public var role: String
    public var updatedAt: Date
    // Nutzer-spezifische Identitäts-Felder (Private Area, optional)
    public var clockodoUserID: String?
    public var googleDomain: String?
    // V10 Folge-Block A: stabile lokale Nutzer-ID (First-Run-UUID), Grundlage
    // für Per-User-Keychain-Services. Anders als clockodoUserID/googleDomain
    // (optional, oft leer, extern) wird diese IMMER beim ersten Profil-Load
    // erzeugt und danach nie mehr geändert — siehe AppState.ensureUserID().
    // Optional nur wegen additivem Rollout (Bestandsprofile ohne diese Spalte).
    public var userID: String?
    // Persönliche Profil-Angaben (v28, 2026-07-06 — „richtiges schönes Nutzerprofil").
    // Alle optional + additiv: Bestandsprofile ohne diese Spalten decodieren als nil.
    // Rein lokal, nie extern geteilt (Datenschutz-Sektion steuert Sichtbarkeit).
    public var birthDate: Date?
    public var phone: String?
    public var department: String?
    public var bio: String?

    public init(
        displayName: String,
        role: String,
        updatedAt: Date = Date(),
        clockodoUserID: String? = nil,
        googleDomain: String? = nil,
        userID: String? = nil,
        birthDate: Date? = nil,
        phone: String? = nil,
        department: String? = nil,
        bio: String? = nil
    ) {
        self.displayName = displayName
        self.role = role
        self.updatedAt = updatedAt
        self.clockodoUserID = clockodoUserID
        self.googleDomain = googleDomain
        self.userID = userID
        self.birthDate = birthDate
        self.phone = phone
        self.department = department
        self.bio = bio
    }

    public static let empty = UserProfile(displayName: "", role: "", updatedAt: .distantPast)

    public var isComplete: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
