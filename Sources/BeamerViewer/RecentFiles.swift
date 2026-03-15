import Foundation

@Observable
final class RecentFiles {
    static let shared = RecentFiles()
    private let key = "recentFiles"
    private let maxCount = 10

    private(set) var files: [RecentFile] = []

    struct RecentFile: Codable, Identifiable {
        let name: String
        let date: Date
        let bookmark: Data?  // security-scoped bookmark for iOS
        let path: String     // display path / macOS direct path
        var id: String { path }

        var url: URL? {
            #if os(iOS)
            guard let bookmark else { return nil }
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmark,
                bookmarkDataIsStale: &isStale
            ) else { return nil }
            // Security scope is needed — SlideManager.load() handles start/stop
            return url
            #else
            return URL(fileURLWithPath: path)
            #endif
        }

        var exists: Bool {
            #if os(iOS)
            return url != nil
            #else
            return FileManager.default.fileExists(atPath: path)
            #endif
        }
    }

    init() {
        load()
    }

    func add(url: URL) {
        let bookmark: Data?
        #if os(iOS)
        let accessing = url.startAccessingSecurityScopedResource()
        bookmark = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        if accessing { url.stopAccessingSecurityScopedResource() }
        #else
        bookmark = nil
        #endif

        let file = RecentFile(
            name: url.lastPathComponent,
            date: Date(),
            bookmark: bookmark,
            path: url.path
        )
        files.removeAll { $0.path == file.path }
        files.insert(file, at: 0)
        if files.count > maxCount { files = Array(files.prefix(maxCount)) }
        save()
    }

    func removeByPath(_ path: String) {
        files.removeAll { $0.path == path }
        save()
    }

    func remove(at offsets: IndexSet) {
        files.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        files.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([RecentFile].self, from: data) else { return }
        #if os(iOS)
        files = decoded  // don't filter by exists on iOS — bookmarks resolve lazily
        #else
        files = decoded.filter { $0.exists }
        #endif
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(files) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
