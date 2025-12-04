import SwiftUI
import ResignerLib

struct MainAppView: View {

    let services: Services
    @ObservedObject private var filePickerState: FilepickerState
    @State private var appcontainer: AppContainer?

    init(services: Services) {
        self.services = services
        self.filePickerState = services.filePickerState
    }

    var body: some View {
        VStack {
            if let appcontainer {
                AppTreeView(appcontainer: appcontainer, services: services)
            }
            else {
                Text("Recent:")
                List {
                    Button("one") {}
                    Button("two") {}
                }
                Button("Open new app") {
                    filePickerState.isFileImporterPresented = true
                }
            }

        }
        .padding()
        .fileImporter(isPresented: $filePickerState.isFileImporterPresented,
                      allowedContentTypes: [.application],
                      allowsMultipleSelection: false) { result in
            print("file opened: \(result)")
            switch result {
            case .failure(let error):
                print("Error: \(error)")

            case .success(let urls):
                guard urls.count == 1 else {
                    print("Error: Required only one item")
                    return
                }

                let url = urls[0]
                let resigner = try! AppParser(appPath: url.path)
                appcontainer = try! resigner.parse()
                services.currentAppcontainer = appcontainer
            }
        } onCancellation: {
            print("file open cancelled")
        }
    }
}
