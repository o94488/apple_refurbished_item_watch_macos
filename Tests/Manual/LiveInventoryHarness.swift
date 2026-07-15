import Foundation

@main
struct LiveInventoryHarness {
    static func main() async throws {
        let client = AppleStoreClient()
        var inventory: [ProductCategory: [AppleProduct]] = [:]
        for category in ProductCategory.allCases {
            let products = try await client.fetchProducts(category: category, bypassCache: true)
            inventory[category] = products
            print("\(category.displayName): \(products.count) current listings")
        }

        guard inventory.values.reduce(0, { $0 + $1.count }) > 0 else {
            throw AppleStoreError.unreadableProductData
        }

        let target = "Refurbished iPhone 16 Pro 256GB - Black Titanium"
        let targetIsPresent = (inventory[.iphone] ?? []).contains {
            ProductTitleMatcher.isCloseMatch(target: target, productName: $0.name)
        }
        print("Requested configuration has a close-enough listing: \(targetIsPresent ? "yes" : "no")")
    }
}
