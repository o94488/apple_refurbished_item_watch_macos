import Foundation

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

@main
struct TestHarness {
    static func main() throws {
        try expect(
            ProductTitleMatcher.isCloseMatch(
                target: "Refurbished iPhone 16 Pro 256GB - Black Titanium",
                productName: "Refurbished iPhone 16 Pro 256GB - Black Titanium (Unlocked)"
            ),
            "Expected normalized target title to match Apple’s listing title"
        )

        try expect(
            !ProductTitleMatcher.isCloseMatch(
                target: "Refurbished iPhone 16 Pro 256GB - Black Titanium",
                productName: "Refurbished iPhone 16 Pro 512GB - Black Titanium (Unlocked)"
            ),
            "A different storage size must not match"
        )

        try expect(
            !ProductTitleMatcher.isCloseMatch(
                target: "Refurbished iPhone 16 Pro 256GB - Black Titanium",
                productName: "Refurbished iPhone 16 Pro Max 256GB - Black Titanium (Unlocked)"
            ),
            "A different model must not match"
        )

        try expect(
            ProductTitleMatcher.isCloseMatch(
                target: "Refurbished iPad Pro 13-inch M4 256GB Space Black",
                productName: "Refurbished iPad Pro 13-inch (M4) Wi-Fi 256GB with Standard glass – Space Black"
            ),
            "Apple may add unspecified details to a close-enough listing"
        )

        try expect(
            !ProductTitleMatcher.isCloseMatch(
                target: "Refurbished iPhone 16 256GB - Black",
                productName: "Refurbished iPhone 16 256GB - Space Black (Unlocked)"
            ),
            "A longer, conflicting colour name must not match"
        )

        let parsed = ProductDescriptionParser.parse(
            "Please monitor Refurbished iPhone 16 Pro 256GB in Black Titanium on the Apple Canada refurbished website"
        )
        try expect(parsed.category == .iphone, "The iPhone category should be inferred")
        try expect(parsed.detectedDetails.contains("256GB"), "Storage should be detected")
        try expect(parsed.detectedDetails.contains("Black Titanium"), "Colour should be detected")

        let html = """
        <html><script>window.REFURB_GRID_BOOTSTRAP = {};</script>
        <script type="application/ld+json">{"@context":"https://schema.org","@type":"Product","name":"Refurbished iPhone 16 Pro 256GB - Black Titanium (Unlocked)","url":"https://www.apple.com/ca/shop/product/fyn03vc/a","offers":[{"priceCurrency":"CAD","price":1229.00,"sku":"FYN03VC/A"}]}</script>
        </html>
        """
        let products = try AppleProductHTMLParser.parse(html: html)
        try expect(products.count == 1, "One structured product should be parsed")
        try expect(products[0].formattedPrice == "$1,229.00", "CAD price should be formatted")

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = TaskPersistence(fileURL: folder.appendingPathComponent("tasks.json"))
        var task = WatchTask.initialTarget
        task.isMonitoring = true
        task.hasAlertedForCurrentAvailability = true
        try persistence.save([task])
        let loaded = try persistence.load()
        try expect(loaded == [task], "Task state should survive persistence")
        try? FileManager.default.removeItem(at: folder)

        print("All Refurb Watch core tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw TestFailure.failed(message) }
    }
}
