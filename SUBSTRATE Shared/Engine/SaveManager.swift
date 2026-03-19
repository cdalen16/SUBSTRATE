import Foundation

enum SaveManager {

    private static let saveFileName = "substrate_save.json"
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private static let decoder = JSONDecoder()

    // MARK: - Save

    static func save(state: GameState) {
        do {
            let data = try encoder.encode(state)
            let url = saveFileURL()
            try data.write(to: url, options: .atomic)
        } catch {
            print("[SaveManager] Save failed: \(error)")
        }
    }

    // MARK: - Load

    static func load() -> GameState? {
        let url = saveFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let state = try decoder.decode(GameState.self, from: data)
            return state
        } catch {
            print("[SaveManager] Load failed: \(error)")
            return nil
        }
    }

    // MARK: - Delete

    static func deleteSave() {
        let url = saveFileURL()
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Check

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: saveFileURL().path)
    }

    // MARK: - File Path

    private static func saveFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(saveFileName)
    }
}
