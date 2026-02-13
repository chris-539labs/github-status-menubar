import Foundation

final class ConfigurationManager: ObservableObject {
    @Published var configuration: AppConfiguration

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    static let shared = ConfigurationManager()

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = home.appendingPathComponent(".github-status.json")

        self.encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        self.decoder = JSONDecoder()

        self.configuration = .default
        self.configuration = load()
    }

    func load() -> AppConfiguration {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .default
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(AppConfiguration.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            return .default
        }
    }

    func save(_ config: AppConfiguration) {
        do {
            let data = try encoder.encode(config)
            try data.write(to: fileURL, options: .atomic)
            self.configuration = config
        } catch {
            print("Failed to save config: \(error)")
        }
    }

    func reload() {
        self.configuration = load()
    }
}
