import Foundation

final class ShellExecutable {

    func execute(_ cmd: [String]) -> String {
        print("executing $ \(cmd.joined(separator: " "))")
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
