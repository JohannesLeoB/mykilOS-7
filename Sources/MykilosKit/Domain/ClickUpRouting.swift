import Foundation

// MARK: - ClickUpRoutingZeile
// mykilOS 8, Block D (S4): das Adapter-SCHEMA für die ClickUp-Verdrahtung
// (HANDOFF_PROVISIONING_NOMENKLATUR §9). Jede Zeile = eine Weiche: welcher User bekommt
// wann was, und triggert wohin. Block D legt NUR das Gerüst an (Daten/Config) — KEIN echter
// ClickUp-Write; der konkrete Baum (echte Space/List/Task-IDs) wird live in einer künftigen
// Session geroutet. Re-Routing = Zeile ändern, nicht Code (Johannes' Entscheidung 2026-07-01:
// ClickUp in Block D nur als Routing-Tabelle/Gerüst).
public struct ClickUpRoutingZeile: Codable, Hashable, Sendable, Identifiable {
    public var id: String { routingID }
    public let routingID: String
    public let ebene: String          // global / projekt / user
    public let richtung: String       // app→clickup / clickup→app / beide
    public let appObjekt: String
    public let clickUpObjekt: String
    public let trigger: String
    public let userScope: String
    public let frequenz: String
    public let noGo: String?
    /// Laufzeit-Referenz (Space/List/Task-ID) — leer, bis live geroutet.
    public var clickUpRef: String?
    public var aktiv: Bool
    public var optin: Bool

    public init(routingID: String, ebene: String, richtung: String, appObjekt: String,
                clickUpObjekt: String, trigger: String, userScope: String, frequenz: String,
                noGo: String? = nil, clickUpRef: String? = nil, aktiv: Bool = false, optin: Bool = false) {
        self.routingID = routingID; self.ebene = ebene; self.richtung = richtung
        self.appObjekt = appObjekt; self.clickUpObjekt = clickUpObjekt; self.trigger = trigger
        self.userScope = userScope; self.frequenz = frequenz; self.noGo = noGo
        self.clickUpRef = clickUpRef; self.aktiv = aktiv; self.optin = optin
    }

    /// Default-Zeilen aus dem Provisioning-Vertrag §9 — das Adapter-Schema, gegen das der
    /// künftige ClickUp-Konnektor liest/schreibt. Alle inaktiv (Gerüst, noch nicht live).
    public static let defaults: [ClickUpRoutingZeile] = [
        ClickUpRoutingZeile(routingID: "CU_GLOBAL_SPACES", ebene: "global", richtung: "app→clickup", appObjekt: "Projektliste", clickUpObjekt: "Space/Folder-Baum", trigger: "Provisioning (live)", userScope: "Admin/Johannes", frequenz: "einmalig"),
        ClickUpRoutingZeile(routingID: "CU_PROJ_LIST", ebene: "projekt", richtung: "app→clickup", appObjekt: "neues Projekt", clickUpObjekt: "List in Projekt-Folder", trigger: "Projekt-Anlage", userScope: "Ersteller", frequenz: "je Projekt", noGo: "nur eigenes Projekt"),
        ClickUpRoutingZeile(routingID: "CU_PROJ_TASKS", ebene: "projekt", richtung: "beide", appObjekt: "Aufgaben/Subtasks", clickUpObjekt: "Task/Subtask", trigger: "Status-/Phasenwechsel", userScope: "Projektteam", frequenz: "on-change"),
        ClickUpRoutingZeile(routingID: "CU_ROUTINE_CHECK", ebene: "projekt", richtung: "app→clickup", appObjekt: "Routine", clickUpObjekt: "Checkliste an Task", trigger: "Phasen-Eintritt", userScope: "System", frequenz: "je Phase"),
        ClickUpRoutingZeile(routingID: "CU_USER_INBOX", ebene: "user", richtung: "clickup→app", appObjekt: "Zugewiesene Tasks", clickUpObjekt: "Task (assignee)", trigger: "Polling/Webhook", userScope: "je User (eigene)", frequenz: "periodisch", noGo: "nie fremde Tasks zeigen"),
        ClickUpRoutingZeile(routingID: "CU_USER_TIME", ebene: "user", richtung: "app→clickup", appObjekt: "Zeit-Notiz (opt.)", clickUpObjekt: "Time/Comment", trigger: "Buchung (opt.)", userScope: "je User", frequenz: "on-confirm", noGo: "nur eigene"),
    ]
}
