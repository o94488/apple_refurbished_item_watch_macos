import Foundation
import SwiftUI

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case mac
    case ipad
    case iphone
    case airpods
    case appleTV
    case homepod
    case accessories

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mac: "Mac"
        case .ipad: "iPad"
        case .iphone: "iPhone"
        case .airpods: "AirPods"
        case .appleTV: "Apple TV"
        case .homepod: "HomePod"
        case .accessories: "Accessories"
        }
    }

    var storePath: String {
        switch self {
        case .mac: "mac"
        case .ipad: "ipad"
        case .iphone: "iphone"
        case .airpods: "airpods"
        case .appleTV: "appletv"
        case .homepod: "homepod"
        case .accessories: "accessories"
        }
    }

    var symbolName: String {
        switch self {
        case .mac: "laptopcomputer"
        case .ipad: "ipad"
        case .iphone: "iphone"
        case .airpods: "airpodspro"
        case .appleTV: "appletv"
        case .homepod: "homepodmini"
        case .accessories: "keyboard"
        }
    }
}

enum InventoryStatus: String, Codable {
    case paused
    case waiting
    case checking
    case inStock
    case outOfStock
    case error

    var label: String {
        switch self {
        case .paused: "Paused"
        case .waiting: "Waiting"
        case .checking: "Checking"
        case .inStock: "In Stock"
        case .outOfStock: "Out of Stock"
        case .error: "Connection Error"
        }
    }

    var color: Color {
        switch self {
        case .paused: .secondary
        case .waiting: .blue
        case .checking: .orange
        case .inStock: .green
        case .outOfStock: .secondary
        case .error: .red
        }
    }

    var symbolName: String {
        switch self {
        case .paused: "pause.circle.fill"
        case .waiting: "clock.fill"
        case .checking: "arrow.trianglehead.2.clockwise.rotate.90"
        case .inStock: "checkmark.circle.fill"
        case .outOfStock: "xmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }
}

struct WatchTask: Codable, Identifiable, Equatable {
    var id: UUID
    var naturalLanguageDescription: String
    var exactProductTitle: String
    var category: ProductCategory
    var intervalSeconds: TimeInterval
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var isMonitoring: Bool

    var status: InventoryStatus
    var lastCheckedAt: Date?
    var nextCheckAt: Date?
    var matchedProductName: String?
    var matchedPrice: String?
    var matchedProductURL: URL?
    var lastError: String?
    var hasAlertedForCurrentAvailability: Bool

    init(
        id: UUID = UUID(),
        naturalLanguageDescription: String,
        exactProductTitle: String,
        category: ProductCategory,
        intervalSeconds: TimeInterval = 300,
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        isMonitoring: Bool = false,
        status: InventoryStatus = .paused,
        lastCheckedAt: Date? = nil,
        nextCheckAt: Date? = nil,
        matchedProductName: String? = nil,
        matchedPrice: String? = nil,
        matchedProductURL: URL? = nil,
        lastError: String? = nil,
        hasAlertedForCurrentAvailability: Bool = false
    ) {
        self.id = id
        self.naturalLanguageDescription = naturalLanguageDescription
        self.exactProductTitle = exactProductTitle
        self.category = category
        self.intervalSeconds = min(max(intervalSeconds, 30), 86_400)
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.isMonitoring = isMonitoring
        self.status = status
        self.lastCheckedAt = lastCheckedAt
        self.nextCheckAt = nextCheckAt
        self.matchedProductName = matchedProductName
        self.matchedPrice = matchedPrice
        self.matchedProductURL = matchedProductURL
        self.lastError = lastError
        self.hasAlertedForCurrentAvailability = hasAlertedForCurrentAvailability
    }

    static var initialTarget: WatchTask {
        WatchTask(
            naturalLanguageDescription: "Refurbished iPhone 16 Pro 256GB - Black Titanium",
            exactProductTitle: "Refurbished iPhone 16 Pro 256GB - Black Titanium",
            category: .iphone
        )
    }
}

struct AppleProduct: Equatable {
    let name: String
    let url: URL
    let price: Decimal?
    let currencyCode: String?
    let sku: String?

    var formattedPrice: String? {
        guard let price else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        return formatter.string(from: price as NSDecimalNumber)
    }
}

struct ParsedProductDescription {
    let original: String
    let exactProductTitle: String
    let category: ProductCategory
    let detectedDetails: [String]
}

struct ProductOpenRequest: Identifiable {
    let id = UUID()
    let productName: String
    let url: URL
}

enum CheckInterval {
    static let options: [TimeInterval] = [
        30, 60, 120, 300, 600, 900, 1_800, 3_600, 7_200, 21_600, 43_200, 86_400
    ]

    static func label(for seconds: TimeInterval) -> String {
        let value = Int(seconds)
        if value < 60 { return "Every \(value) seconds" }
        if value < 3_600 {
            let minutes = value / 60
            return "Every \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        let hours = value / 3_600
        return "Every \(hours) hour\(hours == 1 ? "" : "s")"
    }
}
