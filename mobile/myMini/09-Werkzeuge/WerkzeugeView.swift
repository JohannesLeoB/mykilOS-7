import SwiftUI

/// Sammelstelle für eigenständige Vor-Ort-Werkzeuge, die keine Postbox,
/// keinen Sync und kein Projekt brauchen — nur Kamera/Sensor + sofortige
/// Antwort. Wächst mit weiteren Bausteinen (z. B. Barcode-Scanner).
/// Das Abnahmeprotokoll ist die eine Ausnahme, die ein Projekt braucht
/// (deshalb der `store`-Parameter) — es lebt trotzdem hier und nicht in der
/// Fang-Karte, weil es mit Diktat statt Kamera-Tipp beginnt.
struct WerkzeugeView: View {
    let store: ProjectStore
    let feldFotoStore: FeldFotoStore
    @State private var barcodeLog = BarcodeLogStore()
    @State private var roomPlanStore = RoomPlanStore()

    var body: some View {
        List {
            NavigationLink {
                BeleuchtungsCheckView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Beleuchtungs-Check")
                        Text("Foto → Helligkeit einschätzen")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "sun.max.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                BarcodeLogListView(logStore: barcodeLog)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Barcode/QR-Scanner")
                        Text("Rohdaten-Log, kein WorkBasket-Abgleich")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "barcode.viewfinder").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                WasserwaageView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wasserwaage")
                        Text("Gyroskop-Neigungsmesser")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "level").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                FarbtemperaturCheckView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Farbtemperatur-Check")
                        Text("Warm/Neutral/Kühl — grobe Schätzung, kein Kelvin")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "paintpalette.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                RaumakustikCheckView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Raumakustik-Check")
                        Text("Grobe Lautstärke, keine Nachhallzeit")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "waveform").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                AbnahmeprotokollView(store: store)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abnahmeprotokoll")
                        Text("Diktat + Foto, nummeriert je Projekt")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "list.number").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                KreativStudioView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kreativ-Studio · Firefly")
                        Text("Bestandsfoto + Stil → Render-Prompt")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "wand.and.stars").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                SonnenverlaufView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sonnenverlauf")
                        Text("Wo steht die Sonne? Licht- & Fensterplanung")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "sun.and.horizon.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                FotoBemassungView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Foto-Bemaßung · Stift")
                        Text("Maßlinien + Maßzahlen ins Foto einbrennen")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "pencil.and.ruler.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                ARMassbandScreen()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AR-Maßband")
                        Text("Zwei Punkte antippen, Distanz sehen")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "arkit").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                ARAnkerScreen(store: store, feldFotoStore: feldFotoStore)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AR-Anker · Gewerke")
                        Text("Wasser/Strom/Abfluss im Raum markieren")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "mappin.and.ellipse").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                VertragSignierenView(store: store)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vertrag signieren")
                        Text("Geführt: PDF + Unterschrift + SHA-256-Siegel")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "signature").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                ServiceAnfrageView(store: store, feldFotoStore: feldFotoStore)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Service-Anfrage")
                        Text("Vorbefüllte Mail an den Servicepartner")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "wrench.adjustable.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                AnleitungenView(store: store)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Geräte-Anleitungen")
                        Text("PDFs je Projekt, immer offline dabei")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "book.closed.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                PlanModellView(store: store)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planmodelle · AR")
                        Text("USDZ aus VectorWorks im Raum zeigen")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "cube.fill").foregroundStyle(MykColor.brand)
                }
            }
            NavigationLink {
                RoomPlanCaptureScreen(store: store, roomPlanStore: roomPlanStore)
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RoomPlan-Aufmaß")
                        Text("Raum scannen (braucht LiDAR)")
                            .font(.caption)
                            .foregroundStyle(MykColor.muted)
                    }
                } icon: {
                    Image(systemName: "cube.transparent.fill").foregroundStyle(MykColor.brand)
                }
            }
            if !roomPlanStore.aufnahmen.isEmpty {
                NavigationLink {
                    RoomPlanListView(roomPlanStore: roomPlanStore, store: store)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Raumscans")
                            Text("\(roomPlanStore.aufnahmen.count) gespeichert")
                                .font(.caption)
                                .foregroundStyle(MykColor.muted)
                        }
                    } icon: {
                        Image(systemName: "cube.transparent").foregroundStyle(MykColor.brand)
                    }
                }
            }
        }
        .navigationTitle("Werkzeuge")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WerkzeugeView(store: ProjectStore(), feldFotoStore: FeldFotoStore())
    }
}
