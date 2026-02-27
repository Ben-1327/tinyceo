import Foundation
import SQLite3

public enum SQLiteRepositoryError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case stepFailed(String)
    case bindFailed(String)
    case decodeFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let message): return "sqlite open failed: \(message)"
        case .prepareFailed(let message): return "sqlite prepare failed: \(message)"
        case .stepFailed(let message): return "sqlite step failed: \(message)"
        case .bindFailed(let message): return "sqlite bind failed: \(message)"
        case .decodeFailed(let error): return "state decode failed: \(error)"
        }
    }
}

public final class SQLiteRepository: @unchecked Sendable {
    private var db: OpaquePointer?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(path: String) throws {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.sortedKeys]

        if sqlite3_open(path, &db) != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(db))
            sqlite3_close(db)
            throw SQLiteRepositoryError.openFailed(message)
        }

        try migrate()
    }

    deinit {
        sqlite3_close(db)
    }

    public func saveSnapshot(_ state: GameState) throws {
        let data = try encoder.encode(state)
        guard let json = String(data: data, encoding: .utf8) else {
            throw SQLiteRepositoryError.bindFailed("snapshot encoding returned non-utf8")
        }

        let sql = "INSERT INTO snapshots(created_at, state_json) VALUES(?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteRepositoryError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        guard sqlite3_bind_text(statement, 1, timestamp, -1, SQLITE_TRANSIENT) == SQLITE_OK,
              sqlite3_bind_text(statement, 2, json, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw SQLiteRepositoryError.bindFailed(String(cString: sqlite3_errmsg(db)))
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteRepositoryError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    public func loadLatestSnapshot() throws -> GameState? {
        let sql = "SELECT state_json FROM snapshots ORDER BY id DESC LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteRepositoryError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        let result = sqlite3_step(statement)
        guard result == SQLITE_ROW || result == SQLITE_DONE else {
            throw SQLiteRepositoryError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }

        guard result == SQLITE_ROW, let pointer = sqlite3_column_text(statement, 0) else {
            return nil
        }

        let json = String(cString: pointer)
        do {
            return try decoder.decode(GameState.self, from: Data(json.utf8))
        } catch {
            throw SQLiteRepositoryError.decodeFailed(error)
        }
    }

    public func appendEvent(type: String, payload: [String: String]) throws {
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        guard let payloadJSON = String(data: payloadData, encoding: .utf8) else {
            throw SQLiteRepositoryError.bindFailed("event payload is not utf8")
        }

        let sql = "INSERT INTO events(created_at, event_type, payload_json) VALUES(?, ?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteRepositoryError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        guard sqlite3_bind_text(statement, 1, timestamp, -1, SQLITE_TRANSIENT) == SQLITE_OK,
              sqlite3_bind_text(statement, 2, type, -1, SQLITE_TRANSIENT) == SQLITE_OK,
              sqlite3_bind_text(statement, 3, payloadJSON, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw SQLiteRepositoryError.bindFailed(String(cString: sqlite3_errmsg(db)))
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteRepositoryError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    public func loadEvents(limit: Int = 100) throws -> [[String: String]] {
        let sql = "SELECT created_at, event_type, payload_json FROM events ORDER BY id DESC LIMIT ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteRepositoryError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(limit)) == SQLITE_OK else {
            throw SQLiteRepositoryError.bindFailed(String(cString: sqlite3_errmsg(db)))
        }

        var items: [[String: String]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let createdAt = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? ""
            let eventType = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? ""
            let payload = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? "{}"
            items.append([
                "created_at": createdAt,
                "event_type": eventType,
                "payload_json": payload
            ])
        }
        return items
    }

    private func migrate() throws {
        let createSnapshots = """
        CREATE TABLE IF NOT EXISTS snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            state_json TEXT NOT NULL
        );
        """

        let createEvents = """
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            event_type TEXT NOT NULL,
            payload_json TEXT NOT NULL
        );
        """

        try execute(sql: createSnapshots)
        try execute(sql: createEvents)
    }

    private func execute(sql: String) throws {
        var errorMessage: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(db))
            sqlite3_free(errorMessage)
            throw SQLiteRepositoryError.stepFailed(message)
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
