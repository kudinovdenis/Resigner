import ResignerLib

final class Services {

    let filePickerState = FilepickerState()
    var currentAppcontainer: AppContainer?
    let resigner: Resigner
    let consoleLogsCollector: ConsoleLogsCollectorImpl
    let uistate: UIState

    init() throws {
        consoleLogsCollector = ConsoleLogsCollectorImpl()
        resigner = try Resigner.loadPersistentState(consoleLogsCollector: consoleLogsCollector)
        uistate = UIState()
    }

}
