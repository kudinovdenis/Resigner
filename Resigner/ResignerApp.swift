import SwiftUI

@main
struct ResignerApp: App {

    let services: Services

    init() {
        services = try! Services()
    }

    var body: some Scene {
        Window("Resigner", id: UUID().uuidString) {
            MainAppView(services: services)
        }
        .defaultSize(width: 1000, height: 800)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open...") {
                    services.filePickerState.isFileImporterPresented = true
                }
                .keyboardShortcut("o")

                Button("Save") {
                    do {
                        try services.resigner.savePersistentState()
                    }
                    catch {
                        services.consoleLogsCollector.addLog("Error: \(error)")
                    }
                }
                .keyboardShortcut("s")

                Button("Resign") {
                    do {
                        if let appcontainer = services.currentAppcontainer {
                            try services.resigner.resign(appcontainer: appcontainer)
                            services.consoleLogsCollector.addLog("done")
                        }
                    }
                    catch {
                        services.consoleLogsCollector.addLog("Error: \(error)")
                    }
                }
                .keyboardShortcut("r")
            }
        }
    }
}
