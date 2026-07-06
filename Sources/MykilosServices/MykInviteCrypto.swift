import Foundation
import CryptoKit
import Security
import MykilosKit

// MARK: - MykInviteError
public enum MykInviteError: Error, LocalizedError, Equatable {
    case falschesPasswort
    case kaputteDatei
    case abgelaufen
    case keineZugangsdatenVerbunden

    public var errorDescription: String? {
        switch self {
        case .falschesPasswort: return "Falsches Passwort oder beschädigte Einladung."
        case .kaputteDatei: return "Die Einladungsdatei ist beschädigt oder kein gültiges .mykinvite-Format."
        case .abgelaufen: return "Diese Einladung ist abgelaufen."
        case .keineZugangsdatenVerbunden: return "Keine Airtable-Zugangsdaten verbunden — es gibt nichts zu teilen."
        }
    }
}

// MARK: - MykInviteCrypto (Onboarding-Plan Ebene 2)
// Verschlüsselt/entschlüsselt eine .mykinvite-Datei: AES-GCM, Schlüssel aus einem Einmal-
// Passwort abgeleitet. Übergabe bewusst zweikanalig (Plan-Doku): die DATEI per Mail, das
// PASSWORT über einen getrennten Kanal (mündlich/Signal) — wer nur eins abfängt, hat nichts.
//
// ⚠️ Ehrlicher Hinweis zur Schlüsselableitung: CryptoKit bietet kein PBKDF2/scrypt/Argon2 für
// niedrige-Entropie-Passwörter; ein echtes CommonCrypto-PBKDF2 bräuchte einen Bridging-Header,
// den SPM hier nicht sauber trägt. Als Kompromiss: SHA256 salted + 100k Iterationen (deutlich
// härter als ein Einzel-Hash, aber KEIN peer-reviewtes KDF). Für den tatsächlichen Bedrohungs-
// fall hier (interne Team-Keys, Zwei-Kanal-Übergabe) ausreichend; für höhere Ansprüche später
// auf eine echte PBKDF2/Argon2-Bibliothek wechseln.
public enum MykInviteCrypto {
    private static let saltLength = 16
    private static let iterationen = 100_000
    static let dateiendung = "mykinvite"

    /// Verschlüsselt einen Payload mit einem Einmal-Passwort → Bytes für die .mykinvite-Datei.
    public static func verschluesseln(_ payload: MykInvitePayload, passwort: String) throws -> Data {
        var saltBytes = [UInt8](repeating: 0, count: saltLength)
        let result = SecRandomCopyBytes(kSecRandomDefault, saltLength, &saltBytes)
        guard result == errSecSuccess else { throw MykInviteError.kaputteDatei }
        let salt = Data(saltBytes)

        let key = try schluessel(ausPasswort: passwort, salt: salt)
        let klartext = try JSONEncoder().encode(payload)
        let versiegelt = try AES.GCM.seal(klartext, using: key)
        guard let combined = versiegelt.combined else { throw MykInviteError.kaputteDatei }
        // Format: [salt (16 Byte)][AES.GCM.combined (nonce + ciphertext + tag)].
        return salt + combined
    }

    /// Entschlüsselt eine .mykinvite-Datei mit dem vom Nutzer eingegebenen Passwort.
    public static func entschluesseln(_ daten: Data, passwort: String) throws -> MykInvitePayload {
        guard daten.count > saltLength else { throw MykInviteError.kaputteDatei }
        let salt = Data(daten.prefix(saltLength))
        let rest = Data(daten.dropFirst(saltLength))
        let key = try schluessel(ausPasswort: passwort, salt: salt)

        let klartext: Data
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: rest)
            klartext = try AES.GCM.open(sealedBox, using: key)
        } catch {
            // Falsches Passwort UND kaputte/manipulierte Datei landen hier beide (AES-GCM
            // unterscheidet nicht) — für den Nutzer ist "falsches Passwort" die hilfreichere
            // erste Vermutung.
            throw MykInviteError.falschesPasswort
        }

        let payload: MykInvitePayload
        do {
            payload = try JSONDecoder().decode(MykInvitePayload.self, from: klartext)
        } catch {
            throw MykInviteError.kaputteDatei
        }
        guard payload.istAbgelaufen == false else { throw MykInviteError.abgelaufen }
        return payload
    }

    private static func schluessel(ausPasswort passwort: String, salt: Data) throws -> SymmetricKey {
        guard let passwortData = passwort.data(using: .utf8), passwortData.isEmpty == false else {
            throw MykInviteError.falschesPasswort
        }
        var derived = passwortData + salt
        for _ in 0..<iterationen {
            derived = Data(SHA256.hash(data: derived))
        }
        return SymmetricKey(data: derived)
    }
}
