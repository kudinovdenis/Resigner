import SwiftUI

@main
struct ResignerApp: App {

    let services: Services

    init() {
        services = try! Services()
    }

    var body: some Scene {
        Window("title", id: UUID().uuidString) {
            MainAppView(services: services)
        }
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
                        print("Error: \(error)")
                    }
                }
                .keyboardShortcut("s")

                Button("Resign") {
                    do {
                        if let appcontainer = services.currentAppcontainer {
                            try services.resigner.resign(appcontainer: appcontainer)
                        }
                    }
                    catch {
                        print("Error: \(error)")
                    }
                }
                .keyboardShortcut("r")
            }
        }
    }
}
