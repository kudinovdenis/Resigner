import ResignerLib
import ArgumentParser

@main
struct ResignCommand: ParsableCommand {

    @Option(help: "Path to binary to resign")
    var binaryPath: String

    func run() throws {
        let consoleLogsCollector = ConsoleLogsCollectorImpl()
        consoleLogsCollector.addLog("Resigning started")
        let resigner = try Resigner.loadPersistentState(consoleLogsCollector: consoleLogsCollector)
        let parser = try resigner.makeAppParser(appPath: binaryPath)
        let appcontainer = try parser.parse()
        try resigner.resign(appcontainer: appcontainer)
        consoleLogsCollector.addLog("Resigning done")
    }

}
