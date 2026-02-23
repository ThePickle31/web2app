import SwiftUI

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassModifier())
    }
}
