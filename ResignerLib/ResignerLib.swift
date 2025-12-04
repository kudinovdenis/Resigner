import Foundation

public final class SigningInfoStorage: Codable {

    public class SigningInfo: Codable {

        public var newEntitlementsFileUrl: URL? = nil
        public var newProvisioningProfileFileUrl: URL? = nil

        public init() {

        }

    }

    public var bundleIdToSigningInfo: [String: SigningInfo] = [:]

}

public final class Resigner: Codable {

    enum Error: Swift.Error {
        case mismatchIdentifiers
        case noSigningInfo
        case unknownContainerType
    }

    public let signingInfoStorage: SigningInfoStorage

    public init() {
        signingInfoStorage = SigningInfoStorage()
    }

    public func savePersistentState() throws {
        let encoded = try JSONEncoder().encode(self)
        let appSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let persistentStorageFileUrl = appSupportUrl.appending(path: "ps")
        _ = persistentStorageFileUrl.startAccessingSecurityScopedResource()
        defer { persistentStorageFileUrl.stopAccessingSecurityScopedResource() }
        try encoded.write(to: persistentStorageFileUrl)
    }

    public static func loadPersistentState() throws -> Resigner {
        let decoder = JSONDecoder()
        let appSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let persistentStorageFileUrl = appSupportUrl.appending(path: "ps")
        _ = persistentStorageFileUrl.startAccessingSecurityScopedResource()
        defer { persistentStorageFileUrl.stopAccessingSecurityScopedResource() }

        guard let content = FileManager.default.contents(atPath: persistentStorageFileUrl.path) else {
            return .init()
        }

        let resigner = try decoder.decode(Resigner.self, from: content)
        return resigner
    }

    func makeParser(appPath: String) throws -> AppParser {
        return try AppParser(appPath: appPath)
    }

    public func checkProvisioningProfile(profile url: URL, for appcontainer: AppContainer) throws {
        let profile = try ProvisinoingProfile(url: url)
        let identifier = profile.bundleIdentifier

        var valid = true
        valid = valid && (identifier == appcontainer.infoPlist.bundleId)
        if let teamIdentifier = appcontainer.infoPlist.teamId {
            valid = valid && (profile.teamIdentifier == teamIdentifier)
        }

        if !valid {
            throw Error.mismatchIdentifiers
        }
    }

    public func checkEntitlements(entitlements url: URL, for appcontainer: AppContainer) throws {
        let entitlements = try Entitlements(url: url)
        let identifier = entitlements.shortBundleIdentifier

        var valid = true
        valid = valid && (identifier == appcontainer.infoPlist.bundleId)
        if let teamIdentifier = appcontainer.infoPlist.teamId {
            valid = valid && (entitlements.teamIdentifier == teamIdentifier)
        }

        if !valid {
            throw Error.mismatchIdentifiers
        }
    }

    public func resign(appcontainer: AppContainer) throws {
        let certificateName = "Apple Development: Denis Kudinov (AV8NQCTK49)"
        let processExecutor = ShellExecutable()

        for watch in appcontainer.watch {
            try resign(appcontainer: watch)
        }

        for plugin in appcontainer.plugins {
            try resign(appcontainer: plugin)
        }

        for `extension` in appcontainer.extensions {
            try resign(appcontainer: `extension`)
        }

        for framework in appcontainer.frameworks {
            // resign
            // dylibs???
            try removeCodeSignDir(relatedTo: framework)
            try signBinary(framework, certificateName: certificateName, processExecutor: processExecutor)
        }

        try removeCodeSignDir(relatedTo: appcontainer)
        try signBinary(appcontainer, certificateName: certificateName, processExecutor: processExecutor)
    }

    private func removeCodeSignDir(relatedTo: MachOContainer) throws {
        let codeSignatureDirUrl = relatedTo.url.appending(components: "_CodeSignature")
        try FileManager.default.removeItem(at: codeSignatureDirUrl)
    }

    private func signBinary(_ container: MachOContainer, certificateName: String, processExecutor: ShellExecutable) throws {
        let bundleId = container.infoPlist.bundleId

        let cmd: [String]
        if let framework = container as? Framework {
            cmd = ["codesign", "-f", "-s", certificateName, framework.url.path]
        }
        else if let appcontainer = container as? AppContainer {
            guard
                let signingInfo = signingInfoStorage.bundleIdToSigningInfo[bundleId],
                let provisioningProfile = signingInfo.newProvisioningProfileFileUrl,
                let entitlements = signingInfo.newEntitlementsFileUrl
            else {
                throw Error.noSigningInfo
            }

            let provisioningProfileDestination = container.url.appending(path: "embedded.mobileprovision")
            if FileManager.default.fileExists(atPath: provisioningProfileDestination.path) {
                try FileManager.default.removeItem(at: provisioningProfileDestination)
            }
            try FileManager.default.copyItem(at: provisioningProfile, to: provisioningProfileDestination)
            cmd = ["codesign", "-f", "-s", certificateName, "--entitlements", entitlements.path, appcontainer.url.path]
        }
        else {
            throw Error.unknownContainerType
        }

        let result = processExecutor.execute(cmd)
        print("Output: \(result)")
    }

}
