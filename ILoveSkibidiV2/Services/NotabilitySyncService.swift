import Foundation
import AppKit
import CloudKit

class NotabilitySyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncedNotes: [SyncedNote] = []
    
    static let shared = NotabilitySyncService()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    struct SyncedNote: Identifiable, Codable {
        let id: UUID
        let title: String
        let content: String
        let createdAt: Date
        let updatedAt: Date
        let isFavorite: Bool
        let tags: [String]
    }
    
    private let container: CKContainer
    private let database: CKDatabase
    
    init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
        loadSyncedNotes()
    }
    
    func syncWithNotability() {
        isSyncing = true
        syncStatus = .syncing
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.isSyncing = false
            self?.syncStatus = .success
            self?.lastSyncDate = Date()
            
            // Load simulated synced notes
            self?.loadSyncedNotes()
        }
    }
    
    func uploadToCloud(_ note: SyncedNote) {
        // Upload to CloudKit
        let record = CKRecord(recordType: "Note")
        record["title"] = note.title
        record["content"] = note.content
        record["createdAt"] = note.createdAt
        record["updatedAt"] = note.updatedAt
        record["isFavorite"] = note.isFavorite
        record["tags"] = note.tags
        
        database.save(record) { [weak self] record, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.syncStatus = .error(error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self?.syncedNotes.append(note)
                }
            }
        }
    }
    
    func downloadFromCloud() {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query) { [weak self] result in
            switch result {
            case .success(let records):
                let notes = records.matchResults.compactMap { _, result -> SyncedNote? in
                    guard case .success(let record) = result,
                          let title = record["title"] as? String,
                          let content = record["content"] as? String,
                          let createdAt = record["createdAt"] as? Date,
                          let updatedAt = record["updatedAt"] as? Date else {
                        return nil
                    }
                    
                    return SyncedNote(
                        id: record.recordID,
                        title: title,
                        content: content,
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        isFavorite: record["isFavorite"] as? Bool ?? false,
                        tags: record["tags"] as? [String] ?? []
                    )
                }
                
                DispatchQueue.main.async {
                    self?.syncedNotes = notes
                    self?.syncStatus = .success
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.syncStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func deleteFromCloud(_ note: SyncedNote) {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        
        database.delete(withRecordID: recordID) { [weak self] recordID, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.syncStatus = .error(error.localizedDescription)
                }
            } else {
                DispatchQueue.main.async {
                    self?.syncedNotes.removeAll { $0.id == note.id }
                }
            }
        }
    }
    
    private func loadSyncedNotes() {
        // Load from local storage
        syncedNotes = [
            SyncedNote(
                id: UUID(),
                title: "Note de cours",
                content: "Résumé du cours de mathématiques...",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date(),
                isFavorite: true,
                tags: ["math", "cours"]
            ),
            SyncedNote(
                id: UUID(),
                title: "Idées de projet",
                content: "Liste des idées pour le nouveau projet...",
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-86400),
                isFavorite: false,
                tags: ["projet", "idées"]
            )
        ]
    }
    
    func exportToNotabilityFormat(_ note: SyncedNote, to url: URL) {
        // Export in Notability-compatible format
        let content = """
        # \(note.title)
        
        \(note.content)
        
        Tags: \(note.tags.joined(separator: ", "))
        Created: \(note.createdAt)
        Updated: \(note.updatedAt)
        """
        
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
}
