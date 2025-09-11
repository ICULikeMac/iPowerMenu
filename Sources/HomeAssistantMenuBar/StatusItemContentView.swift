import AppKit

final class StatusItemContentView: NSView {
    private let label: NSTextField
    var onClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        // Configure a label that can render attributed, multi-line content
        label = NSTextField(labelWithAttributedString: NSAttributedString(string: ""))
        label.isEditable = false
        label.isSelectable = false
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        label.usesSingleLineMode = false

        super.init(frame: frameRect)

        translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        // Center label in the available status bar height
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAttributedTitle(_ title: NSAttributedString) {
        label.attributedStringValue = title
        invalidateIntrinsicContentSize()
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    override var intrinsicContentSize: NSSize {
        // Width expands to fit label; height matches status bar thickness for perfect centering
        let width = label.attributedStringValue.size().width + 6
        return NSSize(width: width, height: NSStatusBar.system.thickness)
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

