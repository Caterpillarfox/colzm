import Foundation

/// Errors surfaced by `ContainerStore`.
enum ContainerError: LocalizedError {
    case writeFailed(String)
    case readFailed(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let message): return "Write failed: \(message)"
        case .readFailed(let message): return "Read failed: \(message)"
        case .notFound(let path): return "File not found: \(path)"
        }
    }
}

/// Thin wrapper around the app's *own* sandboxed Documents container.
///
/// Phase 1 uses only `FileManager` — there is no exploit here. This exists so
/// the build -> sign -> sideload -> run pipeline can be verified end to end.
/// A later phase adds a parallel store that reaches foreign containers via the
/// `bad_query` sandbox escape.
struct ContainerStore {
    /// Name of the dummy file written by the demo.
    static let fileName = "data.txt"

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// The app's own Documents directory, e.g.
    /// `/var/mobile/Containers/Data/Application/<UUID>/Documents`.
    var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Absolute URL of `data.txt` inside Documents.
    var fileURL: URL {
        documentsURL.appendingPathComponent(Self.fileName, isDirectory: false)
    }

    /// Writes `contents` to `data.txt`, replacing any existing file.
    /// - Returns: the URL that was written.
    @discardableResult
    func write(_ contents: String) throws -> URL {
        do {
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ContainerError.writeFailed(error.localizedDescription)
        }
    }

    /// Reads `data.txt` as UTF-8 text.
    func read() throws -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ContainerError.notFound(fileURL.path)
        }
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw ContainerError.readFailed(error.localizedDescription)
        }
    }

    /// Whether `data.txt` currently exists.
    func exists() -> Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }
}
