import Foundation

enum TodoBucket: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }
}

struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
}

@MainActor
final class TodoStore: ObservableObject {
    @Published private var lists: [TodoBucket: [TodoItem]] = [
        .daily: [],
        .weekly: [],
        .monthly: [],
    ]

    private let storageKey = "todo-widget-lists-v1"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    func items(for bucket: TodoBucket) -> [TodoItem] {
        lists[bucket] ?? []
    }

    func add(_ title: String, to bucket: TodoBucket) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        var bucketItems = lists[bucket] ?? []
        bucketItems.insert(
            TodoItem(id: UUID(), title: trimmedTitle, isDone: false, createdAt: Date()),
            at: 0
        )
        lists[bucket] = bucketItems
        save()
    }

    func toggle(_ item: TodoItem, in bucket: TodoBucket) {
        guard var bucketItems = lists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].isDone.toggle()
        lists[bucket] = bucketItems
        save()
    }

    func rename(_ item: TodoItem, to newTitle: String, in bucket: TodoBucket) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard var bucketItems = lists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].title = trimmed
        lists[bucket] = bucketItems
        save()
    }

    func delete(_ item: TodoItem, in bucket: TodoBucket) {
        guard var bucketItems = lists[bucket] else { return }
        bucketItems.removeAll { $0.id == item.id }
        lists[bucket] = bucketItems
        save()
    }

    private func save() {
        do {
            let data = try encoder.encode(lists)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("TodoStore save error: \(error)")
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            let decoded = try decoder.decode([TodoBucket: [TodoItem]].self, from: data)
            lists = [
                .daily: decoded[.daily] ?? [],
                .weekly: decoded[.weekly] ?? [],
                .monthly: decoded[.monthly] ?? [],
            ]
        } catch {
            print("TodoStore load error: \(error)")
        }
    }
}
