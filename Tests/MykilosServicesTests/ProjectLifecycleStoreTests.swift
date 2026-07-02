import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

// Beweist: die nutzergesetzte Lebenszyklus-Stufe überlebt den App-Neustart (GRDB-backed),
// und die Ableitung behauptet nie mehr als die Signale belegen.
@MainActor
struct ProjectLifecycleStoreTests {

    @Test func stufeUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProjectLifecycleStore(db: db)
        try store.load()
        #expect(store.stage(for: "2026-015") == nil)   // nichts gesetzt → nil (Aufrufer leitet ab)

        try store.setStage(.ausfuehrung, for: "2026-015")
        try store.setStage(.angebot, for: "2026-016")

        // Neustart: neue Instanz auf derselben DB
        let reborn = ProjectLifecycleStore(db: db)
        try reborn.load()
        #expect(reborn.stage(for: "2026-015") == .ausfuehrung)
        #expect(reborn.stage(for: "2026-016") == .angebot)
    }

    @Test func upsertUeberschreibtStattZuDuplizieren() throws {
        let db = try GRDBDatabase.inMemory()
        let store = ProjectLifecycleStore(db: db)
        try store.load()
        try store.setStage(.planung, for: "2026-015")
        try store.setStage(.abschluss, for: "2026-015")   // Korrektur überschreibt

        let reborn = ProjectLifecycleStore(db: db)
        try reborn.load()
        #expect(reborn.stage(for: "2026-015") == .abschluss)
        #expect(reborn.stages.count == 1)
    }

    @Test func ableitungBehauptetNieMehrAlsBelegt() {
        // Kein Signal → Akquise (ehrlicher Default), nicht etwa "Angebot".
        #expect(ProjectLifecycleDeriver.derive(timeBookedHours: 0, isArchived: false) == .akquise)
        // Gebuchte Zeit → mindestens Planung (es wird nachweislich gearbeitet).
        #expect(ProjectLifecycleDeriver.derive(timeBookedHours: 3.5, isArchived: false) == .planung)
        // Archiviert gewinnt immer.
        #expect(ProjectLifecycleDeriver.derive(timeBookedHours: 0, isArchived: true) == .abschluss)
        #expect(ProjectLifecycleDeriver.derive(timeBookedHours: 99, isArchived: true) == .abschluss)
    }
}
