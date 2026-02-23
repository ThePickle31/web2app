import AppKit

extension NSImage {
    /// Returns a new image resized to the specified dimensions using high-quality interpolation.
    func resized(to size: NSSize) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            self.draw(
                in: rect,
                from: NSRect(origin: .zero, size: self.size),
                operation: .copy,
                fraction: 1.0
            )
            return true
        }
    }

    /// Returns the PNG data representation of the image, or nil if conversion fails.
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
