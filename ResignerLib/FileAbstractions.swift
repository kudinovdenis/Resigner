import Foundation

public protocol Item {

    var url: URL { get }

}

extension Item {

    var fileManager: FileManager {
        return .default
    }

}

extension Item {

    var name: String {
        return url.lastPathComponent
    }

}

public class File: Item {

    public let url: URL

    init(url: URL) throws {
        self.url = url
    }

}

public class Directory: Item {

    public let url: URL

    init(url: URL) throws {
        self.url = url
    }

}

//

public final class Entitlements: File {

    enum Error: Swift.Error {
        case notRepresentableAsDictionary
    }

    public let content: [String: Any]
    public let teamIdentifier: String
    public let shortBundleIdentifier: String
    public let longBundleIdentifier: String

    override init(url: URL) throws {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        guard let dict = NSDictionary.init(contentsOf: url) as? [String: Any] else {
            throw Error.notRepresentableAsDictionary
        }
        content = dict

        longBundleIdentifier = (content["application-identifier"] as? String) ?? "unknown"

        var teamIdentifier: String = ""
        var shortBundleIdentifier: String = ""

        var teamIdFinished = false
        for char in longBundleIdentifier {
            if char == "." && !teamIdFinished {
                teamIdFinished = true
                continue
            }
            if teamIdFinished {
                shortBundleIdentifier.append(char)
            }
            else {
                teamIdentifier.append(char)
            }
        }

        self.teamIdentifier = teamIdentifier
        self.shortBundleIdentifier = shortBundleIdentifier

        try super.init(url: url)
    }

}

public final class ProvisinoingProfile: File {

    enum Error: Swift.Error {
        case noFile
        case noPlistData
        case unableToConvert
    }

    public let content: [String: Any]

    public var bundleIdentifier: String {
        let entitlementsDict = (content["Entitlements"] as? [String: Any]) ?? [:]
        var longBundleId = (entitlementsDict["application-identifier"] as? String) ?? "unknown"
        longBundleId.replace(teamIdentifier, with: "")
        longBundleId.removeFirst()
        return longBundleId
    }

    public var teamIdentifier: String {
        return ((content["TeamIdentifier"] as? [String]) ?? ["unknown"])[0]
    }

    override init(url: URL) throws {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        let path = url.path
        guard let data = FileManager.default.contents(atPath: path) else {
            throw Error.noFile
        }

        guard
            let start = data.firstRange(of: "<?xml".data(using: .utf8)!),
            let end = data.lastRange(of: "</dict>".data(using: .utf8)!)
        else {
            fatalError()
        }

        var plistData = data[start.lowerBound..<end.upperBound]
        plistData.append("</plist>".data(using: .utf8)!)

        do {
            let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
            content = (plist as? [String: Any]) ?? [:]
        } catch {
            throw error
        }
        try super.init(url: url)
    }

}

//

public final class InfoPlist: File {

    public let content: [String: Any]
    public let bundleId: String
    public let executableName: String
    public let teamId: String?

    override init(url: URL) throws {
        guard let dict = NSDictionary.init(contentsOf: url) else {
            fatalError("Missing file: \(url.path)")
        }
        content = dict as! [String : Any]
        bundleId = (content["CFBundleIdentifier"] as? String) ?? "Unknown"
        executableName = (content["CFBundleExecutable"] as? String) ?? "Unknown"
        var teamId = (content["AppIdentifierPrefix"] as? String)
        teamId?.removeLast()
        self.teamId = teamId
        try super.init(url: url)
    }

}

public final class MachOBinary: File {

    public var entitlements: [String: Any] = [:]

    convenience init(url: URL, shellExecutor: ShellExecutable) throws {
        try self.init(url: url)

        let result = shellExecutor.execute(["codesign",  "-d", "--entitlements", ":-", "\(url.path)", "-vvv"])

        let components = result.split(separator: "<?xml")
        if components.count == 2 {
            var xmlString = components[1]
            xmlString = "<?xml" + xmlString

            let parsedRaw = try! PropertyListSerialization.propertyList(from: xmlString.data(using: .utf8)!, format: nil)
            let parsedDict = parsedRaw as? [String : Any]

            entitlements = parsedDict ?? [:]
        }
    }

}

public protocol MachOContainer {

    var binary: MachOBinary { get }
    var infoPlist: InfoPlist { get }
    var url: URL { get }

}

//

public class Framework: Directory, MachOContainer {

    public let binary: MachOBinary
    public let infoPlist: InfoPlist

    init(url: URL, shellExecutor: ShellExecutable) throws {
        let plistUrl = url.appending(path: "Info.plist")
        self.infoPlist = try InfoPlist(url: plistUrl)

        let binaryUrl = url.appending(path: infoPlist.executableName)
        self.binary = try MachOBinary(url: binaryUrl, shellExecutor: shellExecutor)

        try super.init(url: url)
    }

}

public final class Extension: AppContainer {

}

public final class Plugin: AppContainer {

}

public class AppContainer: Directory, MachOContainer {

    public var frameworks: [Framework] = []
    public var extensions: [Extension] = []
    public var plugins: [Plugin] = []
    public var watch: [WatchKitApp] = []

    public let binary: MachOBinary
    public let infoPlist: InfoPlist

    init(url: URL, shellExecutor: ShellExecutable) throws {
        let plistUrl = url.appending(path: "Info.plist")
        self.infoPlist = try InfoPlist(url: plistUrl)

        let binaryUrl = url.appending(path: infoPlist.executableName)
        self.binary = try MachOBinary(url: binaryUrl, shellExecutor: shellExecutor)

        try super.init(url: url)

        // Frameworks

        let frameworksPath = url.appending(path: "Frameworks")
        if fileManager.fileExists(atPath: frameworksPath.path) {
            let content = try fileManager.contentsOfDirectory(atPath: frameworksPath.path)
            for entry in content {
                let frameworkPath = frameworksPath.appending(path: entry)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: frameworkPath.path, isDirectory: &isDirectory) else {
                    continue
                }

                guard isDirectory.boolValue else {
                    continue
                }

                let framework = try Framework(url: frameworkPath, shellExecutor: shellExecutor)

                frameworks.append(framework)
            }
        }

        // Plugins

        let pluginsPath = url.appending(path: "PlugIns")
        if fileManager.fileExists(atPath: pluginsPath.path) {
            let content = try fileManager.contentsOfDirectory(atPath: pluginsPath.path)
            for entry in content {
                let pluginPath = pluginsPath.appending(path: entry)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: pluginPath.path, isDirectory: &isDirectory) else {
                    continue
                }

                guard isDirectory.boolValue else {
                    continue
                }

                let plugin = try Plugin(url: pluginPath, shellExecutor: shellExecutor)

                plugins.append(plugin)
            }
        }

        // Extensions

        let extensionsPath = url.appending(path: "Extensions")
        if fileManager.fileExists(atPath: extensionsPath.path) {
            let content = try fileManager.contentsOfDirectory(atPath: extensionsPath.path)
            for entry in content {
                let extensionPath = extensionsPath.appending(path: entry)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: extensionPath.path, isDirectory: &isDirectory) else {
                    continue
                }

                guard isDirectory.boolValue else {
                    continue
                }

                let `extension` = try Extension(url: extensionPath, shellExecutor: shellExecutor)

                extensions.append(`extension`)
            }
        }

        // Watch

        let watchPath = url.appending(path: "Watch")
        if fileManager.fileExists(atPath: watchPath.path) {
            let content = try fileManager.contentsOfDirectory(atPath: watchPath.path)
            for entry in content {
                let watchBundlePath = watchPath.appending(path: entry)

                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: watchBundlePath.path, isDirectory: &isDirectory) else {
                    continue
                }

                guard isDirectory.boolValue else {
                    continue
                }

                let watchKitApp = try WatchKitApp(url: watchBundlePath, shellExecutor: shellExecutor)

                watch.append(watchKitApp)
            }
        }
    }

}

public class WatchKitApp: AppContainer {

}
