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

        // Add embedded power flow view
        let powerFlowHostingView = NSHostingView(rootView: CompactPowerFlowView(menuBarController: self))
        powerFlowHostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 230)

        let powerFlowMenuItem = NSMenuItem()
        powerFlowMenuItem.view = powerFlowHostingView
        menu.addItem(powerFlowMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Add menu items for display entities only (filter out internal entities)
        for entityType in EntityType.allCases where entityType.isDisplayEntity {
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
            var newValues: [EntityType: String] = [:]
            var successfulFetches = 0
            let totalEntities = allConfiguredEntities.count

            // Fetch data for ALL configured entities with individual error handling
            for entityConfig in allConfiguredEntities {
                do {
                    let entityData = try await homeAssistantClient.getEntityState(entityId: entityConfig.entityId)
                    let formattedValue = formatValue(entityData.state, unitType: entityConfig.unitType)
                    newValues[entityConfig.type] = formattedValue
                    successfulFetches += 1
                } catch {
                    // Log individual entity failure but continue with others
                    NSLog("Failed to fetch \(entityConfig.type.displayName) (\(entityConfig.entityId)): \(error)")

                    // Set appropriate fallback value based on unit type
                    switch entityConfig.unitType {
                    case .watts:
                        newValues[entityConfig.type] = "N/A"
                    case .percentage:
                        newValues[entityConfig.type] = "N/A"
                    case .currency:
                        newValues[entityConfig.type] = "N/A"
                    }
                }
            }

            // Update entity values with what we successfully fetched
            for (entityType, value) in newValues {
                self.entityValues[entityType] = value
            }

            // Determine connection status based on success rate
            if successfulFetches == 0 && totalEntities > 0 {
                // Complete failure - no entities could be fetched
                self.connectionStatus = .error
                NSLog("Failed to fetch any entities - connection error")
                self.updateMenuBarForError(HomeAssistantError.networkError(NSError(domain: "iPowerMenu", code: 0, userInfo: [NSLocalizedDescriptionKey: "No entities could be fetched"])))
            } else if successfulFetches < totalEntities {
                // Partial success - some entities failed
                self.connectionStatus = .connected
                NSLog("Partial success: \(successfulFetches)/\(totalEntities) entities fetched successfully")
                self.updateMenuBar()
            } else {
                // Complete success
                self.connectionStatus = .connected
                self.updateMenuBar()
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
            let displayEntities = EntityType.allCases.filter { $0.isDisplayEntity }
            for (index, entityType) in displayEntities.enumerated() {
                // Offset by 2 to account for power flow view and separator at the beginning
                menu.item(at: index + 2)?.title = "\(entityType.displayName): Not configured"
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
            let displayEntities = EntityType.allCases.filter { $0.isDisplayEntity }
            for (index, entityType) in displayEntities.enumerated() {
                // Offset by 2 to account for power flow view and separator at the beginning
                menu.item(at: index + 2)?.title = "\(entityType.displayName): \(errorMessage)"
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
            // Update display entity menu items
            let displayEntities = EntityType.allCases.filter { $0.isDisplayEntity }
            for (index, entityType) in displayEntities.enumerated() {
                let value = entityValues[entityType] ?? "---"
                let displayName = getDisplayName(for: entityType, value: value)
                // Offset by 2 to account for power flow view and separator at the beginning
                menu.item(at: index + 2)?.title = "\(displayName): \(value)"
            }

            let statusText = connectionStatus == .connected ? "✅ Connected" :
                           connectionStatus == .error ? "❌ Connection Error" : "⚠️ Disconnected"

            // Status item is after the entities and separator (index = displayEntityCount + 3)
            let statusIndex = displayEntities.count + 3
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
        case .currency:
            return formatCurrency(value)
        }
    }
    
    private func getDisplayName(for entityType: EntityType, value: String) -> String {
        if entityType == .gridUsage {
            // Always show "Grid" - the positive/negative value indicates import/export
            return "Grid"
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
        if value == "N/A" {
            return "N/A"
        }
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
        if value == "N/A" {
            return "N/A"
        }
        if let percentage = Double(value) {
            return String(format: "%.0f%%", percentage)
        }
        return "---%"
    }

    private func formatCurrency(_ value: String) -> String {
        if value == "N/A" {
            return "N/A"
        }
        if let price = Double(value) {
            return String(format: "$%.3f/kWh", price)
        }
        return "$---.---/kWh"
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}
