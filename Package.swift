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

        // Design-Tokens — nur SwiftUI
        .target(name: "MykilosDesign",
                dependencies: ["MykilosKit"],
                path: "Sources/MykilosDesign"),

        // Services — hier lebt GRDB. Hält die DB-Logik von Views fern.
        .target(name: "MykilosServices",
                dependencies: [
                    "MykilosKit",
                    .product(name: "GRDB", package: "GRDB.swift"),
                ],
                path: "Sources/MykilosServices"),

        // Widgets — SwiftUI, kein GRDB
        .target(name: "MykilosWidgets",
                dependencies: ["MykilosKit", "MykilosDesign"],
                path: "Sources/MykilosWidgets"),

        // App-Shell
        .executableTarget(
            name: "MykilosApp",
            dependencies: ["MykilosKit", "MykilosDesign", "MykilosServices", "MykilosWidgets"],
            path: "Sources/MykilosApp"
        ),

        // Tests
        .testTarget(name: "MykilosKitTests",
                    dependencies: ["MykilosKit"],
                    path: "Tests/MykilosKitTests"),
        .testTarget(name: "MykilosServicesTests",
                    dependencies: [
                        "MykilosServices", "MykilosKit",
                        .product(name: "GRDB", package: "GRDB.swift"),
                    ],
                    path: "Tests/MykilosServicesTests"),
    ]
)
