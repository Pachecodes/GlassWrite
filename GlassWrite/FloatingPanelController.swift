import AppKit
import SwiftUI

final class FloatingPanelController: NSWindowController {
    private let state: AppState

    init(state: AppState) {
        self.state = state
        let root = FloatingOverlayView(state: state)
        let hosting = NSHostingView(rootView: root)
        let panel = NSPanel(
            contentRect: NSRect(x: 880, y: 620, width: 430, height: 260),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.contentView = hosting
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        window?.orderFrontRegardless()
    }
}
