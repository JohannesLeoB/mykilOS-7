// swift-tools-version: 5.10
import PackageDescription

// mykilOS 6 — Akt 2: GRDB als Core-Wahrheit kommt rein.
// Jede Schicht bleibt ihr eigenes Target; Views können keinen DB-Code importieren.
let package = Package(
    name: "mykilOS6",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "mykilOS6", targets: ["MykilosApp"])
    ],
    dependencies: [
        // GRDB — SQLite, sauber, schnell, kein ORM-Overkill.
        // Pat: eine Datei, eine Wahrheit, relationale Queries, typsicher.
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
    ],
    targets: [
        // Kern — plattformneutral, KEIN SwiftUI, KEIN GRDB
        .target(name: "MykilosKit",
                path: "Sources/MykilosKit"),

        // Kalkulations-Kern — verbatim aus mykilO$$ portiert, NUR Foundation.
        // Reiner Schätz-/Kostenboden-Kern; GRDB-Adapter leben in MykilosServices.
        .target(name: "MykilosKalkulationsCore",
                path: "Sources/MykilosKalkulationsCore"),

        // Design-Tokens — nur SwiftUI
        .target(name: "MykilosDesign",
                dependencies: ["MykilosKit"],
                path: "Sources/MykilosDesign"),

        // Services — hier lebt GRDB. Hält die DB-Logik von Views fern.
        .target(name: "MykilosServices",
                dependencies: [
                    "MykilosKit",
                    "MykilosKalkulationsCore",
                    .product(name: "GRDB", package: "GRDB.swift"),
                ],
                path: "Sources/MykilosServices",
                resources: [.copy("Resources/studio_brain.json")]),

        // Widgets — SwiftUI. NotesWidget braucht NoteStore aus MykilosServices.
        .target(name: "MykilosWidgets",
                dependencies: ["MykilosKit", "MykilosDesign", "MykilosServices"],
                path: "Sources/MykilosWidgets"),

        // App-Shell
        .executableTarget(
            name: "MykilosApp",
            dependencies: ["MykilosKit", "MykilosDesign", "MykilosServices", "MykilosWidgets"],
            path: "Sources/MykilosApp",
            resources: [.copy("Resources")]
        ),

        // Tests
        .testTarget(name: "MykilosKitTests",
                    dependencies: ["MykilosKit"],
                    path: "Tests/MykilosKitTests"),
        .testTarget(name: "MykilosKalkulationsCoreTests",
                    dependencies: ["MykilosKalkulationsCore"],
                    path: "Tests/MykilosKalkulationsCoreTests"),
        .testTarget(name: "MykilosServicesTests",
                    dependencies: [
                        "MykilosServices", "MykilosKit", "MykilosKalkulationsCore",
                        .product(name: "GRDB", package: "GRDB.swift"),
                    ],
                    path: "Tests/MykilosServicesTests"),
        // Tests für MykilosWidgets-eigene, reine Logik (RechnerModel etc.).
        .testTarget(name: "MykilosWidgetsTests",
                    dependencies: ["MykilosWidgets", "MykilosKit", "MykilosDesign"],
                    path: "Tests/MykilosWidgetsTests"),
        // Tests für MykilosApp-eigene Utility-Klassen (MykPDFRenderer etc.).
        // Executable targets können in SPM 5.4+ per @testable importiert werden.
        .testTarget(name: "MykilosAppTests",
                    dependencies: ["MykilosApp"],
                    path: "Tests/MykilosAppTests"),
    ]
)
