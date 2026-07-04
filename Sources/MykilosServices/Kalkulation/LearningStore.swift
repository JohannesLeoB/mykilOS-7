import Foundation
import GRDB
import MykilosKalkulationsCore

public enum LearningStoreError: Error, CustomStringConvertible {
    case sessionNotFound(String)
    case candidateNotFound(String)
    case factorNotFound(String)

    public var description: String {
        switch self {
        case .sessionNotFound(let id): "Estimate session nicht gefunden: \(id)"
        case .candidateNotFound(let id): "CalibrationFactorCandidate nicht gefunden: \(id)"
        case .factorNotFound(let id): "ActiveCalibrationFactor nicht gefunden: \(id)"
        }
    }
}

public struct LearningSummary: Equatable {
    public let sessions: Int
    public let adjustments: Int
    public let candidates: [CalibrationFactorCandidate]
    public let activeFactors: [ActiveCalibrationFactor]
    public let outliers: Int
}

// MARK: - LearningStore
// Append-only Learning- und Kalibrierungsspeicher. Ab Akt 4A produktiv auf SQLite
// (GRDB) statt JSONL — gleiche öffentliche API, gleiche fachliche Logik. Ein
// vorhandener JSONL-Snapshot im selben Verzeichnis wird beim ersten Zugriff
// verlustfrei und idempotent in die Working Copy importiert.
//
// No-delete: Es gibt keine Lösch-/Update-API. Statusänderungen (promote/deactivate,
// Outlier) sind neue Zeilen; "aktuell" wird über die höchste pk je record_id
// projiziert (latestByID). Der Bundle-Seed wird nie berührt.
public final class LearningStore: CalibrationFactorProviding, @unchecked Sendable {
    public let directory: URL
    private var cachedDatabase: LearningDatabase?
    // Ultra-Review-Fix: der Store wird jetzt aus zwei Isolation-Domains genutzt
    // (MainActor-UI: vormerken/freigeben; KalkulationsEngine-actor: Anker lesen).
    // Der Lock macht die Lazy-Init von `cachedDatabase` atomar (sonst Data Race +
    // doppelter JSONL-Import). GRDB selbst ist danach thread-safe.
    private let dbLock = NSLock()

    public init(directory: URL = LearningStore.defaultDirectory()) {
        self.directory = directory
    }

    public static func defaultDirectory() -> URL {
        if let override = ProcessInfo.processInfo.environment["MYKILOS_LEARNING_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return support.appendingPathComponent("MYKILOS/Kalkulationslabor/Learning", isDirectory: true)
    }

    /// Öffnet die Working-Copy-DB lazy und importiert einmalig vorhandene JSONL-Daten.
    public func database() throws -> LearningDatabase {
        dbLock.lock()
        defer { dbLock.unlock() }
        if let cachedDatabase { return cachedDatabase }
        let db = try LearningDatabase(url: directory.appendingPathComponent("learning.sqlite"))
        _ = try db.importJSONLSnapshot(from: directory)
        cachedDatabase = db
        return db
    }

    // MARK: Writes

    public func saveSession(from result: EstimateResult) throws -> EstimateSession {
        let db = try database()
        let session = EstimateSession(
            requestText: result.request.rawText,
            baseLowNet: result.baseTotalBand.low,
            baseMidNet: result.baseTotalBand.expected,
            baseHighNet: result.baseTotalBand.high,
            laborValueNet: result.baseLaborValue,
            evidenceIDs: result.evidence.map(\.priceAnchorID)
        )
        let components: [EstimateSessionComponent] = result.lines.enumerated().map { index, line in
            EstimateSessionComponent(
                sessionID: session.id,
                componentIndex: index,
                componentClass: line.component.componentClass,
                componentType: line.component.type,
                adjustmentTarget: Self.target(for: line.component),
                baseLowNet: line.priceBand.low,
                baseMidNet: line.priceBand.expected,
                baseHighNet: line.priceBand.high,
                evidenceIDs: line.evidence.map(\.priceAnchorID)
            )
        }
        // Eine Transaktion über Session, Komponenten und Audit.
        try db.write { conn in
            try db.insert(session, conn)
            for component in components { try db.insert(component, conn) }
            try db.insert(LearningAuditLogEntry(entityID: session.id, entityTable: "estimate_sessions", action: "created", message: "Estimate session captured append-only."), conn)
        }
        return session
    }

    public func appendAdjustment(sessionID: String, percentDelta: Double, euroDelta: Decimal?, reason: EstimateAdjustmentReason, target: EstimateAdjustmentTarget, learn: Bool, note: String = "") throws -> EstimateAdjustment {
        let db = try database()
        return try db.write { conn in
            guard let session = try db.sessions(conn).last(where: { $0.id == sessionID }) else {
                throw LearningStoreError.sessionNotFound(sessionID)
            }
            let basis = try Self.baseMidNet(db, conn, session: session, target: target)
            let adjustedMid = euroDelta.map { basis + $0 } ?? (basis * Decimal(1 + percentDelta / 100))
            let inferredPercent = NSDecimalNumber(decimal: basis == 0 ? Decimal(percentDelta) : ((adjustedMid - basis) / basis * Decimal(100))).doubleValue
            let status: LearningRecordStatus = abs(inferredPercent) > 25 ? .reviewOutlier : .active
            let adjustment = EstimateAdjustment(
                sessionID: sessionID,
                percentDelta: inferredPercent,
                euroDelta: euroDelta,
                adjustedMidNet: adjustedMid,
                reason: reason,
                target: target,
                status: status,
                note: note
            )
            try db.insert(adjustment, conn)

            let matchingComponents = try db.sessionComponents(conn)
                .filter { $0.sessionID == sessionID && (target == .wholeEstimate || $0.adjustmentTarget == target) }
            if matchingComponents.isEmpty {
                try db.insert(EstimateAdjustmentComponentTarget(adjustmentID: adjustment.id, sessionComponentID: nil, target: target, percentDelta: inferredPercent, status: status), conn)
            } else {
                for component in matchingComponents {
                    try db.insert(EstimateAdjustmentComponentTarget(adjustmentID: adjustment.id, sessionComponentID: component.id, target: target, percentDelta: inferredPercent, status: status), conn)
                }
            }
            try db.insert(LearningAuditLogEntry(entityID: adjustment.id, entityTable: "estimate_adjustments", action: learn ? "learning_saved" : "estimate_adjusted", message: "Adjustment stored with status \(status.rawValue)."), conn)
            if learn {
                try Self.regenerateCandidate(db, conn, reason: reason, target: target)
            }
            return adjustment
        }
    }

    public func promoteCalibration(candidateID: String) throws -> ActiveCalibrationFactor {
        let db = try database()
        return try db.write { conn in
            guard let candidate = try Self.latestByID(db.candidates(conn)).last(where: { $0.id == candidateID }) else {
                throw LearningStoreError.candidateNotFound(candidateID)
            }
            let factor = ActiveCalibrationFactor(
                candidateID: candidate.id,
                reason: candidate.reason,
                target: candidate.target,
                multiplier: candidate.multiplier,
                weightedPercentDelta: candidate.weightedPercentDelta,
                sampleCount: candidate.sampleCount
            )
            try db.insert(factor, conn)
            let promoted = CalibrationFactorCandidate(
                id: candidate.id,
                createdAt: Date(),
                reason: candidate.reason,
                target: candidate.target,
                sampleCount: candidate.sampleCount,
                weightedPercentDelta: candidate.weightedPercentDelta,
                multiplier: candidate.multiplier,
                adjustmentIDs: candidate.adjustmentIDs,
                status: .promoted,
                note: "Promoted to active factor \(factor.id)."
            )
            try db.insert(promoted, conn)
            try db.insert(LearningAuditLogEntry(entityID: factor.id, entityTable: "active_calibration_factors", action: "promoted", message: "Candidate \(candidate.id) promoted."), conn)
            return factor
        }
    }

    public func deactivateCalibration(factorID: String) throws -> ActiveCalibrationFactor {
        let db = try database()
        return try db.write { conn in
            guard let factor = try Self.latestByID(db.factors(conn)).last(where: { $0.id == factorID }) else {
                throw LearningStoreError.factorNotFound(factorID)
            }
            let inactive = ActiveCalibrationFactor(
                id: factor.id,
                candidateID: factor.candidateID,
                createdAt: Date(),
                reason: factor.reason,
                target: factor.target,
                multiplier: factor.multiplier,
                weightedPercentDelta: factor.weightedPercentDelta,
                sampleCount: factor.sampleCount,
                status: .inactive
            )
            try db.insert(inactive, conn)
            try db.insert(LearningAuditLogEntry(entityID: factor.id, entityTable: "active_calibration_factors", action: "deactivated", message: "Factor set inactive append-only."), conn)
            return inactive
        }
    }

    // MARK: Reads

    public func summary() throws -> LearningSummary {
        let adjustments = try estimateAdjustments()
        return LearningSummary(
            sessions: try estimateSessions().count,
            adjustments: adjustments.count,
            candidates: try latestCandidates(),
            activeFactors: try activeCalibrationFactors(),
            outliers: adjustments.filter { $0.status == .reviewOutlier }.count
        )
    }

    public func activeCalibrationFactors() throws -> [ActiveCalibrationFactor] {
        Self.latestByID(try database().factors())
            .filter { $0.status == .active }
    }

    public func estimateSessions() throws -> [EstimateSession] {
        try database().sessions()
    }

    public func estimateSessionComponents() throws -> [EstimateSessionComponent] {
        try database().sessionComponents()
    }

    public func estimateAdjustments() throws -> [EstimateAdjustment] {
        try database().adjustments()
    }

    public func latestCandidates() throws -> [CalibrationFactorCandidate] {
        Self.latestByID(try database().candidates())
    }

    // MARK: Fachliche Hilfslogik (unverändert gegenüber JSONL-Variante)

    private static func regenerateCandidate(_ db: LearningDatabase, _ conn: Database, reason: EstimateAdjustmentReason, target: EstimateAdjustmentTarget) throws {
        let similar = try db.adjustments(conn)
            .filter { $0.reason == reason && $0.target == target && $0.status == .active && abs($0.percentDelta) <= 25 }
        guard similar.count >= 3 else { return }
        let weightSum = similar.map { $0.reason.weight }.reduce(0, +)
        let weightedPercent = similar.map { $0.percentDelta * $0.reason.weight }.reduce(0, +) / max(weightSum, 0.01)
        let status: LearningRecordStatus = similar.count >= 5 ? .strongCandidate : .candidate
        let id = "CAL-\(reason.rawValue)-\(target.rawValue)"
        let multiplier = Decimal(1 + weightedPercent / 100)
        let candidate = CalibrationFactorCandidate(
            id: id,
            reason: reason,
            target: target,
            sampleCount: similar.count,
            weightedPercentDelta: weightedPercent,
            multiplier: multiplier,
            adjustmentIDs: similar.map(\.id),
            status: status,
            note: "\(similar.count) ähnliche Adjustments, weighted by reason reliability."
        )
        try db.insert(candidate, conn)
        try db.insert(LearningAuditLogEntry(entityID: candidate.id, entityTable: "calibration_factor_candidates", action: status.rawValue, message: "Candidate regenerated from \(similar.count) adjustments."), conn)
    }

    private static func baseMidNet(_ db: LearningDatabase, _ conn: Database, session: EstimateSession, target: EstimateAdjustmentTarget) throws -> Decimal {
        if target == .wholeEstimate { return session.baseMidNet }
        let components = try db.sessionComponents(conn).filter { $0.sessionID == session.id && $0.adjustmentTarget == target }
        let sum = components.map(\.baseMidNet).reduce(Decimal(0), +)
        return sum > 0 ? sum : session.baseMidNet
    }

    private static func latestByID<T: Identifiable>(_ records: [T]) -> [T] where T.ID == String {
        var order: [String] = []
        var latest: [String: T] = [:]
        for record in records {
            if latest[record.id] == nil { order.append(record.id) }
            latest[record.id] = record
        }
        return order.compactMap { latest[$0] }
    }

    private static func target(for component: EstimateComponent) -> EstimateAdjustmentTarget {
        if component.type == .drawerAddon || component.drawerCount > 0 { return .drawers }
        switch component.componentClass {
        case .kitchenRun: return .kitchenRun
        case .island: return .island
        case .tallCabinetBlock: return .tallCabinetBlock
        case .worktopSurface: return .worktop
        case .logistics: return .logistics
        default: return .wholeEstimate
        }
    }
}
