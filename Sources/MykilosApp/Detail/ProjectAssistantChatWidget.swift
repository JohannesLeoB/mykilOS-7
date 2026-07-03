import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - ProjectAssistantChatWidget (S25)
// Der volle konversationelle Assistent (AssistantChatView) als kompaktes,
// maximierbares Widget auf der Projekt-Übersicht. Dieselbe Engine, derselbe
// Scope wie der „Assistent"-Tab — der Verlauf ist also identisch, egal ob das
// Gespräch hier im Widget oder im Tab geführt wird.
//
// Kompakt: feste Höhe, eingebetteter Chat. Maximiert: volles Sheet.
// Liest alle Abhängigkeiten aus dem AppState-Environment (App-Layer-Widget),
// damit der Widget-Layer frei von Engine/Keychain bleibt.
struct ProjectAssistantChatWidget: View {
    let projectID: String
    let driveFolderID: String?
    let clickUpListID: String?

    @Environment(AppState.self) private var appState
    @State private var maximized = false

    private static let compactHeight: CGFloat = 360

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MykColor.line.color)
            chat
                .frame(height: Self.compactHeight)
        }
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.paper2.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
        .sheet(isPresented: $maximized) { maximizedSheet }
    }

    // MARK: Header (Titel + Maximieren)

    private var header: some View {
        HStack(spacing: MykSpace.s3) {
            Image(systemName: "sparkles")
                .font(.mykSmall)
                .foregroundStyle(MykColor.ink.color)
            Text("ASSISTENT")
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            Button { maximized = true } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.mykMono(11))
                    .foregroundStyle(MykColor.drive.color)
            }
            .buttonStyle(.plain)
            .help("Assistent maximieren")
            .accessibilityLabel("Assistent maximieren")
        }
        .padding(.horizontal, MykSpace.s5)
        .padding(.vertical, MykSpace.s4)
    }

    // MARK: Eingebetteter Chat (kompakt)

    private var chat: some View { makeChat() }

    // MARK: Maximiertes Sheet

    private var maximizedSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "sparkles").font(.mykBody).foregroundStyle(MykColor.ink.color)
                Text("Assistent").font(.mykHeadline).foregroundStyle(MykColor.ink.color)
                Spacer()
                Button { maximized = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.mykHeadline)
                        .foregroundStyle(MykColor.faint.color)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, MykSpace.s5)
            .padding(.vertical, MykSpace.s4)
            Divider().overlay(MykColor.line.color)
            makeChat()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 760, minHeight: 680)
        .background(MykColor.paper.color)
    }

    // MARK: Chat-Fabrik — eine Quelle für kompakt UND maximiert (identischer Scope/Verlauf)

    private func makeChat() -> AssistantChatView {
        AssistantChatView(
            scope: .project(projectID),
            chatStore: appState.chat,
            engine: appState.conversation,
            isConnected: appState.claudeAuth.status == .connected,
            modelName: (try? appState.claudeAuth.storedCredentials()?.model)
                ?? ClaudeAuthService.defaultModel,
            projects: appState.registry.projects,
            focusedProjectID: projectID,
            focusedDriveFolderID: driveFolderID,
            focusedClickUpListID: clickUpListID,
            profile: appState.profile.profile,
            onCreateContact: { await appState.createContact($0) },
            onCreateDraft: { await appState.createDraft($0) },
            onWriteAirtableContact: { await appState.writeAirtableContact($0) },
            onUploadFileToDrive: { file, targetFolderID in
                guard !targetFolderID.isEmpty else {
                    return .failed("Kein Drive-Ordner für dieses Projekt konfiguriert.")
                }
                return await appState.uploadFileToDrive(file, parentFolderID: targetFolderID)
            },
            onLoadTargetFolders: { await appState.listDriveSubfolders(parentFolderID: $0) },
            onAttachFilesToMailDraft: { await appState.createDraftWithAttachments($0) }
        )
    }
}
