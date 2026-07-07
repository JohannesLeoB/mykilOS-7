import Foundation
import Security

// MARK: - MykInvitePasswordGenerator (Johannes 2026-07-07)
// Erzeugt ein starkes Zufallspasswort für den Einladungs-Schlüsselbund. Das ist die
// PRAKTISCHE Härtung gegen den eigentlichen Angriff (Passwort per Brute-Force raten): mit
// einem starken Zufallspasswort ist selbst das bewusst einfache KDF (SHA256 salted + 100k,
// siehe MykInviteCrypto) unbrechbar — der Flaschenhals wäre ein SCHWACHES Menschenpasswort,
// und genau das wird hier vermieden. Der Admin kann trotzdem ein eigenes tippen.
//
// Alphabet ohne mehrdeutige Zeichen (0/O, 1/l/I) — die Datei geht per Mail, das Passwort
// über einen getrennten Kanal (mündlich/abtippen), da helfen unverwechselbare Zeichen.
public enum MykInvitePasswordGenerator {
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789")

    /// Kryptografisch zufälliges Passwort der gewünschten Länge (Default 20). Zieht die Indizes
    /// aus `SecRandomCopyBytes` und mappt sie modulo-bias-frei über Rejection-Sampling auf das
    /// Alphabet (kein simples `% count`, das häufige Zeichen bevorzugen würde).
    public static func generate(length: Int = 20) -> String {
        let sicher = max(1, length)
        let count = alphabet.count
        // Größter Vielfacher von `count` unter 256 → alles darüber wird verworfen (kein Bias).
        let grenze = 256 - (256 % count)
        var ergebnis = [Character]()
        ergebnis.reserveCapacity(sicher)
        while ergebnis.count < sicher {
            var byte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else { continue }
            if Int(byte) >= grenze { continue }   // Rejection-Sampling gegen Modulo-Bias
            ergebnis.append(alphabet[Int(byte) % count])
        }
        return String(ergebnis)
    }
}
