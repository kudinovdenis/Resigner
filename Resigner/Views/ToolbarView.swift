import SwiftUI
import ResignerLib

struct ToolbarView: View {

    @State private var isSettingsPresented = false
    private let consoleLogsCollector: ConsoleLogsCollector
    private let filePickerState: FilepickerState
    private let resigner: Resigner
    private let uistate: UIState
    private let services: Services // use only for current app container

    init(consoleLogsCollector: ConsoleLogsCollector, filePickerState: FilepickerState, resigner: Resigner, uistate: UIState, services: Services) {
        self.consoleLogsCollector = consoleLogsCollector
        self.filePickerState = filePickerState
        self.resigner = resigner
        self.uistate = uistate
        self.services = services
    }

    var body: some View {
        HStack {
            Button(action: {
                consoleLogsCollector.addLog("Open file")
                filePickerState.isFileImporterPresented = true
            }) {
                Image(systemName: "folder.badge.plus")
            }
            .help("Open app")

            Button(action: {
                do {
                    try resigner.savePersistentState()
                }
                catch {
                    consoleLogsCollector.addLog("Failed with error: \(error)")
                }
            }) {
                Image(systemName: "square.and.arrow.down")
            }
            .help("Save resigner state (profiles and entitlements paths")

            VStack {
                Button(action: {
                    guard let app = services.currentAppcontainer else {
                        consoleLogsCollector.addLog("No current app")
                        return
                    }
                    do {
                        try resigner.resign(appcontainer: app)
                    }
                    catch  {
                        consoleLogsCollector.addLog("Failed to resign: \(error)")
                    }
                }) {
                    Image(systemName: "play")
                }
                Text("Resign")
            }
            .buttonStyle(PlainButtonStyle())
            .help("Start resigning process")

            Spacer()

            Button(action: {
                consoleLogsCollector.addLog("Console switch")
                uistate.isConsoleOpened.toggle()
            }) {
                Image(systemName: "apple.terminal")
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                consoleLogsCollector.addLog("Settings")
                isSettingsPresented = true
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $isSettingsPresented) {
            Text("WIP")
        }
    }

}
