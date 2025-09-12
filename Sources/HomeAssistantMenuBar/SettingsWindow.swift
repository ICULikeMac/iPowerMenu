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
        
        window.title = "iPowerMenu Settings"
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
    @State private var topEntity: EntityType? = nil
    @State private var bottomEntity: EntityType? = nil
    @State private var refreshInterval: Double = 30.0
    @State private var isTestingConnection = false
    @State private var testResult: String? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("iPowerMenu Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Home Assistant Configuration Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                        Text("Home Assistant Configuration")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("Home Assistant URL:")
                            TextField("http://homeassistant.local:8123", text: $homeAssistantURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Long-lived Access Token:")
                            TextField("Your access token", text: $accessToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    }
                    .padding(.leading, 20)
                }
                
                Divider()
                
                // Menu Bar Configuration Section  
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "menubar.rectangle")
                            .foregroundColor(.green)
                        Text("Menu Bar Configuration")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entity Configuration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Configure the entity IDs for your sensors:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(EntityType.allCases, id: \.self) { entityType in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: entityType.sfSymbolName)
                                        .frame(width: 16)
                                    Text("\(entityType.displayName) Entity ID:")
                                }
                                TextField(entityType.defaultEntityId, text: Binding(
                                    get: { entityIds[entityType] ?? "" },
                                    set: { entityIds[entityType] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        Text("Display Selection")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text("Choose which entities to display in the menu bar:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Top position picker
                            HStack {
                                Text("Top Position:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Picker("", selection: $topEntity) {
                                    Text("Select entity...").tag(EntityType?.none)
                                    ForEach(EntityType.allCases, id: \.self) { entityType in
                                        let isConfigured = !(entityIds[entityType]?.isEmpty ?? true)
                                        if isConfigured {
                                            HStack {
                                                Image(systemName: entityType.sfSymbolName)
                                                Text(entityType.displayName)
                                            }
                                            .tag(EntityType?.some(entityType))
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: topEntity) { _ in
                                    autoSaveIfValid()
                                }
                            }
                            
                            // Bottom position picker
                            HStack {
                                Text("Bottom Position:")
                                    .frame(width: 100, alignment: .leading)
                                
                                Picker("", selection: $bottomEntity) {
                                    Text("Select entity...").tag(EntityType?.none)
                                    ForEach(EntityType.allCases, id: \.self) { entityType in
                                        let isConfigured = !(entityIds[entityType]?.isEmpty ?? true)
                                        if isConfigured && entityType != topEntity {
                                            HStack {
                                                Image(systemName: entityType.sfSymbolName)
                                                Text(entityType.displayName)
                                            }
                                            .tag(EntityType?.some(entityType))
                                        }
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: bottomEntity) { _ in
                                    autoSaveIfValid()
                                }
                            }
                        }
                        .padding(.leading, 10)
                        
                        if topEntity == nil || bottomEntity == nil {
                            Text("Please select entities for both positions")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("Refresh Settings")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text("Refresh Interval (seconds):")
                        HStack {
                            Slider(value: $refreshInterval, in: 10...300, step: 5)
                            Text("\(Int(refreshInterval))s")
                                .frame(width: 40)
                        }
                    }
                    .padding(.leading, 20)
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
        guard !homeAssistantURL.isEmpty && !accessToken.isEmpty else {
            return false
        }
        
        guard let top = topEntity, let bottom = bottomEntity else {
            return false
        }
        
        // Check if selected entities have valid entity IDs
        if let topId = entityIds[top], topId.isEmpty {
            return false
        }
        
        if let bottomId = entityIds[bottom], bottomId.isEmpty {
            return false
        }
        
        return true
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
        let selectedTypes = settings.selectedEntityTypes
        if selectedTypes.count >= 2 {
            topEntity = selectedTypes[0]
            bottomEntity = selectedTypes[1]
        } else {
            topEntity = nil
            bottomEntity = nil
        }
    }
    
    private func autoSaveIfValid() {
        // Only auto-save if both entities are selected and all other settings are valid
        guard let top = topEntity, let bottom = bottomEntity else {
            return
        }
        
        guard !homeAssistantURL.isEmpty && !accessToken.isEmpty else {
            return
        }
        
        // Check if selected entities have valid entity IDs
        guard let topId = entityIds[top], !topId.isEmpty else {
            return
        }
        
        guard let bottomId = entityIds[bottom], !bottomId.isEmpty else {
            return
        }
        
        // All conditions met - save settings automatically
        saveSettingsInternal(showAlert: false)
    }
    
    private func saveSettings() {
        saveSettingsInternal(showAlert: true)
    }
    
    private func saveSettingsInternal(showAlert: Bool) {
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
        var selectedTypes: [EntityType] = []
        if let top = topEntity {
            selectedTypes.append(top)
        }
        if let bottom = bottomEntity {
            selectedTypes.append(bottom)
        }
        settings.selectedEntityTypes = selectedTypes
        print("📊 Selected entities: Top: \(topEntity?.displayName ?? "none"), Bottom: \(bottomEntity?.displayName ?? "none")")
        
        print("✅ Settings saved to UserDefaults")
        print("⚙️ Settings now configured: \(settings.isConfigured)")
        
        // Notify MenuBarController to restart with new settings
        if let appDelegate = AppDelegate.shared {
            print("📡 Notifying MenuBarController to restart...")
            appDelegate.menuBarController?.restartWithNewSettings()
        } else {
            print("❌ AppDelegate.shared is nil!")
        }
        
        if showAlert {
            alertMessage = "Settings saved successfully! Data refresh started."
            showingAlert = true
        }
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