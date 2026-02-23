import SwiftUI

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
        }
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassModifier())
    }
}
