import AppKit
import Foundation
import os

struct IconGenerator {
    private static let logger = Logger(subsystem: "com.web2app", category: "IconGenerator")

    private static let iconSizes: [(size: Int, scale: Int, suffix: String)] = [
        (16, 1, "16x16"),
        (16, 2, "16x16@2x"),
        (32, 1, "32x32"),
        (32, 2, "32x32@2x"),
        (128, 1, "128x128"),
        (128, 2, "128x128@2x"),
        (256, 1, "256x256"),
        (256, 2, "256x256@2x"),
        (512, 1, "512x512"),
        (512, 2, "512x512@2x")
    ]

    /// Converts an NSImage into .icns data using iconutil.
    /// Creates a temporary .iconset directory with properly named PNGs,
    /// then runs `iconutil -c icns` to produce the .icns file.
    static func generateICNS(from image: NSImage) throws -> Data {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let iconsetDirectory = tempDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)
        let icnsOutputURL = tempDirectory.appendingPathComponent("AppIcon.icns")

        defer {
            try? fileManager.removeItem(at: tempDirectory)
        }

        try fileManager.createDirectory(at: iconsetDirectory, withIntermediateDirectories: true)

        // Generate each icon size as a PNG
        for entry in iconSizes {
            let pixelSize = entry.size * entry.scale
            let resized = image.resized(to: NSSize(width: pixelSize, height: pixelSize))

            guard let pngData = resized.pngData() else {
                throw IconGeneratorError.pngConversionFailed(size: pixelSize)
            }

            let filename = "icon_\(entry.suffix).png"
            let fileURL = iconsetDirectory.appendingPathComponent(filename)
            try pngData.write(to: fileURL)
        }

        // Run iconutil to create .icns from .iconset
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetDirectory.path(percentEncoded: false), "-o", icnsOutputURL.path(percentEncoded: false)]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            logger.error("iconutil failed: \(errorMessage)")
            throw IconGeneratorError.iconutilFailed(errorMessage)
        }

        let icnsData = try Data(contentsOf: icnsOutputURL)
        logger.info("Generated .icns file (\(icnsData.count) bytes)")
        return icnsData
    }
}

enum IconGeneratorError: LocalizedError {
    case pngConversionFailed(size: Int)
    case iconutilFailed(String)

    var errorDescription: String? {
        switch self {
        case .pngConversionFailed(let size):
            return "Failed to convert image to PNG at size \(size)x\(size)"
        case .iconutilFailed(let message):
            return "iconutil failed: \(message)"
        }
    }
}
