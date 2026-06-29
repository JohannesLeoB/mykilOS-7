import Foundation

// MARK: - AssistantToolManifest (Mandate E — Typed I/O)
//
// Eine statische Brücke zwischen Assistenten-Tool-Namen (z. B. "search_gmail")
// und den kanonischen Datenstrom-Manifest-IDs (z. B. "GMAIL_SEARCH").
//
// WARUM: Vor dieser Brücke loggte die ConversationEngine den ROHEN Tool-Namen als
// `integrationID` (`integrationID: toolUse.name`). Das SchaltzentrumView matcht aber
// auf die Manifest-IDs aus DatastromManifest.json. Folge (Forensik F12): jeder
// Tool-Lauf wurde unter "search_gmail" protokolliert, die Schaltzentrum-Zeile
// "GMAIL_SEARCH" fand nie einen Eintrag → 0 Handshakes, egal wie oft gesucht wurde.
//
// Diese Map ist die EINE Quelle der Wahrheit für die Zuordnung. Ein Cross-Check-Test
// (AssistantToolManifestTests) stellt sicher, dass (a) jeder registrierte Tool-Name
// hier eine Zuordnung hat und (b) jede Ziel-ID tatsächlich im Manifest existiert.
public enum AssistantToolManifest {

    /// Tool-Name → kanonische Manifest-`integrationID`.
    /// Jeder registrierte Tool-Name MUSS hier stehen (Test erzwingt es).
    public static let toolToManifestID: [String: String] = [
        "search_gmail":           "GMAIL_SEARCH",
        "list_calendar_events":   "CALENDAR_LIST",
        "suggest_calendar_event": "CALENDAR_SUGGEST",
        "list_drive_folder":      "DRIVE_ASSISTANT_LIST",
        "find_offers":            "DRIVE_OFFERS_FIND",
        "read_drive_file":        "DRIVE_FILE_READ",
        "search_contacts":        "CONTACTS_QUERY",
        "create_contact":         "CONTACTS_CREATE",
        "list_clickup_tasks":     "CLICKUP_TASKS",
        "search_katalog":         "LOCAL_DEVICECATALOG_ARTIKEL",
        "query_studio_knowledge": "STUDIO_KNOWLEDGE_QUERY",
        "lookup_kunde":           "AIRTABLE_KUNDEN_LOOKUP",
        "lookup_kontakt":         "AIRTABLE_KONTAKTE_LOOKUP",
        "create_note":            "ASSISTANT_NOTES",
        "list_notes":             "ASSISTANT_NOTES",
        "update_note":            "ASSISTANT_NOTES",
        "delete_note":            "ASSISTANT_NOTES",
        "create_task":            "ASSISTANT_TASKS",
        "list_tasks":             "ASSISTANT_TASKS",
        "complete_task":          "ASSISTANT_TASKS",
        "delete_task":            "ASSISTANT_TASKS",
        "schaetze_projekt":       "KALKULATION_LOCAL",
    ]

    /// Umbrella-ID für einen (noch) nicht zugeordneten Tool-Namen. Existiert im
    /// Manifest, sodass die Schaltzentrum-Zeile auch bei einem künftigen, noch nicht
    /// gemappten Tool nicht ins Leere zeigt. Der Cross-Check-Test verhindert, dass
    /// reguläre Tools still hierher fallen.
    public static let umbrellaID = "ASSISTANT_TOOL_CALL"

    /// Liefert die Manifest-ID für einen Tool-Namen. Unbekannt → Umbrella.
    public static func manifestID(forTool toolName: String) -> String {
        toolToManifestID[toolName] ?? umbrellaID
    }
}
