import Foundation
import MessageUI
import Observation
import SwiftUI

/// Ein Servicepartner (Werkskundendienst/Haendler) — lokal gepflegt, einmal
/// anlegen, immer wiederverwenden. Ehrliche Grenze: Hersteller bieten keine
/// oeffentlichen Ticket-APIs — der universelle Kanal ist eine vollstaendige
/// E-Mail an den Partner, vorbefuellt aus App-Daten.
struct ServicePartner: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var marken: String

    init(id: UUID = UUID(), name: String, email: String, marken: String = "") {
        self.id = id
        self.name = name
        self.email = email
        self.marken = marken
    }
}

/// Log-Eintrag einer rausgegangenen Service-Anfrage.
struct ServiceAnfrage: Identifiable, Codable, Hashable {
    let id: UUID
    let partnerName: String
    let projectTitel: String
    let geraet: String
    let gesendetAm: Date

    init(id: UUID = UUID(), partnerName: String, projectTitel: String, geraet: String, gesendetAm: Date = Date()) {
        self.id = id
        self.partnerName = partnerName
        self.projectTitel = projectTitel
        self.geraet = geraet
        self.gesendetAm = gesendetAm
    }
}

@Observable
final class ServicePartnerStore {
    private(set) var partner: [ServicePartner] = []
    private(set) var anfragen: [ServiceAnfrage] = []
    private let partnerURL: URL
    private let anfragenURL: URL

    init(documentsURL: URL? = nil) {
        let documents = documentsURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.partnerURL = documents.appendingPathComponent("servicepartner.json")
        self.anfragenURL = documents.appendingPathComponent("serviceanfragen.json")
        if let d = try? Data(contentsOf: partnerURL), let p = try? JSONDecoder().decode([ServicePartner].self, from: d) { partner = p }
        if let d = try? Data(contentsOf: anfragenURL), let a = try? JSONDecoder().decode([ServiceAnfrage].self, from: d) { anfragen = a }
    }

    func speicherePartner(_ neu: ServicePartner) throws {
        var next = partner
        if let i = next.firstIndex(where: { $0.id == neu.id }) { next[i] = neu } else { next.append(neu) }
        let data = try JSONEncoder().encode(next)
        try data.write(to: partnerURL, options: .atomic)
        partner = next
    }

    func loggeAnfrage(_ anfrage: ServiceAnfrage) throws {
        var next = anfragen
        next.append(anfrage)
        let data = try JSONEncoder().encode(next)
        try data.write(to: anfragenURL, options: .atomic)
        anfragen = next
    }
}

/// Apples Mail-Kompositions-Sheet — der einzige Weg, eine E-Mail MIT
/// Anhaengen (Fotos) vorzubereiten. Gesendet wird erst, wenn der Mensch im
/// Sheet auf Senden tippt — eingebautes Karte->Bestaetigung.
struct MailKomposition: UIViewControllerRepresentable {
    let empfaenger: String
    let betreff: String
    let text: String
    let anhaenge: [(daten: Data, dateiname: String)]
    let onFertig: (Bool) -> Void

    static var kannSenden: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([empfaenger])
        mail.setSubject(betreff)
        mail.setMessageBody(text, isHTML: false)
        for anhang in anhaenge {
            mail.addAttachmentData(anhang.daten, mimeType: "image/jpeg", fileName: anhang.dateiname)
        }
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    func makeCoordinator() -> Koordinator { Koordinator(onFertig: onFertig) }

    final class Koordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFertig: (Bool) -> Void
        init(onFertig: @escaping (Bool) -> Void) { self.onFertig = onFertig }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
            onFertig(result == .sent)
        }
    }
}
