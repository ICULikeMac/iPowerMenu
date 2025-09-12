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
    @State private var entityIds: [EntityType: String] = [:]
    @State private var selectedEntityTypes: Set<EntityType> = []
    @State private var refreshInterval: Double = 30.0
    @State private var isTestingConnection = false
    @State private var testResult: String? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Home Assistant Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Connection Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connection Settings")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Group {
                        Text("Home Assistant URL:")
                        TextField("http://homeassistant.local:8123", text: $homeAssistantURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Long-lived Access Token:")
                        TextField("Your access token", text: $accessToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Entity Configuration Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Entity Configuration")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Configure the entity IDs for all sensors:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(EntityType.allCases, id: \.self) { entityType in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entityType.displayName) Entity ID:")
                            TextField(entityType.defaultEntityId, text: Binding(
                                get: { entityIds[entityType] ?? "" },
                                set: { entityIds[entityType] = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Menu Bar Display Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Menu Bar Display")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Select exactly 2 entities to display in the menu bar:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(EntityType.allCases, id: \.self) { entityType in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { selectedEntityTypes.contains(entityType) },
                                    set: { isSelected in
                                        if isSelected {
                                            if selectedEntityTypes.count < 2 {
                                                selectedEntityTypes.insert(entityType)
                                            }
                                        } else {
                                            selectedEntityTypes.remove(entityType)
                                        }
                                    }
                                ))
                                .disabled(selectedEntityTypes.count >= 2 && !selectedEntityTypes.contains(entityType))
                                .frame(width: 20)
                                
                                Text(entityType.displayName)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 10)
                    
                    if selectedEntityTypes.count != 2 {
                        Text("Select exactly 2 entities (\(selectedEntityTypes.count)/2 selected)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Refresh Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Refresh Settings")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Refresh Interval (seconds):")
                    HStack {
                        Slider(value: $refreshInterval, in: 10...300, step: 5)
                        Text("\(Int(refreshInterval))s")
                            .frame(width: 40)
                    }
                }
                
                // Connection Test
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
                
                // Action buttons
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
                    .disabled(!isValidConfiguration)
                    
                    if !isValidConfiguration {
                        Text("(Complete all fields and select 2 entities)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 550, height: 700)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isValidConfiguration: Bool {
        return !homeAssistantURL.isEmpty && 
               !accessToken.isEmpty && 
               selectedEntityTypes.count == 2 &&
               entityIds.allSatisfy { !$0.value.isEmpty }
    }
    
    private func loadCurrentSettings() {
        homeAssistantURL = settings.homeAssistantURL ?? ""
        accessToken = settings.accessToken
        refreshInterval = settings.refreshInterval
        
        // Load all entity IDs
        for entityType in EntityType.allCases {
            entityIds[entityType] = settings.getEntityId(for: entityType)
        }
        
        // Load selected entity types
        selectedEntityTypes = Set(settings.selectedEntityTypes)
    }
    
    private func saveSettings() {
        print("💾 Saving settings...")
        print("🏠 URL: \(homeAssistantURL)")
        print("🔑 Token: \(accessToken.prefix(10))...")
        
        settings.homeAssistantURL = homeAssistantURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.accessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.refreshInterval = refreshInterval
        
        // Save all entity IDs
        for entityType in EntityType.allCases {
            if let entityId = entityIds[entityType] {
                settings.setEntityId(for: entityType, entityId: entityId.trimmingCharacters(in: .whitespacesAndNewlines))
                print("🏷️ \(entityType.displayName): \(entityId)")
            }
        }
        
        // Save selected entity types
        settings.selectedEntityTypes = Array(selectedEntityTypes)
        print("📊 Selected entities: \(selectedEntityTypes.map { $0.displayName }.joined(separator: ", "))")
        
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