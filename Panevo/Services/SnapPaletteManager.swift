import AppKit
import SwiftUI

/// Interactive grid overlay for picking a snap position (Moom-style palette).
final class SnapPaletteManager {
    private let displayManager: DisplayManager
    private let onSelect: (WindowPosition, CGDirectDisplayID) -> Void
    private var window: NSWindow?
    private var hostingView: NSHostingView<SnapPaletteView>?
    private var cells: [(position: WindowPosition, frame: CGRect)] = []
    private var currentDisplayID: CGDirectDisplayID = 0
    private var highlighted: WindowPosition?

    init(displayManager: DisplayManager, onSelect: @escaping (WindowPosition, CGDirectDisplayID) -> Void) {
        self.displayManager = displayManager
        self.onSelect = onSelect
    }

    func show(on screen: NSScreen) {
        currentDisplayID = screen.displayID
        let visible = screen.visibleFrame
        cells = buildCells(in: visible)

        let root = SnapPaletteView(
            cells: cells.map { ($0.position, $0.frame) },
            highlighted: highlighted,
            screenFrame: visible,
            onClick: { [weak self] position in
                guard let self else { return }
                self.onSelect(position, self.currentDisplayID)
                self.hide()
            }
        )

        if let existing = window, let host = hostingView {
            host.rootView = root
            existing.setFrame(visible, display: true)
            existing.orderFront(nil)
            return
        }

        let host = NSHostingView(rootView: root)
        hostingView = host

        let win = NSWindow(
            contentRect: visible,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.ignoresMouseEvents = false
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.contentView = host
        win.setFrame(visible, display: true)
        win.orderFront(nil)
        window = win
    }

    func hide() {
        highlighted = nil
        window?.orderOut(nil)
    }

    func highlightAt(_ point: CGPoint) {
        highlighted = cells.first { $0.frame.contains(point) }?.position
        refresh()
    }

    func selectAt(_ point: CGPoint) {
        if let cell = cells.first(where: { $0.frame.contains(point) }) {
            onSelect(cell.position, currentDisplayID)
        }
    }

    private func refresh() {
        guard let host = hostingView, let win = window else { return }
        let visible = win.frame
        host.rootView = SnapPaletteView(
            cells: cells.map { ($0.position, $0.frame) },
            highlighted: highlighted,
            screenFrame: visible,
            onClick: { [weak self] position in
                guard let self else { return }
                self.onSelect(position, self.currentDisplayID)
                self.hide()
            }
        )
    }

    private func buildCells(in visible: CGRect) -> [(WindowPosition, CGRect)] {
        let positions: [WindowPosition] = [
            .topLeft, .topHalf, .topRight,
            .leftHalf, .fullScreen, .rightHalf,
            .bottomLeft, .bottomHalf, .bottomRight,
        ]

        let cols = 3
        let rows = 3
        let gap: CGFloat = 10
        let pad: CGFloat = 40
        let usable = visible.insetBy(dx: pad, dy: pad)
        let cellW = (usable.width - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let cellH = (usable.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

        return positions.enumerated().map { index, position in
            let col = index % cols
            let row = index / cols
            let frame = CGRect(
                x: usable.minX + CGFloat(col) * (cellW + gap),
                y: usable.maxY - CGFloat(row + 1) * cellH - CGFloat(row) * gap,
                width: cellW,
                height: cellH
            )
            return (position, frame)
        }
    }
}

struct SnapPaletteView: View {
    let cells: [(WindowPosition, CGRect)]
    let highlighted: WindowPosition?
    let screenFrame: CGRect
    let onClick: (WindowPosition) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { /* dismiss handled by manager hide */ }

            ForEach(Array(cells.enumerated()), id: \.offset) { _, item in
                let position = item.0
                let frame = item.1
                Button {
                    onClick(position)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(highlighted == position ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                            )
                        Image(systemName: position.symbolName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: frame.width, height: frame.height)
                .position(
                    x: frame.midX - screenFrame.minX,
                    y: screenFrame.maxY - frame.midY
                )
            }
        }
        .frame(width: screenFrame.width, height: screenFrame.height)
    }
}
