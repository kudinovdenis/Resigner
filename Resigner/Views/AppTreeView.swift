import SwiftUI
import ResignerLib

struct AppTreeView: View {

    let appcontainer: AppContainer
    let services: Services

    @State private var selectedInstance: Item?

    var body: some View {
        HSplitView {
            ToolboxView(title: "Application tree") {
                AppContainerView(appcontainer: appcontainer, selectedInstance: $selectedInstance)
            }
            .frame(minWidth: 100, maxWidth: .infinity, maxHeight: .infinity)

            VSplitView {
                DetailedInformationView(selectedInstance: selectedInstance)
                    .frame(minWidth: 100, idealWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

                SigningInfoView(selectedInstance: selectedInstance, resigner: services.resigner)
                    .frame(minWidth: 100, maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 100, idealWidth: 100, maxHeight: .infinity)
        }
    }

}

struct ToolboxView<Content: View>: View {

    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            Text(title)
                .background(Color.secondary)
            Divider()
            ScrollView {
                content
            }
        }
    }

}

struct DetailedInformationView: View {

    struct DictionaryView<Key: Hashable & CustomStringConvertible, Value: Any>: View {
        let dictionary: [Key: Value]

        var body: some View {
            // Sort the keys for a consistent display order
            ForEach(dictionary.keys.sorted { $0.description < $1.description }, id: \.self) { key in
                HStack {
                    Text(key.description) // Display the key
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(String(describing: dictionary[key]))") // Display the value
                }
            }
        }
    }

    let selectedInstance: Item?

    init(selectedInstance: Item?) {
        self.selectedInstance = selectedInstance
    }

    var body: some View {
        ToolboxView(title: "Detailed view") {
            VStack {
                if let selectedInstance {
                    Text("\(selectedInstance.url.path)")
                    if let appContainer = selectedInstance as? AppContainer {
                        Text("Entitlements:")
                        DictionaryView(dictionary: appContainer.binary.entitlements)
                    }
                }
            }
        }
    }

}

struct SigningInfoView: View {

    struct AppContainerSigningInfoView: View {

        @State private var provisionProfileCheckResult: Result<Void, Error>?
        @State private var entitlementsCheckResult: Result<Void, Error>?

        @State var isProvisioningProfilePickerPresented = false
        @State var isEntitlementPickerPresented = false

        let appcontainer: AppContainer
        let signingInfo: SigningInfoStorage.SigningInfo
        let resigner: Resigner

        init(appcontainer: AppContainer, resigner: Resigner) {
            self.appcontainer = appcontainer
            self.resigner = resigner

            let signingInfoStorage = resigner.signingInfoStorage
            let initialSigningInfo = signingInfoStorage.bundleIdToSigningInfo[appcontainer.infoPlist.bundleId]
            ?? SigningInfoStorage.SigningInfo()
            signingInfoStorage.bundleIdToSigningInfo[appcontainer.infoPlist.bundleId] = initialSigningInfo
            self.signingInfo = initialSigningInfo

            if let url = signingInfo.newEntitlementsFileUrl {
                do {
                    try resigner.checkEntitlements(entitlements: url, for: appcontainer)
                    _entitlementsCheckResult = State(initialValue: .success(()))
                }
                catch {
                    _entitlementsCheckResult = State(initialValue:.failure(error))
                }
            }
            if let url = signingInfo.newProvisioningProfileFileUrl {
                do {
                    try resigner.checkProvisioningProfile(profile: url, for: appcontainer)
                    _provisionProfileCheckResult = State(initialValue:.success(()))
                }
                catch {
                    _provisionProfileCheckResult = State(initialValue:.failure(error))
                }
            }
        }

        var body: some View {
            VStack {
                HStack {
                    Text("New provisioning profile:")
                    if let newProvisioningProfileUrl = signingInfo.newProvisioningProfileFileUrl {
                        HStack {
                            if let provisionProfileCheckResult {
                                switch provisionProfileCheckResult {
                                case .success:
                                    Text("✅")
                                case .failure(let error):
                                    Text("🚨 \(error)")
                                }
                            }
                            Text("selected: \(newProvisioningProfileUrl.path)")
                        }
                    }
                    else {
                        Text("Not selected")
                    }
                    Button("select") {
                        isProvisioningProfilePickerPresented = true
                    }
                    .fileImporter(isPresented: $isProvisioningProfilePickerPresented, allowedContentTypes: [.item]) { result in
                        switch result {
                        case .failure(let error):
                            provisionProfileCheckResult = .failure(error)

                        case .success(let url):
                            signingInfo.newProvisioningProfileFileUrl = url
                            do {
                                try resigner.checkProvisioningProfile(profile: url, for: appcontainer)
                                provisionProfileCheckResult = .success(())
                            }
                            catch {
                                provisionProfileCheckResult = .failure(error)
                            }
                        }
                    }
                }

                HStack {
                    Text("New entitlements:")
                    if let newEntitlementsUrl = signingInfo.newEntitlementsFileUrl {
                        HStack {
                            if let entitlementsCheckResult {
                                switch entitlementsCheckResult {
                                case .success:
                                    Text("✅")
                                case .failure(let error):
                                    Text("🚨 \(error)")
                                }
                            }
                            Text("selected: \(newEntitlementsUrl.path)")
                        }
                    }
                    else {
                        Text("Not selected")
                    }
                    Button("select") {
                        isEntitlementPickerPresented = true
                    }
                    .fileImporter(isPresented: $isEntitlementPickerPresented, allowedContentTypes: [.item]) { result in
                        switch result {
                        case .failure(let error):
                            entitlementsCheckResult = .failure(error)

                        case .success(let url):
                            signingInfo.newEntitlementsFileUrl = url
                            do {
                                try resigner.checkEntitlements(entitlements: url, for: appcontainer)
                                entitlementsCheckResult = .success(())
                            }
                            catch {
                                entitlementsCheckResult = .failure(error)
                            }
                        }
                    }
                }
            }
        }

    }

    let selectedInstance: Item?
    let resigner: Resigner

    init(selectedInstance: Item?, resigner: Resigner) {
        self.selectedInstance = selectedInstance
        self.resigner = resigner
    }

    var body: some View {
        ToolboxView(title: "Signing info") {
            if let appcontainer = selectedInstance as? AppContainer {
                AppContainerSigningInfoView(appcontainer: appcontainer, resigner: resigner)
            }
            else {
                Text("N/A")
            }
        }
    }

}

struct AppContainerView: View {

    let appcontainer: AppContainer
    @Binding var selectedInstance: Item?

    var body: some View {
        VStack(alignment: .leading) {

            DisclosureWithTapHandler(label: {
                disclosureLabel(title: "\(appcontainer.infoPlist.executableName) (\(appcontainer.infoPlist.bundleId))")
            })
            {

                if appcontainer.frameworks.count > 0 {
                    Divider()
                    HStack {
                        Spacer().frame(width: 20)
                        DisclosureWithTapHandler("Frameworks (\(appcontainer.frameworks.count))") {
                            ForEach(appcontainer.frameworks) { framework in
                                singleItemView(framework)
                                    .onTapGesture {
                                        self.selectedInstance = framework
                                    }
                            }
                        }
                    }
                }


                if appcontainer.plugins.count > 0 {
                    Divider()
                    HStack {
                        Spacer().frame(width: 20)
                        VStack(alignment: .leading) {
                            DisclosureWithTapHandler("PlugIns (\(appcontainer.plugins.count))") {
                                ForEach(appcontainer.plugins) { plugin in
                                    singleItemView(plugin)
                                }
                            }
                        }
                    }
                }

                if appcontainer.extensions.count > 0 {
                    Divider()
                    HStack {
                        Spacer().frame(width: 20)
                        VStack(alignment: .leading) {
                            DisclosureWithTapHandler("Extensions (\(appcontainer.extensions.count))") {
                                ForEach(appcontainer.extensions) { `extension` in
                                    singleItemView(`extension`)
                                }
                            }
                        }
                    }
                }

                if appcontainer.watch.count > 0 {
                    Divider()
                    HStack {
                        Spacer().frame(width: 20)
                        VStack(alignment: .leading) {
                            DisclosureWithTapHandler("Watch (\(appcontainer.watch.count))") {
                                ForEach(appcontainer.watch) { watch in
                                    singleItemView(watch)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func disclosureLabel(title: String) -> some View {
        Text(title)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    self.selectedInstance = appcontainer
                }
        )
    }

    func singleItemView(_ item: Item) -> some View {
        HStack {
            Spacer().frame(width: 20)
            if let framework = item as? Framework {
                FrameworkNode(framework: framework)
            }
            else if let plugin = item as? Plugin {
                AppContainerView(appcontainer: plugin, selectedInstance: $selectedInstance)
            }
            else if let `extension` = item as? Extension {
                AppContainerView(appcontainer: `extension`, selectedInstance: $selectedInstance)
            }
            else if let watch = item as? WatchKitApp {
                AppContainerView(appcontainer: watch, selectedInstance: $selectedInstance)
            }
            Spacer()
        }
    }

}

struct DisclosureWithTapHandler<Label, Content> : View where Label : View, Content : View {

    var content: Content
    var label: Label

    @State var isExpanded = false

    init(@ViewBuilder label: () -> Label, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.label = label()
    }

    var body: some View {
        let label = label
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        isExpanded.toggle()
                    }
            )
        DisclosureGroup.init(isExpanded: $isExpanded,
                             content: { content } ,
                             label: { label })
    }

}

extension DisclosureWithTapHandler where Label == Text {

    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.label = Text(titleKey)
    }

}

extension Framework: @retroactive Identifiable {

    public var id: String {
        return infoPlist.bundleId
    }

}

struct FrameworkNode: View {

    let framework: Framework

    var body: some View {
        Text("\(framework.infoPlist.executableName) (\(framework.infoPlist.bundleId))")
    }

}

extension AppContainer: @retroactive Identifiable {

    public var id: String {
        return infoPlist.bundleId
    }

}
