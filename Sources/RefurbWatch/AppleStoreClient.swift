import Foundation

enum AppleStoreError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case unexpectedPage
    case unreadableProductData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Apple returned an invalid response."
        case .httpStatus(let status):
            "Apple returned HTTP status \(status)."
        case .unexpectedPage:
            "Apple’s refurbished-store page format was not recognized."
        case .unreadableProductData:
            "Apple’s product inventory could not be read."
        }
    }
}

actor AppleStoreClient {
    private struct CacheEntry {
        let fetchedAt: Date
        let products: [AppleProduct]
    }

    private var cache: [ProductCategory: CacheEntry] = [:]
    private let cacheLifetime: TimeInterval = 15
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProducts(category: ProductCategory, bypassCache: Bool = false) async throws -> [AppleProduct] {
        if !bypassCache,
           let entry = cache[category],
           Date().timeIntervalSince(entry.fetchedAt) < cacheLifetime {
            return entry.products
        }

        let url = URL(string: "https://www.apple.com/ca/shop/refurbished/\(category.storePath)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("RefurbWatch/1.0 (macOS; personal stock monitor)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppleStoreError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw AppleStoreError.httpStatus(httpResponse.statusCode)
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw AppleStoreError.unreadableProductData
        }

        let products = try AppleProductHTMLParser.parse(html: html)
        cache[category] = CacheEntry(fetchedAt: Date(), products: products)
        return products
    }
}

enum AppleProductHTMLParser {
    static func parse(html: String) throws -> [AppleProduct] {
        let markerIsPresent = html.contains("REFURB_GRID_BOOTSTRAP") || html.contains("application/ld+json")
        guard markerIsPresent else { throw AppleStoreError.unexpectedPage }

        let pattern = #"<script[^>]+type=[\"']application/ld\+json[\"'][^>]*>(.*?)</script>"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        let range = NSRange(html.startIndex..., in: html)

        var products: [AppleProduct] = []
        for match in regex.matches(in: html, range: range) {
            guard match.numberOfRanges > 1,
                  let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            let json = String(html[jsonRange])
                .replacingOccurrences(of: "&quot;", with: "\"")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = json.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) else { continue }
            products.append(contentsOf: extractProducts(from: object))
        }

        var seen = Set<String>()
        return products.filter { product in
            let key = product.sku ?? product.url.absoluteString
            return seen.insert(key).inserted
        }
    }

    private static func extractProducts(from object: Any) -> [AppleProduct] {
        if let array = object as? [Any] {
            return array.flatMap(extractProducts(from:))
        }

        guard let dictionary = object as? [String: Any] else { return [] }

        var products: [AppleProduct] = []
        if let type = dictionary["@type"] as? String,
           type.caseInsensitiveCompare("Product") == .orderedSame,
           let product = makeProduct(from: dictionary) {
            products.append(product)
        }

        if let graph = dictionary["@graph"] {
            products.append(contentsOf: extractProducts(from: graph))
        }
        if let items = dictionary["itemListElement"] {
            products.append(contentsOf: extractProducts(from: items))
        }
        if let item = dictionary["item"] {
            products.append(contentsOf: extractProducts(from: item))
        }
        return products
    }

    private static func makeProduct(from dictionary: [String: Any]) -> AppleProduct? {
        guard let name = dictionary["name"] as? String else { return nil }
        let urlString = (dictionary["url"] as? String) ?? (dictionary["mainEntityOfPage"] as? String)
        guard let urlString, let url = URL(string: urlString) else { return nil }

        let offer: [String: Any]?
        if let offers = dictionary["offers"] as? [[String: Any]] {
            offer = offers.first
        } else {
            offer = dictionary["offers"] as? [String: Any]
        }

        let price: Decimal?
        if let number = offer?["price"] as? NSNumber {
            price = number.decimalValue
        } else if let string = offer?["price"] as? String {
            price = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))
        } else {
            price = nil
        }

        return AppleProduct(
            name: name,
            url: url,
            price: price,
            currencyCode: offer?["priceCurrency"] as? String,
            sku: offer?["sku"] as? String
        )
    }
}
