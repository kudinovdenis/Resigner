import SwiftUI
import ResignerLib

struct MainAppView: View {

    let services: Services
    @ObservedObject private var filePickerState: FilepickerState
    @ObservedObject private var uistate: UIState
    @State private var appcontainer: AppContainer?

    init(services: Services) {
        self.services = services
        self.filePickerState = services.filePickerState
        self.uistate = services.uistate
    }

    var body: some View {
        VStack {
            ToolbarView(consoleLogsCollector: services.consoleLogsCollector,
                        filePickerState: filePickerState,
                        resigner: services.resigner,
                        uistate: uistate,
                        services: services)
            VSplitView {
                if let appcontainer {
                    AppTreeView(appcontainer: appcontainer, services: services)
                        .frame(maxWidth: .infinity)
                }
                else {
                    VStack {
                        Text("Recent (WIP):")
                        List {
                            Button("one") {}
                            Button("two") {}
                        }
                        Button("Open new app") {
                            filePickerState.isFileImporterPresented = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                if (uistate.isConsoleOpened) {
                    ToolboxView(title: "console") {
                        ConsoleView(vm: services.consoleLogsCollector)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                }
            }
        }
        .padding()
        .fileImporter(isPresented: $filePickerState.isFileImporterPresented,
                      allowedContentTypes: [.application],
                      allowsMultipleSelection: false) { result in
            services.consoleLogsCollector.addLog("file opened: \(result)")
            switch result {
            case .failure(let error):
                services.consoleLogsCollector.addLog("Error: \(error)")

            case .success(let urls):
                guard urls.count == 1 else {
                    services.consoleLogsCollector.addLog("Error: Required only one item")
                    return
                }

                let url = urls[0]
                do {
                    let appParser = try services.resigner.makeAppParser(appPath: url.path)
                    appcontainer = try appParser.parse()
                    services.currentAppcontainer = appcontainer
                }
                catch {
                    services.consoleLogsCollector.addLog("Unable to parse app at path \(url.path) with error: \(error)")
                }
            }
        } onCancellation: {
            services.consoleLogsCollector.addLog("file open cancelled")
        }
    }
}
