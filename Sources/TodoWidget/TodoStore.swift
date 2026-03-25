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
    var dueDate: Date?
}

@MainActor
final class TodoStore: ObservableObject {
    @Published private var lists: [TodoBucket: [TodoItem]] = [
        .daily: [],
        .weekly: [],
        .monthly: [],
    ]
    @Published private var weeklists: [WeekBucket: [TodoItem]] = [
        .monday: [],
        .tuesday: [],
        .wednesday: [],
        .thursday: [],
        .friday: [],
        .saturday: [],
        .sunday: [],
    ]
    
    private let storageKey = "todo-widget-lists-v1"
    private let weekStorageKey = "todo-widget-week-v1"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        load()
    }
    
    func items(for bucket: TodoBucket) -> [TodoItem] {
        let items = lists[bucket] ?? []
        return items.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (aDate?, bDate?): return aDate < bDate
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return false
            }
        }
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

    func setDueDate(_ item: TodoItem, to date: Date?, in bucket: TodoBucket) {
        guard var bucketItems = lists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].dueDate = date
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
        do {
            let data = try encoder.encode(weeklists)
            defaults.set(data, forKey: weekStorageKey)
        } catch {
            print("TodoStore save error: \(error)")
        }
    }
    
    private func load() {
        if let data = defaults.data(forKey: storageKey) {
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
        if let weekData = defaults.data(forKey: weekStorageKey) {
            do {
                let decoded = try decoder.decode([WeekBucket: [TodoItem]].self, from: weekData)
                weeklists = [
                    .monday: decoded[.monday] ?? [],
                    .tuesday: decoded[.tuesday] ?? [],
                    .wednesday: decoded[.wednesday] ?? [],
                    .thursday: decoded[.thursday] ?? [],
                    .friday: decoded[.friday] ?? [],
                    .saturday: decoded[.saturday] ?? [],
                    .sunday: decoded[.sunday] ?? [],
                ]
            } catch {
                print("TodoStore load error: \(error)")
            }
        }
    }
    
    func items(for bucket: WeekBucket) -> [TodoItem] {
        let items = weeklists[bucket] ?? []
        return items.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (aDate?, bDate?): return aDate < bDate
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return false
            }
        }
    }
    
    func add(_ title: String, to bucket: WeekBucket) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        var bucketItems = weeklists[bucket] ?? []
        bucketItems.insert(
            TodoItem(id: UUID(), title: trimmedTitle, isDone: false, createdAt: Date()),
            at: 0
        )
        weeklists[bucket] = bucketItems
        save()
    }
    
    func toggle(_ item: TodoItem, in bucket: WeekBucket) {
        guard var bucketItems = weeklists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].isDone.toggle()
        weeklists[bucket] = bucketItems
        save()
    }
    
    func rename(_ item: TodoItem, to newTitle: String, in bucket: WeekBucket) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard var bucketItems = weeklists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].title = trimmed
        weeklists[bucket] = bucketItems
        save()
    }
    
    func delete(_ item: TodoItem, in bucket: WeekBucket) {
        guard var bucketItems = weeklists[bucket] else { return }
        bucketItems.removeAll { $0.id == item.id }
        weeklists[bucket] = bucketItems
        save()
    }

    func setDueDate(_ item: TodoItem, to date: Date?, in bucket: WeekBucket) {
        guard var bucketItems = weeklists[bucket] else { return }
        guard let index = bucketItems.firstIndex(where: { $0.id == item.id }) else { return }
        bucketItems[index].dueDate = date
        weeklists[bucket] = bucketItems
        save()
    }
}

enum WeekBucket: String, CaseIterable, Codable, Identifiable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    var id: String { rawValue }

    var title: String {
        switch self {
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "Th"
        case .friday: "F"
        case .saturday: "S"
        case .sunday: "Su"

        }
    }
}

