import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var selectedBucket: TodoBucket = .daily
    @State private var draftText = ""
    @State private var showPlanner: Bool = false
    @State private var editingDueDateFor: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(showPlanner ? "Planner" : "Todo").font(.headline)
                Spacer()
                Toggle("", isOn: $showPlanner).toggleStyle(.switch)
            }
            
            Divider()
            
            if showPlanner {
                WeeklyPlannerView()
            } else {
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
                            ForEach(items) { item in row(for: item)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 260)
                }
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private func row(for item: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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

                if selectedBucket == .monthly || selectedBucket == .weekly {
                    if let dueDate = item.dueDate {
                        Text(dDayLabel(for: dueDate))
                            .font(.caption.bold())
                            .foregroundStyle(dDayColor(for: dueDate))
                    }

                    Button {
                        editingDueDateFor = editingDueDateFor == item.id ? nil : item.id
                    } label: {
                        Image(systemName: item.dueDate != nil ? "calendar.badge.checkmark" : "calendar")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(item.dueDate != nil ? .blue : .secondary)
                    .popover(isPresented: Binding(
                        get: { editingDueDateFor == item.id },
                        set: { if !$0 { editingDueDateFor = nil } }
                    )) {
                        VStack(spacing: 8) {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { item.dueDate ?? Date() },
                                    set: { store.setDueDate(item, to: $0, in: selectedBucket) }
                                ),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .focusable(false)

                            if item.dueDate != nil {
                                Divider()
                                Button("Clear date") {
                                    store.setDueDate(item, to: nil, in: selectedBucket)
                                    editingDueDateFor = nil
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                                .buttonStyle(.plain)
                                .padding(.bottom, 4)
                            }
                        }
                        .padding(12)
                        .focusable(false)
                    }
                }

                Button {
                    store.delete(item, in: selectedBucket)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func dDayLabel(for date: Date) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0
        if days == 0 { return "D-Day" }
        if days > 0 { return "D-\(days)" }
        return "D+\(-days)"
    }

    private func dDayColor(for date: Date) -> Color {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0
        if days < 0 { return .red }
        if days == 0 { return .orange }
        return .blue
    }

    private func addTask() {
        store.add(draftText, to: selectedBucket)
        draftText = ""
    }
}
