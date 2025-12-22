import Foundation
import ResignerLib

final class ConsoleLogsCollectorImpl: ConsoleLogsCollector, ConsoleViewModel {

    struct LogEntry {
        let line: String
        let timestamp: Date
    }

    @Published var lines: [LogEntry] = []

    init() {

    }

    func addLog(_ log: String) {
        lines.append(LogEntry(line: log, timestamp: Date()))
        print(log)
    }

}

