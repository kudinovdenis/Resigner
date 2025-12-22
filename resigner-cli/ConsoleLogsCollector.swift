import Foundation
import ResignerLib

final class ConsoleLogsCollectorImpl: ConsoleLogsCollector {
    
    init() {

    }

    func addLog(_ log: String) {
        print(log)
    }

}

