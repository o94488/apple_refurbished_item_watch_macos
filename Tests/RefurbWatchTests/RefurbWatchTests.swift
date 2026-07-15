import Foundation
import Testing
@testable import RefurbWatch

@Test("Close matching accepts Apple's fulfillment qualifier")
func closeTitleNormalization() {
    let target = "Refurbished iPhone 16 Pro 256GB - Black Titanium"
    let listing = "Refurbished iPhone 16 Pro 256GB - Black Titanium (Unlocked)"
    #expect(ProductTitleMatcher.isCloseMatch(target: target, productName: listing))
}

@Test("Close matching accepts additional unspecified product details")
func acceptsAdditionalDetails() {
    #expect(ProductTitleMatcher.isCloseMatch(
        target: "Refurbished iPad Pro 13-inch M4 256GB Space Black",
        productName: "Refurbished iPad Pro 13-inch (M4) Wi-Fi 256GB with Standard glass – Space Black"
    ))
}

@Test("Close matching rejects a conflicting configuration")
func rejectsDifferentConfiguration() {
    let target = "Refurbished iPhone 16 Pro 256GB - Black Titanium"
    #expect(!ProductTitleMatcher.isCloseMatch(
        target: target,
        productName: "Refurbished iPhone 16 Pro 512GB - Black Titanium (Unlocked)"
    ))
    #expect(!ProductTitleMatcher.isCloseMatch(
        target: target,
        productName: "Refurbished iPhone 16 Pro 256GB - White Titanium (Unlocked)"
    ))
    #expect(!ProductTitleMatcher.isCloseMatch(
        target: target,
        productName: "Refurbished iPhone 16 Pro Max 256GB - Black Titanium (Unlocked)"
    ))
    #expect(!ProductTitleMatcher.isCloseMatch(
        target: "Refurbished iPhone 16 256GB - Black",
        productName: "Refurbished iPhone 16 256GB - Space Black (Unlocked)"
    ))
}

@Test("Natural-language parsing is local and identifies the category")
func naturalLanguageParsing() {
    let parsed = ProductDescriptionParser.parse(
        "Please monitor Refurbished iPhone 16 Pro 256GB in Black Titanium on the Apple Canada refurbished website"
    )
    #expect(parsed.category == .iphone)
    #expect(parsed.exactProductTitle == "Refurbished iPhone 16 Pro 256GB in Black Titanium")
    #expect(parsed.detectedDetails.contains("256GB"))
    #expect(parsed.detectedDetails.contains("Black Titanium"))
}

@Test("Structured Apple product data is parsed")
func htmlInventoryParsing() throws {
    let html = """
    <html><script>window.REFURB_GRID_BOOTSTRAP = {};</script>
    <script type="application/ld+json">{"@context":"https://schema.org","@type":"Product","name":"Refurbished iPhone 16 Pro 256GB - Black Titanium (Unlocked)","url":"https://www.apple.com/ca/shop/product/fyn03vc/a","offers":[{"priceCurrency":"CAD","price":1229.00,"sku":"FYN03VC/A"}]}</script>
    </html>
    """
    let products = try AppleProductHTMLParser.parse(html: html)
    #expect(products.count == 1)
    #expect(products[0].name.contains("iPhone 16 Pro"))
    #expect(products[0].formattedPrice == "$1,229.00")
    #expect(products[0].sku == "FYN03VC/A")
}

@Test("Task persistence retains monitoring and alert state")
func persistenceRoundTrip() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let file = folder.appendingPathComponent("tasks.json")
    let persistence = TaskPersistence(fileURL: file)
    var task = WatchTask.initialTarget
    task.isMonitoring = true
    task.hasAlertedForCurrentAvailability = true
    task.status = .inStock
    task.lastCheckedAt = Date(timeIntervalSince1970: 1_700_000_000)

    try persistence.save([task])
    let loaded = try #require(persistence.load())
    #expect(loaded == [task])

    try? FileManager.default.removeItem(at: folder)
}
