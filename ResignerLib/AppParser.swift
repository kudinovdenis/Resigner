import Foundation

public final class AppParser {

    enum Error: Swift.Error {
        case fileNotFound(String)
        case noPermissionsToAccessingResource // check if url string is correct
    }

    let appUrl: URL
    let fileManager = FileManager.default
    let shellExecutor: ShellExecutable

    init(appPath: String, shellExecutor: ShellExecutable) throws {
        appUrl = URL(filePath: appPath, directoryHint: .isDirectory)
        self.shellExecutor = shellExecutor
        guard appUrl.startAccessingSecurityScopedResource() else {
            throw Error.noPermissionsToAccessingResource
        }

        guard fileManager.fileExists(atPath: appUrl.path) else {
            throw Error.fileNotFound(appUrl.path())
        }
    }

    deinit {
//        appUrl.stopAccessingSecurityScopedResource()
    }

    public func parse() throws -> AppContainer {
        try AppContainer(url: appUrl, shellExecutor: shellExecutor)
    }

}
