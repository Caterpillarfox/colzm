import SwiftUI
import UIKit

// MARK: - Log model

struct LogEntry: Identifiable {
    enum Kind {
        case info, success, error

        var symbol: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .info: return .secondary
            case .success: return .green
            case .error: return .red
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let message: String
    let date: Date
}

// MARK: - Demo state

@MainActor
final class DemoModel: ObservableObject {
    @Published private(set) var log: [LogEntry] = []

    private let store = ContainerStore()

    var bundleID: String { Bundle.main.bundleIdentifier ?? "unknown" }
    var osVersion: String { "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)" }
    var documentsPath: String { store.documentsURL.path }

    func append(_ kind: LogEntry.Kind, _ message: String) {
        log.append(LogEntry(kind: kind, message: message, date: Date()))
    }

    func writeData() {
        do {
            let url = try store.write("some data here")
            append(.success, "Wrote \(ContainerStore.fileName) -> \(url.path)")
        } catch {
            append(.error, error.localizedDescription)
        }
    }

    func readData() {
        do {
            let contents = try store.read()
            append(.info, "Read \(ContainerStore.fileName): \"\(contents)\" (\(contents.utf8.count) bytes)")
        } catch {
            append(.error, error.localizedDescription)
        }
    }

    func clear() {
        log.removeAll()
    }
}

// MARK: - View

struct ContentView: View {
    @StateObject private var model = DemoModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                infoCard
                actionButtons
                Divider()
                logList
            }
            .navigationTitle("BadQueryDemo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { model.clear() }
                        .disabled(model.log.isEmpty)
                }
            }
            .onAppear(perform: bootstrap)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            infoRow("Bundle", model.bundleID)
            infoRow("OS", model.osVersion)
            infoRow("Container", model.documentsPath)
        }
        .font(.system(.footnote, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(title).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                model.writeData()
            } label: {
                Label("Write data.txt", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                model.readData()
            } label: {
                Label("Read data.txt", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var logList: some View {
        ScrollViewReader { proxy in
            List(model.log) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: entry.kind.symbol)
                        .foregroundStyle(entry.kind.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                        Text(entry.date.formatted(date: .omitted, time: .standard))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .id(entry.id)
            }
            .listStyle(.plain)
            .onChange(of: model.log.count) { _, _ in
                if let last = model.log.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private func bootstrap() {
        guard model.log.isEmpty else { return }
        model.append(.info, "Ready - Phase 1 (own container, no exploit).")
        model.append(.info, "Bundle: \(model.bundleID)")
        model.append(.info, "Documents: \(model.documentsPath)")
    }
}

#Preview {
    ContentView()
}
