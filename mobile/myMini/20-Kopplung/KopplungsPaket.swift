import CryptoKit
import Foundation

/// Der Klartext-Inhalt eines Kopplungs-Pakets: Identitaet + die geteilten
/// Instrumente (Keys), die der Satellit von der Mothership uebernimmt.
/// Google bleibt bewusst DRAUSSEN - dessen OAuth-Anmeldung ist geraete-
/// gebunden und laeuft weiter als eigener Sign-in auf dem iPhone.
/// Clockodo bleibt nutzer-privat (Doktrin) - nur die eigenen Credentials.
struct KopplungsInhalt: Codable {
    var version = 1
    /// Der Kosmos: EINE Firma, EINE Mothership, kennt alle User + Rollen
    /// (Johannes). Das Geraet bindet sich an genau diese Firma.
    var firma: String?
    let benutzerName: String
    var benutzerEmail: String?
    /// Rolle des Nutzers, wie die Mothership sie fuehrt (Freitext vom Schiff -
    /// der Satellit erfindet keine Rollen-Taxonomie). Steuert spaeter
    /// Sichtbarkeit/Rechte.
    var rolle: String?
    var airtablePAT: String?
    var claudeKey: String?
    var fireflyClientID: String?
    var fireflyClientSecret: String?
}

/// Der verschluesselte Umschlag, wie er per QR/AirDrop uebertragen wird.
/// AES-GCM, Schluessel aus der PIN + Salt via HKDF. Ohne die richtige PIN
/// laesst sich der Inhalt nicht oeffnen (GCM-Auth schlaegt fehl).
struct KopplungsUmschlag: Codable {
    var version = 1
    /// base64 des Salt.
    let salt: String
    /// base64 der AES-GCM combined box (nonce + ciphertext + tag).
    let daten: String
}

enum KopplungsFehler: Error, LocalizedError {
    case ungueltigesPaket
    case falschePin
    case keinInstrument

    var errorDescription: String? {
        switch self {
        case .ungueltigesPaket: return "Das ist kein gueltiges mykilOS-Kopplungs-Paket."
        case .falschePin: return "Falsche PIN - der Umschlag liess sich nicht oeffnen."
        case .keinInstrument: return "Das Paket enthaelt keine uebernehmbaren Zugaenge."
        }
    }
}

enum KopplungsKrypto {
    private static let info = Data("mykilOS-kopplung-v1".utf8)

    private static func schluessel(pin: String, salt: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: Data(pin.utf8)),
            salt: salt, info: info, outputByteCount: 32)
    }

    /// Verschluesselt einen Inhalt mit PIN -> Umschlag. (Die Mothership macht
    /// exakt das; hier mitgebaut, damit der Algorithmus eindeutig dokumentiert
    /// und testbar ist.)
    static func verschluessle(_ inhalt: KopplungsInhalt, pin: String, salt: Data = Data((0..<16).map { _ in 0 })) throws -> KopplungsUmschlag {
        let klartext = try JSONEncoder().encode(inhalt)
        let box = try AES.GCM.seal(klartext, using: schluessel(pin: pin, salt: salt))
        guard let combined = box.combined else { throw KopplungsFehler.ungueltigesPaket }
        return KopplungsUmschlag(salt: salt.base64EncodedString(), daten: combined.base64EncodedString())
    }

    /// Oeffnet einen Umschlag mit der PIN.
    static func entschluessle(_ umschlag: KopplungsUmschlag, pin: String) throws -> KopplungsInhalt {
        guard let salt = Data(base64Encoded: umschlag.salt),
              let daten = Data(base64Encoded: umschlag.daten) else {
            throw KopplungsFehler.ungueltigesPaket
        }
        let key = schluessel(pin: pin, salt: salt)
        let klartext: Data
        do {
            let box = try AES.GCM.SealedBox(combined: daten)
            klartext = try AES.GCM.open(box, using: key)
        } catch {
            throw KopplungsFehler.falschePin
        }
        guard let inhalt = try? JSONDecoder().decode(KopplungsInhalt.self, from: klartext) else {
            throw KopplungsFehler.ungueltigesPaket
        }
        return inhalt
    }

    /// Liest einen Umschlag aus dem uebertragenen Text (QR-Inhalt oder
    /// AirDrop-Dateiinhalt = JSON des Umschlags).
    static func umschlagAusText(_ text: String) -> KopplungsUmschlag? {
        guard let daten = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(KopplungsUmschlag.self, from: daten)
    }
}

/// Schreibt die uebernommenen Zugaenge in die jeweiligen Keychain-Stores.
/// Gibt die Namen der tatsaechlich uebernommenen Instrumente zurueck.
enum KopplungsAnwender {
    @discardableResult
    static func anwenden(_ inhalt: KopplungsInhalt) throws -> [String] {
        var uebernommen: [String] = []
        if let pat = inhalt.airtablePAT, !pat.isEmpty {
            try KeychainAirtablePostboxCredentialsStore().save(AirtablePostboxCredentials(pat: pat))
            uebernommen.append("Airtable")
        }
        if let key = inhalt.claudeKey, !key.isEmpty {
            try KeychainClaudeCredentialsStore().save(ClaudeCredentials(apiKey: key))
            uebernommen.append("Claude / Copilot")
        }
        if let id = inhalt.fireflyClientID, let secret = inhalt.fireflyClientSecret,
           !id.isEmpty, !secret.isEmpty {
            try KeychainFireflyCredentialsStore().save(FireflyCredentials(clientID: id, clientSecret: secret))
            uebernommen.append("Firefly")
        }
        guard !uebernommen.isEmpty else { throw KopplungsFehler.keinInstrument }
        return uebernommen
    }
}
