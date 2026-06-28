import Testing
import Foundation
@testable import MykilosServices

struct GmailCacheStoreTests {

    @Test func cacheHitLiefertGespeicherteMeldungen() async {
        let store = GmailCacheStore(ttl: 60)
        let msg = GoogleGmailMessage(id: "m1", subject: "Test", from: "me@test.de", snippet: "...", receivedAt: nil)
        await store.store([msg], for: "from:gesa")

        let hit = await store.cached(for: "from:gesa")
        #expect(hit?.count == 1)
        #expect(hit?.first?.id == "m1")
    }

    @Test func cacheMissLiefertNil() async {
        let store = GmailCacheStore(ttl: 60)
        let hit = await store.cached(for: "unbekannte-query")
        #expect(hit == nil)
    }

    @Test func abgelaufenerEintragLiefertNil() async {
        let store = GmailCacheStore(ttl: 0)   // TTL = 0 s → sofort abgelaufen
        let msg = GoogleGmailMessage(id: "m2", subject: "Alt", from: "x@y.de", snippet: "", receivedAt: nil)
        await store.store([msg], for: "subject:Alt")

        let hit = await store.cached(for: "subject:Alt")
        #expect(hit == nil)
    }

    @Test func invalidateEntferntEintrag() async {
        let store = GmailCacheStore(ttl: 60)
        let msg = GoogleGmailMessage(id: "m3", subject: "X", from: "a@b.de", snippet: "", receivedAt: nil)
        await store.store([msg], for: "q1")
        await store.store([msg], for: "q2")

        await store.invalidate(query: "q1")
        #expect(await store.cached(for: "q1") == nil)
        #expect(await store.cached(for: "q2") != nil)
    }

    @Test func invalidateAlleLeertCache() async {
        let store = GmailCacheStore(ttl: 60)
        let msg = GoogleGmailMessage(id: "m4", subject: "Y", from: "b@c.de", snippet: "", receivedAt: nil)
        await store.store([msg], for: "q1")
        await store.store([msg], for: "q2")

        await store.invalidate()
        #expect(await store.validEntryCount == 0)
    }
}
