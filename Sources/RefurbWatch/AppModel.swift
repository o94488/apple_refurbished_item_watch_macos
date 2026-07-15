import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var tasks: [WatchTask] = []
    @Published var productOpenRequest: ProductOpenRequest?
    @Published var persistenceError: String?

    private let client: AppleStoreClient
    private let persistence: TaskPersistence
    private let notifications: NotificationService
    private var monitorLoops: [UUID: Task<Void, Never>] = [:]
    private var oneOffChecks: Set<UUID> = []

    init(
        client: AppleStoreClient = AppleStoreClient(),
        persistence: TaskPersistence = TaskPersistence(),
        notifications: NotificationService = .shared
    ) {
        self.client = client
        self.persistence = persistence
        self.notifications = notifications

        do {
            if let savedTasks = try persistence.load() {
                tasks = savedTasks.map { saved in
                    var task = saved
                    task.nextCheckAt = nil
                    if task.isMonitoring {
                        task.status = .waiting
                    } else if task.status == .checking || task.status == .waiting {
                        task.status = .paused
                    }
                    return task
                }
            } else {
                tasks = [.initialTarget]
                save()
            }
        } catch {
            tasks = [.initialTarget]
            persistenceError = "Saved tasks could not be loaded: \(error.localizedDescription)"
        }

        notifications.onOpenProduct = { [weak self] request in
            self?.productOpenRequest = request
        }

        Task {
            restoreMonitoringLoops()
            await notifications.configure()
        }
    }

    deinit {
        monitorLoops.values.forEach { $0.cancel() }
    }

    var hasMonitoringTasks: Bool {
        tasks.contains(where: \.isMonitoring)
    }

    func addTask(
        naturalLanguageDescription: String,
        exactProductTitle: String,
        category: ProductCategory,
        intervalSeconds: TimeInterval,
        notificationsEnabled: Bool,
        soundEnabled: Bool
    ) {
        let task = WatchTask(
            naturalLanguageDescription: naturalLanguageDescription,
            exactProductTitle: exactProductTitle,
            category: category,
            intervalSeconds: intervalSeconds,
            notificationsEnabled: notificationsEnabled,
            soundEnabled: soundEnabled
        )
        tasks.append(task)
        save()
    }

    func updateTask(
        id: UUID,
        naturalLanguageDescription: String,
        exactProductTitle: String,
        category: ProductCategory,
        intervalSeconds: TimeInterval,
        notificationsEnabled: Bool,
        soundEnabled: Bool
    ) {
        guard let index = index(for: id) else { return }
        let matchChanged = tasks[index].exactProductTitle != exactProductTitle || tasks[index].category != category
        tasks[index].naturalLanguageDescription = naturalLanguageDescription
        tasks[index].exactProductTitle = exactProductTitle
        tasks[index].category = category
        tasks[index].intervalSeconds = min(max(intervalSeconds, 30), 86_400)
        tasks[index].notificationsEnabled = notificationsEnabled
        tasks[index].soundEnabled = soundEnabled

        if matchChanged {
            tasks[index].hasAlertedForCurrentAvailability = false
            tasks[index].matchedProductName = nil
            tasks[index].matchedPrice = nil
            tasks[index].matchedProductURL = nil
            tasks[index].lastError = nil
        }

        let wasMonitoring = tasks[index].isMonitoring
        save()
        if wasMonitoring {
            createMonitoringLoop(for: id, replaceExisting: true)
        }
    }

    func deleteTask(id: UUID) {
        monitorLoops[id]?.cancel()
        monitorLoops[id] = nil
        tasks.removeAll { $0.id == id }
        save()
    }

    func startAll() {
        for id in tasks.map(\.id) {
            startMonitoring(id: id)
        }
    }

    func startMonitoring(id: UUID) {
        guard let index = index(for: id) else { return }
        tasks[index].isMonitoring = true
        tasks[index].status = .waiting
        tasks[index].lastError = nil
        save()
        createMonitoringLoop(for: id, replaceExisting: true)
    }

    func pauseMonitoring(id: UUID) {
        monitorLoops[id]?.cancel()
        monitorLoops[id] = nil
        guard let index = index(for: id) else { return }
        tasks[index].isMonitoring = false
        tasks[index].status = .paused
        tasks[index].nextCheckAt = nil
        save()
    }

    func checkNow(id: UUID) {
        if task(for: id)?.isMonitoring == true {
            createMonitoringLoop(for: id, replaceExisting: true)
            return
        }
        guard !oneOffChecks.contains(id) else { return }
        oneOffChecks.insert(id)
        Task { [weak self] in
            guard let self else { return }
            await self.performCheck(id: id, bypassCache: true)
            self.oneOffChecks.remove(id)
        }
    }

    func setNotificationsEnabled(_ enabled: Bool, id: UUID) {
        guard let index = index(for: id) else { return }
        tasks[index].notificationsEnabled = enabled
        save()
    }

    func setSoundEnabled(_ enabled: Bool, id: UUID) {
        guard let index = index(for: id) else { return }
        tasks[index].soundEnabled = enabled
        save()
    }

    func openConfirmedProduct() {
        guard let url = productOpenRequest?.url else { return }
        NSWorkspace.shared.open(url)
        productOpenRequest = nil
    }

    private func restoreMonitoringLoops() {
        for task in tasks where task.isMonitoring {
            createMonitoringLoop(for: task.id, replaceExisting: true)
        }
    }

    private func createMonitoringLoop(for id: UUID, replaceExisting: Bool) {
        if replaceExisting {
            monitorLoops[id]?.cancel()
        } else if monitorLoops[id] != nil {
            return
        }

        monitorLoops[id] = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let task = self.task(for: id), task.isMonitoring else { break }
                await self.performCheck(id: id, bypassCache: false)
                guard !Task.isCancelled,
                      let refreshedTask = self.task(for: id),
                      refreshedTask.isMonitoring else { break }

                let interval = min(max(refreshedTask.intervalSeconds, 30), 86_400)
                self.setNextCheck(Date().addingTimeInterval(interval), id: id)
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    break
                }
            }
        }
    }

    private func performCheck(id: UUID, bypassCache: Bool) async {
        guard let taskSnapshot = task(for: id),
              let taskIndex = index(for: id) else { return }

        tasks[taskIndex].status = .checking
        tasks[taskIndex].lastError = nil
        tasks[taskIndex].nextCheckAt = nil

        do {
            let products = try await client.fetchProducts(category: taskSnapshot.category, bypassCache: bypassCache)
            guard let currentIndex = index(for: id) else { return }
            let match = products.first {
                ProductTitleMatcher.isCloseMatch(
                    target: tasks[currentIndex].exactProductTitle,
                    productName: $0.name
                )
            }

            tasks[currentIndex].lastCheckedAt = Date()
            tasks[currentIndex].lastError = nil

            if let match {
                let shouldAlert = !tasks[currentIndex].hasAlertedForCurrentAvailability
                tasks[currentIndex].status = .inStock
                tasks[currentIndex].matchedProductName = match.name
                tasks[currentIndex].matchedPrice = match.formattedPrice
                tasks[currentIndex].matchedProductURL = match.url
                tasks[currentIndex].hasAlertedForCurrentAvailability = true

                if shouldAlert {
                    let alertTask = tasks[currentIndex]
                    if alertTask.notificationsEnabled {
                        notifications.sendAvailabilityAlert(for: alertTask, product: match)
                    } else if alertTask.soundEnabled {
                        notifications.playStandaloneSound()
                    }
                }
            } else {
                tasks[currentIndex].status = .outOfStock
                tasks[currentIndex].matchedProductName = nil
                tasks[currentIndex].matchedPrice = nil
                tasks[currentIndex].matchedProductURL = nil
                tasks[currentIndex].hasAlertedForCurrentAvailability = false
            }
            save()
        } catch is CancellationError {
            return
        } catch {
            guard let currentIndex = index(for: id) else { return }
            tasks[currentIndex].status = .error
            tasks[currentIndex].lastCheckedAt = Date()
            tasks[currentIndex].lastError = error.localizedDescription
            // Keep the previous availability episode flag on errors so a network
            // failure never creates a duplicate restock notification.
            save()
        }
    }

    private func setNextCheck(_ date: Date, id: UUID) {
        guard let index = index(for: id) else { return }
        tasks[index].nextCheckAt = date
        if tasks[index].status != .inStock && tasks[index].status != .outOfStock && tasks[index].status != .error {
            tasks[index].status = .waiting
        }
        save()
    }

    private func task(for id: UUID) -> WatchTask? {
        tasks.first { $0.id == id }
    }

    private func index(for id: UUID) -> Int? {
        tasks.firstIndex { $0.id == id }
    }

    private func save() {
        do {
            try persistence.save(tasks)
            persistenceError = nil
        } catch {
            persistenceError = "Changes could not be saved: \(error.localizedDescription)"
        }
    }
}
