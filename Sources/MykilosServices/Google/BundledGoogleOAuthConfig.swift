import Foundation

// MARK: - BundledGoogleOAuthConfig (Onboarding-Plan Ebene 1)
// Liest ein zur Build-Zeit eingebackenes Google-OAuth-Client-Paar aus dem App-Bundle
// (Info.plist-Keys MykGoogleClientID/MykGoogleClientSecret). Injiziert von
// script/build_and_run.sh aus einer lokalen, git-ignorierten Datei
// (script/.google-oauth.local.sh) — NIE im Klartext-Repo. Fehlt die Datei beim Bauen,
// bleiben die Keys leer und ALLES verhält sich exakt wie heute (manuelle Eingabe als
// Notausgang). Für einen Desktop-OAuth-Client ist das Einbacken der von Google
// vorgesehene Standard — PKCE schützt den eigentlichen Login-Flow, der Client-Secret
// gilt in diesem Kontext nicht als geheim.
public enum BundledGoogleOAuthConfig {
    private static let clientIDKey = "MykGoogleClientID"
    private static let clientSecretKey = "MykGoogleClientSecret"

    public static var clientID: String? { wert(fuerKey: clientIDKey) }
    public static var clientSecret: String? { wert(fuerKey: clientSecretKey) }

    public static var istVerfuegbar: Bool { clientID != nil }

    /// Injizierbar für Tests (Default: das echte App-Bundle).
    static func wert(fuerKey key: String, aus dict: [String: Any]? = Bundle.main.infoDictionary) -> String? {
        guard let roh = dict?[key] as? String else { return nil }
        let getrimmt = roh.trimmingCharacters(in: .whitespacesAndNewlines)
        return getrimmt.isEmpty ? nil : getrimmt
    }
}
