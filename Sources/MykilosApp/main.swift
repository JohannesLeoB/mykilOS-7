import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

@main
struct MykilOS6App: App {
    @State private var appState = AppState(database: AppDatabase.production)
    @State private var context  = StudioContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(context)
                .task { await appState.bootstrap() }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1340, height: 860)
        .commands { AppCommands() }
    }
}

// MARK: - AppModule
enum AppModule: String, CaseIterable, Identifiable {
    case today      = "Heute"
    case projects   = "Projekte"
    case assistant  = "Assistent"
    case brands     = "Marken & Daten"
    case offers     = "Angebote"
    case settings   = "Einstellungen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .today:     "sun.min"
        case .projects:  "square.grid.2x2"
        case .assistant: "sparkles"
        case .brands:    "building.2"
        case .offers:    "doc.text"
        case .settings:  "gearshape"
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var module: AppModule = .today
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $module)
            Divider().overlay(MykColor.line.color)
            moduleView
        }
        .background(MykColor.paper.color)
    }

    @ViewBuilder
    private var moduleView: some View {
        switch module {
        case .today:     TodayView()
        case .projects:  ProjectGalleryView()
        case .assistant: AssistantPlaceholderView()
        default:         ComingSoonView(module: module)
        }
    }
}

struct AssistantPlaceholderView: View {
    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
            VStack(spacing: MykSpace.s5) {
                Image(systemName: "sparkles").font(.mykDisplay).foregroundStyle(MykColor.faint.color)
                Text("Assistent — kommt in Akt 4").font(.mykBody).foregroundStyle(MykColor.muted.color)
            }
        }
    }
}

struct ComingSoonView: View {
    let module: AppModule
    var body: some View {
        ZStack {
            MykColor.paper.color.ignoresSafeArea()
            Text("\(module.rawValue) — kommt in einem späteren Akt")
                .font(.mykBody).foregroundStyle(MykColor.muted.color)
        }
    }
}

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
    }
}
