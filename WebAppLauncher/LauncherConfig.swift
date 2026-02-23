import Foundation

struct LauncherConfig {
    let url: URL
    let appName: String
    let allowedDomains: [String]

    init() throws {
        guard let configURL = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: configURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let urlString = dict["URL"] as? String,
              let url = URL(string: urlString),
              let appName = dict["AppName"] as? String else {
            throw LauncherError.configNotFound
        }

        self.url = url
        self.appName = appName
        self.allowedDomains = dict["AllowedDomains"] as? [String] ?? []
    }

    var allAllowedDomains: [String] {
        var domains = allowedDomains
        if let host = url.host() {
            domains.append(host)
            if host.hasPrefix("www.") {
                domains.append(String(host.dropFirst(4)))
            } else {
                domains.append("www.\(host)")
            }
        }
        return domains
    }
}

enum LauncherError: LocalizedError {
    case configNotFound

    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Configuration file not found. This app may be corrupted."
        }
    }
}
