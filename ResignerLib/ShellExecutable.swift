import Foundation

final class ShellExecutable {

    private let consoleLogsCollector: ConsoleLogsCollector

    init(consoleLogsCollector: ConsoleLogsCollector) {
        self.consoleLogsCollector = consoleLogsCollector
    }

    func execute(_ cmd: [String]) -> String {
        consoleLogsCollector.addLog("executing $ \(cmd.joined(separator: " "))")
        let task = Process()

        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe

        task.launchPath = "/usr/bin/env"
        task.arguments = cmd
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }

}
