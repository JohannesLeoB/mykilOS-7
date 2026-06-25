import Foundation

// MARK: - ProjectRegistry
// Woher die Kunden-/Projektliste kommt. Airtable ist eine Implementierung
// (das System-of-Record), der lokale Cache eine zweite. Die App liest über
// dieses Protokoll und kennt die Quelle dahinter nicht — so bleibt sie offline-
// fähig und Airtable bleibt austauschbar.
public protocol ProjectRegistry: Sendable {
    func allCustomers() throws -> [Customer]
    func allProjects() throws -> [Project]
    func projects(forCustomer customerNumber: String) throws -> [Project]
    func addenda(ofParent projectNumber: String) throws -> [Project]
}
