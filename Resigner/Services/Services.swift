import ResignerLib

final class Services {

    let filePickerState = FilepickerState()
    var currentAppcontainer: AppContainer?
    let resigner: Resigner

    init() throws {
        self.resigner = try Resigner.loadPersistentState()
    }

}
