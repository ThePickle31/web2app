import Foundation
import os

actor FaviconFetcher {
    private static let logger = Logger(subsystem: "com.web2app", category: "FaviconFetcher")

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches the highest quality icon for the given URL, trying multiple strategies.
    /// Returns the image data on success, or nil if no icon could be found.
    func fetch(for url: URL) async -> Data? {
        guard let host = url.host() else { return nil }
        let baseURL = url.scheme.map { "\($0)://\(host)" } ?? "https://\(host)"

        // Fetch the page HTML once — multiple strategies parse it
        let html = await fetchHTML(from: baseURL)

        // Strategy 1: Web App Manifest — often has 512x512 icons
        if let html, let data = await fetchFromManifest(html: html, baseURL: baseURL) {
            Self.logger.info("Fetched icon via web manifest for \(host)")
            return data
        }

        // Strategy 2: Parse HTML for largest icon link tag
        if let html, let data = await fetchLargestHTMLIcon(html: html, baseURL: baseURL) {
            Self.logger.info("Fetched icon via HTML link tag for \(host)")
            return data
        }

        // Strategy 3: Apple Touch Icon (usually 180x180)
        for path in ["/apple-touch-icon-precomposed.png", "/apple-touch-icon.png"] {
            if let data = await downloadData(from: "\(baseURL)\(path)") {
                Self.logger.info("Fetched \(path) for \(host)")
                return data
            }
        }

        // Strategy 4: Google Favicon API at max size
        if let data = await downloadData(from: "https://www.google.com/s2/favicons?domain=\(host)&sz=256") {
            Self.logger.info("Fetched icon via Google API for \(host)")
            return data
        }

        // Strategy 5: /favicon.ico (last resort, usually 16x16 or 32x32)
        if let data = await downloadData(from: "\(baseURL)/favicon.ico") {
            Self.logger.info("Fetched favicon.ico for \(host)")
            return data
        }

        Self.logger.info("No icon found for \(host)")
        return nil
    }

    // MARK: - Strategy: Web App Manifest

    private func fetchFromManifest(html: String, baseURL: String) async -> Data? {
        // Find <link rel="manifest" href="...">
        let patterns = [
            #"<link[^>]*rel\s*=\s*"manifest"[^>]*href\s*=\s*"([^"]+)"[^>]*/?\s*>"#,
            #"<link[^>]*href\s*=\s*"([^"]+)"[^>]*rel\s*=\s*"manifest"[^>]*/?\s*>"#
        ]

        guard let manifestHref = firstMatch(patterns: patterns, in: html) else { return nil }
        let manifestURL = resolveURL(manifestHref, base: baseURL)

        guard let manifestData = await downloadData(from: manifestURL),
              let json = try? JSONSerialization.jsonObject(with: manifestData) as? [String: Any],
              let icons = json["icons"] as? [[String: Any]] else {
            return nil
        }

        // Sort icons by size descending, prefer largest
        let sorted = icons.sorted { a, b in
            iconSize(from: a) > iconSize(from: b)
        }

        for icon in sorted {
            guard let src = icon["src"] as? String else { continue }
            let iconURL = resolveURL(src, base: baseURL)
            if let data = await downloadData(from: iconURL), data.count > 500 {
                return data
            }
        }

        return nil
    }

    private func iconSize(from icon: [String: Any]) -> Int {
        guard let sizes = icon["sizes"] as? String else { return 0 }
        // Parse "512x512" or "192x192"
        let parts = sizes.lowercased().split(separator: "x")
        return Int(parts.first ?? "0") ?? 0
    }

    // MARK: - Strategy: Largest HTML Icon

    private func fetchLargestHTMLIcon(html: String, baseURL: String) async -> Data? {
        // Find all <link> tags with rel containing "icon"
        let pattern = #"<link[^>]*rel\s*=\s*"[^"]*icon[^"]*"[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        struct IconCandidate {
            let href: String
            let size: Int
        }

        var candidates: [IconCandidate] = []

        for match in matches {
            guard let matchRange = Range(match.range, in: html) else { continue }
            let tag = String(html[matchRange])

            // Extract href
            guard let href = extractAttribute("href", from: tag) else { continue }

            // Extract size from sizes attribute or type
            let size: Int
            if let sizes = extractAttribute("sizes", from: tag) {
                let parts = sizes.lowercased().split(separator: "x")
                size = Int(parts.first ?? "0") ?? 0
            } else if tag.contains("svg") || tag.contains("image/svg") {
                size = 1024 // SVGs scale infinitely, prefer them
            } else {
                size = 1 // Unknown size, low priority
            }

            candidates.append(IconCandidate(href: href, size: size))
        }

        // Sort by size descending
        let sorted = candidates.sorted { $0.size > $1.size }

        for candidate in sorted {
            let iconURL = resolveURL(candidate.href, base: baseURL)
            // Skip tiny favicons (likely 16x16 .ico files)
            if let data = await downloadData(from: iconURL), data.count > 500 {
                return data
            }
        }

        return nil
    }

    // MARK: - Helpers

    private func fetchHTML(from urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await session.data(from: url),
              let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        return html
    }

    private func downloadData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  !data.isEmpty else {
                return nil
            }
            return data
        } catch {
            Self.logger.debug("Download failed for \(urlString): \(error.localizedDescription)")
            return nil
        }
    }

    private func resolveURL(_ href: String, base: String) -> String {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return href
        } else if href.hasPrefix("//") {
            return "https:\(href)"
        } else if href.hasPrefix("/") {
            return "\(base)\(href)"
        } else {
            return "\(base)/\(href)"
        }
    }

    private func firstMatch(patterns: [String], in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: range),
                  let hrefRange = Range(match.range(at: 1), in: text) else {
                continue
            }
            return String(text[hrefRange])
        }
        return nil
    }

    private func extractAttribute(_ name: String, from tag: String) -> String? {
        let pattern = #"\#(name)\s*=\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(tag.startIndex..., in: tag)
        guard let match = regex.firstMatch(in: tag, range: range),
              let valueRange = Range(match.range(at: 1), in: tag) else {
            return nil
        }
        return String(tag[valueRange])
    }
}
