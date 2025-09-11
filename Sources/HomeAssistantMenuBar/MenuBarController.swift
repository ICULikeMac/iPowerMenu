import AppKit
import SwiftUI
import Foundation

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem
    private var contentView: StatusItemContentView?
    private let homeAssistantClient = HomeAssistantClient()
    private var refreshTimer: Timer?
    
    @Published var solarWatts: String = "---"
    @Published var batterySOC: String = "---"
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
        
        menu.addItem(withTitle: "Solar: --- watts", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Battery: ---%", action: nil, keyEquivalent: "")
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
        updateMenuBarTitle(solar: "---", battery: "---%")
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
        print("⚡️ Solar Entity: \(Settings.shared.solarEntityId)")
        print("🔋 Battery Entity: \(Settings.shared.batteryEntityId)")
        
        Task {
            do {
                print("📡 Fetching solar data...")
                let solarData = try await homeAssistantClient.getEntityState(entityId: Settings.shared.solarEntityId)
                print("⚡️ Solar data received: \(solarData.state)")
                
                print("📡 Fetching battery data...")
                let batteryData = try await homeAssistantClient.getEntityState(entityId: Settings.shared.batteryEntityId)
                print("🔋 Battery data received: \(batteryData.state)")
                
                await MainActor.run {
                    self.solarWatts = formatWatts(solarData.state)
                    self.batterySOC = formatPercentage(batteryData.state)
                    self.connectionStatus = .connected
                    print("✅ Formatted values - Solar: \(self.solarWatts), Battery: \(self.batterySOC)")
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
        updateMenuBarTitle(solar: "---", battery: "---")
        
        if let menu = statusItem.menu {
            menu.item(at: 0)?.title = "Solar: Not configured"
            menu.item(at: 1)?.title = "Battery: Not configured"
        }
    }
    
    private func updateMenuBarTitle(solar: String, battery: String) {
        let attributed = NSMutableAttributedString()

            // Two stacked lines; keep sizes small to fit menu bar height
            let font = NSFont.systemFont(ofSize: 10, weight: .regular)
            let symbolConfig = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular)
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            // A tiny downward nudge to visually center (Retina-safe)
            let baselineNudge = -1.0 / scale

            // Line 1: Sun + solar value
            if let sunBase = NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil),
               let sun = sunBase.withSymbolConfiguration(symbolConfig) {
                let sunAttachment = NSTextAttachment()
                sunAttachment.image = sun
                sunAttachment.bounds = CGRect(x: 0, y: baselineNudge, width: sun.size.width, height: sun.size.height)
                attributed.append(NSAttributedString(attachment: sunAttachment))
            }
            attributed.append(NSAttributedString(string: " \(solar)", attributes: [.font: font, .baselineOffset: baselineNudge]))

            // Newline to stack
            attributed.append(NSAttributedString(string: "\n"))

            // Line 2: Battery + percent
            if let battBase = NSImage(systemSymbolName: "battery.75percent", accessibilityDescription: nil),
               let batt = battBase.withSymbolConfiguration(symbolConfig) {
                let battAttachment = NSTextAttachment()
                battAttachment.image = batt
                battAttachment.bounds = CGRect(x: 0, y: baselineNudge, width: batt.size.width, height: batt.size.height)
                attributed.append(NSAttributedString(attachment: battAttachment))
            }
            attributed.append(NSAttributedString(string: " \(battery)", attributes: [.font: font, .baselineOffset: baselineNudge]))

            // Center both lines; pin line heights to fit status bar
            let para = NSMutableParagraphStyle()
            para.alignment = .center
            para.lineSpacing = 0
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
        updateMenuBarTitle(solar: solarWatts, battery: batterySOC)
        
        if let menu = statusItem.menu {
            menu.item(at: 0)?.title = "Solar: \(solarWatts) watts"
            menu.item(at: 1)?.title = "Battery: \(batterySOC)"
            
            let statusText = connectionStatus == .connected ? "✅ Connected" : 
                           connectionStatus == .error ? "❌ Connection Error" : "⚠️ Disconnected"
            
            // Update or add status item at index 2 (after the separator)
            if menu.numberOfItems > 3 {
                menu.item(at: 3)?.title = "Status: \(statusText)"
            } else {
                menu.insertItem(withTitle: "Status: \(statusText)", action: nil, keyEquivalent: "", at: 3)
            }
            
            print("📋 Menu updated - Solar: \(solarWatts), Battery: \(batterySOC), Status: \(statusText)")
        }
    }
    
    private func formatWatts(_ value: String) -> String {
        if let watts = Double(value) {
            return String(format: "%.0fw", watts)
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
