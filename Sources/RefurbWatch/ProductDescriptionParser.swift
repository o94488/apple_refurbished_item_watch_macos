import Foundation

enum ProductDescriptionParser {
    static let knownColours = [
        "Black Titanium", "White Titanium", "Natural Titanium", "Blue Titanium",
        "Desert Titanium", "Space Black", "Space Grey", "Space Gray", "Silver",
        "Starlight", "Midnight", "Sky Blue", "Ultramarine", "Teal", "Purple",
        "Pink", "Yellow", "Green", "Blue", "White", "Black", "Gold", "Orange",
        "Citrus", "Indigo", "Blush"
    ]

    static func parse(_ input: String) -> ParsedProductDescription {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var title = trimmed.replacingOccurrences(of: "\n", with: " ")
        title = title.replacingOccurrences(
            of: #"(?i)^\s*(?:please\s+)?(?:i\s+(?:want|would like)\s+to\s+)?(?:watch|monitor|track|find|look\s+for)\s+(?:the\s+)?(?:stock\s+(?:of|for)\s+)?"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(
            of: #"(?i)^\s*notify\s+me\s+(?:when|if)\s+(?:a|an|the)?\s*"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(
            of: #"(?i)\s+(?:on|from|at)\s+(?:the\s+)?apple(?:\s+canada(?:'s)?)?\s+refurbished(?:\s+store|\s+website)?\s*$"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(
            of: #"(?i)\s+(?:is\s+)?in\s+stock\s*$"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: "-"))))

        if !title.lowercased().hasPrefix("refurbished ") {
            title = "Refurbished " + title
        }

        return ParsedProductDescription(
            original: trimmed,
            exactProductTitle: title,
            category: inferCategory(from: title),
            detectedDetails: detectDetails(in: title)
        )
    }

    static func inferCategory(from description: String) -> ProductCategory {
        let text = description.lowercased()

        if text.contains("iphone") { return .iphone }
        if text.contains("ipad") || text.contains("apple pencil") { return .ipad }
        if text.contains("airpods") { return .airpods }
        if text.contains("apple tv") { return .appleTV }
        if text.contains("homepod") { return .homepod }

        let macTerms = [
            "macbook", "imac", "mac mini", "mac studio", "mac pro",
            "studio display", "pro display"
        ]
        if macTerms.contains(where: text.contains) { return .mac }

        return .accessories
    }

    static func detectDetails(in description: String) -> [String] {
        var details: [String] = []

        let patterns = [
            #"(?i)\b\d+(?:\.\d+)?\s*(?:TB|GB)\b"#,
            #"(?i)\b\d+(?:\.\d+)?[-\s]*(?:inch|core)\b"#,
            #"(?i)\b(?:M\d(?:\s+(?:Pro|Max|Ultra))?|A\d+\s+Pro)\s+chip\b"#,
            #"(?i)\b(?:Wi[-‑–—\s]?Fi|Cellular|GPS)\b"#
        ]

        for pattern in patterns {
            details.append(contentsOf: matches(pattern: pattern, in: description))
        }

        let lowercased = description.lowercased()
        if let colour = knownColours.first(where: { lowercased.contains($0.lowercased()) }) {
            details.append(colour)
        }

        var seen = Set<String>()
        return details.filter { seen.insert($0.lowercased()).inserted }
    }

    private static func matches(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        }
    }
}

enum ProductTitleMatcher {
    /// A directional match: every meaningful detail the user supplied must be
    /// present in Apple's title, while Apple may add unspecified details.
    static func isCloseMatch(target: String, productName: String) -> Bool {
        let targetTokens = signature(target)
        let productTokens = signature(productName)
        guard !targetTokens.isEmpty,
              isMultisetSubset(targetTokens, of: productTokens) else { return false }

        // Variant words are never treated as harmless extras. This prevents an
        // iPhone 16 target from matching iPhone 16 Pro or Pro Max, and prevents
        // a base M-series chip target from matching a Pro/Max/Ultra chip title.
        let variantMarkers: Set<String> = [
            "pro", "max", "plus", "air", "mini", "ultra", "studio", "neo", "se"
        ]
        for marker in variantMarkers {
            guard targetTokens.count(of: marker) == productTokens.count(of: marker) else {
                return false
            }
        }

        // A short colour such as "Black" must not silently match "Space Black."
        if let targetColour = detectedColour(in: targetTokens) {
            guard detectedColour(in: productTokens) == targetColour else { return false }
        }

        // Explicit base connectivity and display finishes remain meaningful.
        // Additions that are part of the same feature name (for example,
        // "GPS + Cellular") remain acceptable.
        let requested = Set(targetTokens)
        let offered = Set(productTokens)
        if requested.contains("wifi"), !requested.contains("cellular"), offered.contains("cellular") {
            return false
        }
        if requested.contains("gps"), !requested.contains("cellular"), offered.contains("cellular") {
            return false
        }
        if requested.contains("standard"), offered.contains("nano") { return false }
        if requested.contains("nano"), offered.contains("standard") { return false }

        return true
    }

    static func isExactMatch(target: String, productName: String) -> Bool {
        isCloseMatch(target: target, productName: productName)
    }

    static func signature(_ value: String) -> [String] {
        var text = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_CA"))
            .lowercased()
        text = text.replacingOccurrences(of: "&", with: " and ")
        text = text.replacingOccurrences(of: "grey", with: "gray")
        text = text.replacingOccurrences(
            of: #"\((?:unlocked|sim\s*[-‑–— ]?free)\)"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(
            of: #"(\d+(?:\.\d+)?)\s+(tb|gb)\b"#,
            with: "$1$2",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: #"wi\s*[-‑–— ]?fi"#, with: "wifi", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)

        let ignoredWords: Set<String> = [
            "a", "an", "the", "apple", "refurbished", "in", "please", "stock",
            "watch", "monitor", "track", "for", "of", "unlocked", "sim", "free",
            "color", "colour", "storage", "capacity", "size"
        ]
        return text.split(separator: " ")
            .map(String.init)
            .filter { !ignoredWords.contains($0) }
            .sorted()
    }

    private static func isMultisetSubset(_ target: [String], of product: [String]) -> Bool {
        var available = Dictionary(product.map { ($0, 1) }, uniquingKeysWith: +)
        for token in target {
            guard let count = available[token], count > 0 else { return false }
            available[token] = count - 1
        }
        return true
    }

    private static func detectedColour(in tokens: [String]) -> [String]? {
        let tokenCounts = Dictionary(tokens.map { ($0, 1) }, uniquingKeysWith: +)
        let signatures = ProductDescriptionParser.knownColours
            .map(signature)
            .sorted { $0.count > $1.count }
        return signatures.first { colourTokens in
            let required = Dictionary(colourTokens.map { ($0, 1) }, uniquingKeysWith: +)
            return required.allSatisfy { token, count in
                (tokenCounts[token] ?? 0) >= count
            }
        }
    }
}

private extension Array where Element == String {
    func count(of value: String) -> Int {
        reduce(into: 0) { count, element in
            if element == value { count += 1 }
        }
    }
}
