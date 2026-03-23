import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var selectedBucket: TodoBucket = .daily
    @State private var draftText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Todo")
                .font(.headline)

            Divider()

            Picker("List", selection: $selectedBucket) {
                ForEach(TodoBucket.allCases) { bucket in
                    Text(bucket.title).tag(bucket)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                TextField("Add a task...", text: $draftText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTask)

                Button("Add", action: addTask)
                    .keyboardShortcut(.defaultAction)
            }

            let items = store.items(for: selectedBucket)
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("No \(selectedBucket.title) tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Add something above to get started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 18)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(items) { item in
                            row(for: item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private func row(for item: TodoItem) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggle(item, in: selectedBucket)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)

            if item.isDone {
                Text(item.title)
                    .strikethrough(true, color: .secondary)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField(
                    "Task name",
                    text: Binding(
                        get: { item.title },
                        set: { store.rename(item, to: $0, in: selectedBucket) }
                    )
                )
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                store.delete(item, in: selectedBucket)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func addTask() {
        store.add(draftText, to: selectedBucket)
        draftText = ""
    }
}
