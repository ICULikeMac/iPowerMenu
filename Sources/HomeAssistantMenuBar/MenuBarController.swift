import AppKit
import SwiftUI
import Foundation

/// Controls the macOS menu bar status item and manages data refresh from Home Assistant
/// Displays user-selected entities in a stacked vertical layout with SF Symbols
class MenuBarController: ObservableObject {
    // MARK: - Constants
    private static let menuBarFontSize: CGFloat = 10
    private static let lineHeightMultiple: CGFloat = 0.85
    
    // MARK: - Properties
    private var statusItem: NSStatusItem
    private var contentView: StatusItemContentView?
    private let homeAssistantClient = HomeAssistantClient()
    private var refreshTimer: Timer?
    
    @Published var entityValues: [EntityType: String] = [:]
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case error
    }
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenuBar()
        
        if Settings.shared.isConfigured {
            startRefreshTimer()
        } else {
            showFirstRunSetup()
        }
    }
    
    private func setupMenuBar() {
        let menu = NSMenu()
        
        // Add menu items for all configured entities (not just displayed ones)
        for entityType in EntityType.allCases {
            menu.addItem(withTitle: "\(entityType.displayName): ---", action: nil, keyEquivalent: "")
        }
        
        menu.addItem(NSMenuItem.separator())
        let refreshItem = menu.addItem(withTitle: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        
        let settingsItem = menu.addItem(withTitle: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        
        statusItem.menu = menu

        // Install custom vertically-centered content view for stacked layout
        let view = StatusItemContentView()
        view.onClick = { [weak self] in
            guard let self = self else { return }
            // For custom views, we need to manually trigger the menu
            if let menu = self.statusItem.menu {
                self.statusItem.popUpMenu(menu)
            }
        }
        statusItem.view = view
        contentView = view
        
        // Initialize entity values
        for entityType in EntityType.allCases {
            entityValues[entityType] = "---"
        }
        
        updateMenuBarTitle()
    }
    
    @objc private func statusItemClicked() {
        // Menu will show automatically
    }
    
    @objc private func refreshNow() {
        refreshData()
    }
    
    @objc private func showSettings() {
        let settingsWindow = SettingsWindow()
        settingsWindow.show()
    }
    
    private func showFirstRunSetup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let settingsWindow = SettingsWindow()
            settingsWindow.show()
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Settings.shared.refreshInterval, repeats: true) { _ in
            self.refreshData()
        }
        
        // Initial refresh
        refreshData()
    }
    
    func restartWithNewSettings() {
        if Settings.shared.isConfigured {
            startRefreshTimer()
        } else {
            refreshTimer?.invalidate()
            updateMenuBarForNoConnection()
        }
    }
    
    private func refreshData() {
        // Create entity configs for ALL configured entities (for fetching)
        let allConfiguredEntities = EntityType.allCases.compactMap { type in
            let entityId = Settings.shared.getEntityId(for: type)
            return entityId.isEmpty ? nil : EntityConfig(type: type, entityId: entityId)
        }
        
        Task { @MainActor in
            do {
                var newValues: [EntityType: String] = [:]
                
                // Fetch data for ALL configured entities
                for entityConfig in allConfiguredEntities {
                    let entityData = try await homeAssistantClient.getEntityState(entityId: entityConfig.entityId)
                    let formattedValue = formatValue(entityData.state, unitType: entityConfig.unitType)
                    newValues[entityConfig.type] = formattedValue
                }
                
                // Update entity values
                for (entityType, value) in newValues {
                    self.entityValues[entityType] = value
                }
                
                self.connectionStatus = .connected
                self.updateMenuBar()
            } catch {
                NSLog("Error refreshing Home Assistant data: \(error)")
                self.connectionStatus = .error
                self.updateMenuBarForError(error)
            }
        }
    }
    
    private func updateMenuBarForNoConnection() {
        // Reset all entity values
        for entityType in EntityType.allCases {
            entityValues[entityType] = "---"
        }
        
        updateMenuBarTitle()
        
        if let menu = statusItem.menu {
            for (index, entityType) in EntityType.allCases.enumerated() {
                menu.item(at: index)?.title = "\(entityType.displayName): Not configured"
            }
        }
    }
    
    private func updateMenuBarForError(_ error: Error) {
        // Reset all entity values to show error state
        for entityType in EntityType.allCases {
            entityValues[entityType] = "---"
        }
        
        updateMenuBarTitle()
        
        if let menu = statusItem.menu {
            let errorMessage = getErrorMessage(for: error)
            for (index, entityType) in EntityType.allCases.enumerated() {
                menu.item(at: index)?.title = "\(entityType.displayName): \(errorMessage)"
            }
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let haError = error as? HomeAssistantError {
            switch haError {
            case .unauthorized:
                return "Check access token"
            case .notFound:
                return "Entity not found"
            case .invalidURL:
                return "Invalid URL"
            case .networkError(_):
                return "Connection failed"
            default:
                return "Error"
            }
        }
        return "Error"
    }
    
    private func updateMenuBarTitle() {
        let attributed = NSMutableAttributedString()
        let displayedEntities = Settings.shared.displayedEntityConfigs

        // Two stacked lines; keep sizes small to fit menu bar height
        let font = NSFont.systemFont(ofSize: Self.menuBarFontSize, weight: .regular)
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular)
        // Calculate proper baseline offset using capHeight for consistent icon alignment
        let iconSize = font.pointSize
        let baselineOffset = (font.capHeight - iconSize).rounded() / 2

        // Build menu bar title with selected entities
        for (index, entityConfig) in displayedEntities.enumerated() {
            // Add icon
            if let iconBase = NSImage(systemSymbolName: entityConfig.sfSymbolName, accessibilityDescription: nil),
               let icon = iconBase.withSymbolConfiguration(symbolConfig) {
                let iconAttachment = NSTextAttachment()
                iconAttachment.image = icon
                iconAttachment.bounds = CGRect(x: 0, y: baselineOffset, width: icon.size.width, height: icon.size.height)
                attributed.append(NSAttributedString(attachment: iconAttachment))
            }
            
            // Add value
            let value = entityValues[entityConfig.type] ?? "---"
            attributed.append(NSAttributedString(string: " \(value)", attributes: [.font: font]))

            // Add newline between entities (but not after the last one)
            if index < displayedEntities.count - 1 {
                attributed.append(NSAttributedString(string: "\n"))
            }
        }

        // Left-align both lines with proper line spacing control
        let para = NSMutableParagraphStyle()
        para.alignment = .left
        para.lineSpacing = 0
        para.lineHeightMultiple = Self.lineHeightMultiple
        let lineH = max(10.5, Double(font.ascender - font.descender + font.leading))
        para.minimumLineHeight = CGFloat(lineH)
        para.maximumLineHeight = CGFloat(lineH)
        attributed.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: attributed.length))

        if let view = contentView {
            view.setAttributedTitle(attributed)
            statusItem.length = view.intrinsicContentSize.width
        } else if let button = statusItem.button {
            button.attributedTitle = attributed
        }
    }

    
    
    private func updateMenuBar() {
        updateMenuBarTitle()
        
        if let menu = statusItem.menu {
            // Update all entity menu items
            for (index, entityType) in EntityType.allCases.enumerated() {
                let value = entityValues[entityType] ?? "---"
                let displayName = getDisplayName(for: entityType, value: value)
                menu.item(at: index)?.title = "\(displayName): \(value)"
            }
            
            let statusText = connectionStatus == .connected ? "✅ Connected" : 
                           connectionStatus == .error ? "❌ Connection Error" : "⚠️ Disconnected"
            
            // Status item is after the entities and separator (index = entityCount + 1)
            let statusIndex = EntityType.allCases.count + 1
            if menu.numberOfItems > statusIndex {
                menu.item(at: statusIndex)?.title = "Status: \(statusText)"
            } else {
                menu.insertItem(withTitle: "Status: \(statusText)", action: nil, keyEquivalent: "", at: statusIndex)
            }
            
        }
    }
    
    private func formatValue(_ value: String, unitType: UnitType) -> String {
        switch unitType {
        case .watts:
            return formatWatts(value)
        case .percentage:
            return formatPercentage(value)
        }
    }
    
    private func getDisplayName(for entityType: EntityType, value: String) -> String {
        if entityType == .gridUsage {
            // For grid usage, show "Grid Export" if the value is negative (indicating export)
            if let numericValue = extractNumericValue(from: value), numericValue < 0 {
                return "Grid Export"
            } else {
                return "Grid Usage"
            }
        }
        return entityType.displayName
    }
    
    private func extractNumericValue(from formattedValue: String) -> Double? {
        // Extract numeric value from formatted strings like "1250W", "-500W", "85%", etc.
        let cleanedValue = formattedValue.replacingOccurrences(of: "W", with: "")
                                      .replacingOccurrences(of: "%", with: "")
                                      .trimmingCharacters(in: .whitespaces)
        return Double(cleanedValue)
    }
    
    private func formatWatts(_ value: String) -> String {
        if let watts = Double(value) {
            let formatted = String(format: "%.0f", watts)
            if formatted.count == 1 {
                return "\(formatted) W"
            } else {
                return "\(formatted)W"
            }
        }
        return "---"
    }
    
    private func formatPercentage(_ value: String) -> String {
        if let percentage = Double(value) {
            return String(format: "%.0f%%", percentage)
        }
        return "---%"
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}
