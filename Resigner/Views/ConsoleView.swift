import SwiftUI

protocol ConsoleViewModel: ObservableObject {

    var lines: [ConsoleLogsCollectorImpl.LogEntry] { get }

}

struct ConsoleView<VM: ConsoleViewModel>: View {

    @ObservedObject
    var vm: VM

    init(vm: VM) {
        self.vm = vm
    }

    var body: some View {
        LazyVStack {
            ForEach(Array(vm.lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top) {
                    Text("\(index + 1) ").bold().font(Font.system(size: 16).monospaced())
                    + Text("[\(ISO8601DateFormatter().string(from: line.timestamp))] ").font(Font.system(size: 16).monospaced())
                    + Text(line.line).font(Font.system(size: 16).monospaced())
                    Spacer()
                }
            }
        }
    }

}
