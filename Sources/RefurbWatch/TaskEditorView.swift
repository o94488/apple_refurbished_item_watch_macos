import SwiftUI

struct TaskEditorDraft {
    let naturalLanguageDescription: String
    let exactProductTitle: String
    let category: ProductCategory
    let intervalSeconds: TimeInterval
    let notificationsEnabled: Bool
    let soundEnabled: Bool
}

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let task: WatchTask?
    let onSave: (TaskEditorDraft) -> Void

    @State private var naturalLanguageDescription: String
    @State private var exactProductTitle: String
    @State private var category: ProductCategory
    @State private var intervalSeconds: TimeInterval
    @State private var notificationsEnabled: Bool
    @State private var soundEnabled: Bool
    @State private var detectedDetails: [String]
    @State private var hasReviewedDescription: Bool

    init(task: WatchTask?, onSave: @escaping (TaskEditorDraft) -> Void) {
        self.task = task
        self.onSave = onSave

        let natural = task?.naturalLanguageDescription ?? ""
        let title = task?.exactProductTitle ?? ""
        _naturalLanguageDescription = State(initialValue: natural)
        _exactProductTitle = State(initialValue: title)
        _category = State(initialValue: task?.category ?? .iphone)
        _intervalSeconds = State(initialValue: task?.intervalSeconds ?? 300)
        _notificationsEnabled = State(initialValue: task?.notificationsEnabled ?? true)
        _soundEnabled = State(initialValue: task?.soundEnabled ?? true)
        _detectedDetails = State(initialValue: title.isEmpty ? [] : ProductDescriptionParser.detectDetails(in: title))
        _hasReviewedDescription = State(initialValue: task != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task == nil ? "Add Watch Task" : "Edit Watch Task")
                        .font(.title2.weight(.semibold))
                    Text("Describe the product and the details that matter to you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(22)

            Divider()

            Form {
                Section("Natural-language description") {
                    ZStack(alignment: .topLeading) {
                        if naturalLanguageDescription.isEmpty {
                            Text("Example: Refurbished iPhone 16 Pro 256GB in Black Titanium")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 9)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $naturalLanguageDescription)
                            .font(.body)
                            .frame(minHeight: 72)
                            .scrollContentBackground(.hidden)
                    }
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.12))
                    }

                    HStack {
                        Text("Parsing happens entirely on this Mac.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Review Match", systemImage: "wand.and.stars") {
                            reviewDescription()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(naturalLanguageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if hasReviewedDescription {
                    Section("Confirm the product match") {
                        Picker("Store category", selection: $category) {
                            ForEach(ProductCategory.allCases) { category in
                                Label(category.displayName, systemImage: category.symbolName)
                                    .tag(category)
                            }
                        }

                        TextField("Apple product title or important details", text: $exactProductTitle, axis: .vertical)
                            .lineLimit(2...4)

                        Text("Every meaningful detail you enter must appear in Apple’s listing. Apple may add unspecified details such as “Unlocked,” but conflicting models, storage sizes, colours, connectivity, or display finishes are rejected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !detectedDetails.isEmpty {
                            LabeledContent("Detected details") {
                                Text(detectedDetails.joined(separator: "  •  "))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }

                    Section("Monitoring") {
                        Picker("Check interval", selection: $intervalSeconds) {
                            ForEach(CheckInterval.options, id: \.self) { interval in
                                Text(CheckInterval.label(for: interval))
                                    .tag(interval)
                            }
                        }

                        Toggle("Desktop notification", isOn: $notificationsEnabled)
                        Toggle("Sound", isOn: $soundEnabled)

                        Text("The first check runs immediately after monitoring starts. Alerts repeat only after the product disappears and later returns.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Text("Canada • apple.com/ca/shop/refurbished")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Save Task") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding(18)
        }
        .frame(width: 680, height: 690)
    }

    private var canSave: Bool {
        hasReviewedDescription &&
        !naturalLanguageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !exactProductTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func reviewDescription() {
        let parsed = ProductDescriptionParser.parse(naturalLanguageDescription)
        exactProductTitle = parsed.exactProductTitle
        category = parsed.category
        detectedDetails = parsed.detectedDetails
        hasReviewedDescription = true
    }

    private func save() {
        let draft = TaskEditorDraft(
            naturalLanguageDescription: naturalLanguageDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            exactProductTitle: exactProductTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            intervalSeconds: min(max(intervalSeconds, 30), 86_400),
            notificationsEnabled: notificationsEnabled,
            soundEnabled: soundEnabled
        )
        onSave(draft)
        dismiss()
    }
}
