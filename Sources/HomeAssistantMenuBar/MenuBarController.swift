import AppKit
import SwiftUI
import Foundation

class MenuBarController: ObservableObject {
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
        print("🚀 MenuBarController initializing...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenuBar()
        
        print("⚙️ Settings configured: \(Settings.shared.isConfigured)")
        print("🏠 HA URL: \(Settings.shared.homeAssistantURL ?? "nil")")
        print("🔑 Token length: \(Settings.shared.accessToken.count)")
        
        if Settings.shared.isConfigured {
            print("✅ Configuration found, starting timer")
            startRefreshTimer()
        } else {
            print("❌ No configuration, showing setup")
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
            guard let self, let menu = self.statusItem.menu else { return }
            self.statusItem.popUpMenu(menu)
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
        print("🔧 Restarting with new settings...")
        print("⚙️ Settings configured: \(Settings.shared.isConfigured)")
        
        if Settings.shared.isConfigured {
            print("🚀 Starting refresh timer...")
            startRefreshTimer()
        } else {
            print("❌ Settings not configured, stopping timer")
            refreshTimer?.invalidate()
            updateMenuBarForNoConnection()
        }
    }
    
    private func refreshData() {
        print("🔄 Starting data refresh...")
        print("🏠 HA URL: \(Settings.shared.homeAssistantURL ?? "nil")")
        
        // Create entity configs for ALL configured entities (for fetching)
        let allConfiguredEntities = EntityType.allCases.compactMap { type in
            let entityId = Settings.shared.getEntityId(for: type)
            return entityId.isEmpty ? nil : EntityConfig(type: type, entityId: entityId)
        }
        
        // Get the selected entities for display purposes
        let displayedEntities = Settings.shared.displayedEntityConfigs
        
        print("📊 All configured entities: \(allConfiguredEntities.map { "\($0.displayName): \($0.entityId)" }.joined(separator: ", "))")
        print("🖥️ Displayed entities: \(displayedEntities.map { "\($0.displayName): \($0.entityId)" }.joined(separator: ", "))")
        
        Task {
            do {
                var newValues: [EntityType: String] = [:]
                
                // Fetch data for ALL configured entities
                for entityConfig in allConfiguredEntities {
                    print("📡 Fetching \(entityConfig.displayName) data...")
                    let entityData = try await homeAssistantClient.getEntityState(entityId: entityConfig.entityId)
                    print("📊 \(entityConfig.displayName) data received: \(entityData.state)")
                    
                    let formattedValue = formatValue(entityData.state, unitType: entityConfig.unitType)
                    newValues[entityConfig.type] = formattedValue
                }
                
                await MainActor.run {
                    // Update entity values
                    for (entityType, value) in newValues {
                        self.entityValues[entityType] = value
                    }
                    
                    self.connectionStatus = .connected
                    print("✅ All entity values updated: \(newValues)")
                    self.updateMenuBar()
                    print("🎯 Menu bar updated")
                }
            } catch {
                print("❌ Error during refresh: \(error)")
                await MainActor.run {
                    self.connectionStatus = .error
                    self.updateMenuBar()
                }
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
    
    private func updateMenuBarTitle() {
        let attributed = NSMutableAttributedString()
        let displayedEntities = Settings.shared.displayedEntityConfigs

        // Two stacked lines; keep sizes small to fit menu bar height
        let font = NSFont.systemFont(ofSize: 10, weight: .regular)
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
        para.lineHeightMultiple = 0.85  // Reduces line spacing instead of negative paragraphSpacing
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
            
            let displayedEntities = Settings.shared.displayedEntityConfigs
            let entitySummary = displayedEntities.map { "\($0.displayName): \(entityValues[$0.type] ?? "---")" }.joined(separator: ", ")
            let allEntitySummary = EntityType.allCases.map { "\($0.displayName): \(entityValues[$0] ?? "---")" }.joined(separator: ", ")
            print("📋 Menu bar display - \(entitySummary)")
            print("📋 All entities - \(allEntitySummary), Status: \(statusText)")
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
