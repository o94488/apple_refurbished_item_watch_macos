import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingAddTask = false
    @State private var taskToEdit: WatchTask?

    var body: some View {
        VStack(spacing: 0) {
            header

            if let persistenceError = model.persistenceError {
                errorBanner(persistenceError)
            }

            Divider()

            if model.tasks.isEmpty {
                ContentUnavailableView {
                    Label("No Watch Tasks", systemImage: "binoculars")
                } description: {
                    Text("Describe an Apple refurbished product to begin watching it.")
                } actions: {
                    Button("Add Watch Task") {
                        showingAddTask = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(model.tasks) { task in
                            WatchTaskCard(
                                task: task,
                                onEdit: { taskToEdit = task }
                            )
                            .environmentObject(model)
                        }
                    }
                    .padding(22)
                }
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskEditorView(task: nil) { draft in
                model.addTask(
                    naturalLanguageDescription: draft.naturalLanguageDescription,
                    exactProductTitle: draft.exactProductTitle,
                    category: draft.category,
                    intervalSeconds: draft.intervalSeconds,
                    notificationsEnabled: draft.notificationsEnabled,
                    soundEnabled: draft.soundEnabled
                )
            }
        }
        .sheet(item: $taskToEdit) { task in
            TaskEditorView(task: task) { draft in
                model.updateTask(
                    id: task.id,
                    naturalLanguageDescription: draft.naturalLanguageDescription,
                    exactProductTitle: draft.exactProductTitle,
                    category: draft.category,
                    intervalSeconds: draft.intervalSeconds,
                    notificationsEnabled: draft.notificationsEnabled,
                    soundEnabled: draft.soundEnabled
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.blue.gradient)
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text("Refurb Watch")
                    .font(.title2.weight(.semibold))
                Text("Apple Canada refurbished inventory")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.startAll()
            } label: {
                Label("Start All", systemImage: "play.fill")
            }
            .buttonStyle(.bordered)
            .disabled(model.tasks.isEmpty || model.tasks.allSatisfy(\.isMonitoring))

            Button {
                showingAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.09))
    }
}

struct WatchTaskCard: View {
    @EnvironmentObject private var model: AppModel
    let task: WatchTask
    let onEdit: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: task.category.symbolName)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 42, height: 42)
                    .background(task.status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(task.status.color)

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.exactProductTitle)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        statusBadge
                        Text(task.category.displayName)
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(CheckInterval.label(for: task.intervalSeconds))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 14)

                if let price = task.matchedPrice, task.status == .inStock {
                    Text(price)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Divider()

            HStack(alignment: .top, spacing: 24) {
                statusDetails
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Desktop notification", isOn: Binding(
                        get: { task.notificationsEnabled },
                        set: { model.setNotificationsEnabled($0, id: task.id) }
                    ))
                    Toggle("Sound", isOn: Binding(
                        get: { task.soundEnabled },
                        set: { model.setSoundEnabled($0, id: task.id) }
                    ))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .frame(width: 190, alignment: .leading)
            }

            HStack(spacing: 9) {
                Button {
                    if task.isMonitoring {
                        model.pauseMonitoring(id: task.id)
                    } else {
                        model.startMonitoring(id: task.id)
                    }
                } label: {
                    Label(
                        task.isMonitoring ? "Pause" : "Start Monitoring",
                        systemImage: task.isMonitoring ? "pause.fill" : "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(task.isMonitoring ? .orange : .blue)

                Button {
                    model.checkNow(id: task.id)
                } label: {
                    Label("Check Now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Edit", systemImage: "pencil", action: onEdit)
                    .buttonStyle(.borderless)

                Button("Delete", systemImage: "trash") {
                    confirmingDelete = true
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 7, y: 2)
        .confirmationDialog(
            "Delete this watch task?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                model.deleteTask(id: task.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(task.exactProductTitle)
        }
    }

    private var statusBadge: some View {
        Label(task.status.label, systemImage: task.status.symbolName)
            .font(.caption.weight(.medium))
            .foregroundStyle(task.status.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(task.status.color.opacity(0.1), in: Capsule())
    }

    @ViewBuilder
    private var statusDetails: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let matched = task.matchedProductName {
                detailLine(icon: "checkmark.seal", label: "Matched", value: matched)
            } else {
                detailLine(icon: "scope", label: "Target match", value: "No close-enough listing in the current inventory")
            }

            detailLine(
                icon: "clock.arrow.circlepath",
                label: "Last check",
                value: task.lastCheckedAt.map(Self.dateFormatter.string(from:)) ?? "Not checked yet"
            )

            if task.isMonitoring {
                detailLine(
                    icon: "calendar.badge.clock",
                    label: "Next check",
                    value: task.nextCheckAt.map(Self.dateFormatter.string(from:)) ?? "As soon as the current check finishes"
                )
            }

            if let error = task.lastError {
                detailLine(icon: "wifi.exclamationmark", label: "Error", value: error, color: .red)
            }
        }
    }

    private func detailLine(icon: String, label: String, value: String, color: Color = .secondary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Image(systemName: icon)
                .frame(width: 16)
            Text("\(label):")
                .fontWeight(.medium)
            Text(value)
                .lineLimit(2)
        }
        .font(.caption)
        .foregroundStyle(color)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
