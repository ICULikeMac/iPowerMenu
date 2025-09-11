import SwiftUI
import AppKit

class SettingsWindow: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Home Assistant Settings"
        window.center()
        window.isReleasedWhenClosed = false
        
        // Enable proper text editing and menu support
        window.makeFirstResponder(nil)
        
        let hostingView = NSHostingView(rootView: SettingsView())
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var homeAssistantURL: String = ""
    @State private var accessToken: String = ""
    @State private var solarEntityId: String = ""
    @State private var batteryEntityId: String = ""
    @State private var refreshInterval: Double = 30.0
    @State private var isTestingConnection = false
    @State private var testResult: String? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Assistant Configuration")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Home Assistant URL:")
                    TextField("http://homeassistant.local:8123", text: $homeAssistantURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onTapGesture {
                            // Ensure text field can receive focus
                        }
                    
                    Text("Long-lived Access Token:")
                    TextField("Your access token", text: $accessToken)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onTapGesture {
                            // Ensure text field can receive focus
                        }
                    
                    Text("Solar Power Entity ID:")
                    TextField("sensor.solar_power", text: $solarEntityId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onTapGesture {
                            // Ensure text field can receive focus
                        }
                    
                    Text("Battery SOC Entity ID:")
                    TextField("sensor.battery_soc", text: $batteryEntityId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onTapGesture {
                            // Ensure text field can receive focus
                        }
                    
                    Text("Refresh Interval (seconds):")
                    HStack {
                        Slider(value: $refreshInterval, in: 10...300, step: 5)
                        Text("\(Int(refreshInterval))s")
                            .frame(width: 40)
                    }
                }
            }
            
            HStack {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTestingConnection || homeAssistantURL.isEmpty || accessToken.isEmpty)
                
                if isTestingConnection {
                    ProgressView()
                        .scaleEffect(0.5)
                }
                
                if let result = testResult {
                    Text(result)
                        .foregroundColor(result.contains("Success") ? .green : .red)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    loadCurrentSettings()
                    closeWindow()
                }
                
                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .disabled(homeAssistantURL.isEmpty || accessToken.isEmpty || solarEntityId.isEmpty || batteryEntityId.isEmpty)
                
                // Debug info
                if homeAssistantURL.isEmpty || accessToken.isEmpty || solarEntityId.isEmpty || batteryEntityId.isEmpty {
                    Text("(Fill all fields)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .frame(width: 500, height: 500)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        homeAssistantURL = settings.homeAssistantURL ?? ""
        accessToken = settings.accessToken
        solarEntityId = settings.solarEntityId
        batteryEntityId = settings.batteryEntityId
        refreshInterval = settings.refreshInterval
    }
    
    private func saveSettings() {
        print("💾 Saving settings...")
        print("🏠 URL: \(homeAssistantURL)")
        print("🔑 Token: \(accessToken.prefix(10))...")
        print("⚡️ Solar: \(solarEntityId)")
        print("🔋 Battery: \(batteryEntityId)")
        
        settings.homeAssistantURL = homeAssistantURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.accessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.solarEntityId = solarEntityId.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.batteryEntityId = batteryEntityId.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.refreshInterval = refreshInterval
        
        print("✅ Settings saved to UserDefaults")
        print("⚙️ Settings now configured: \(settings.isConfigured)")
        
        // Notify MenuBarController to restart with new settings
        if let appDelegate = AppDelegate.shared {
            print("📡 Notifying MenuBarController to restart...")
            appDelegate.menuBarController?.restartWithNewSettings()
        } else {
            print("❌ AppDelegate.shared is nil!")
        }
        
        alertMessage = "Settings saved successfully! Data refresh started."
        showingAlert = true
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        let tempSettings = Settings.shared
        let originalURL = tempSettings.homeAssistantURL
        let originalToken = tempSettings.accessToken
        
        tempSettings.homeAssistantURL = homeAssistantURL
        tempSettings.accessToken = accessToken
        
        let client = HomeAssistantClient()
        
        Task {
            do {
                let success = try await client.testConnection()
                await MainActor.run {
                    testResult = success ? "✅ Connection successful" : "❌ Connection failed"
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ \(error.localizedDescription)"
                    isTestingConnection = false
                }
            }
            
            tempSettings.homeAssistantURL = originalURL
            tempSettings.accessToken = originalToken
        }
    }
    
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}