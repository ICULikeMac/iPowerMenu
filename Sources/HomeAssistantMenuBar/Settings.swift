import Foundation

class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var homeAssistantURL: String? {
        didSet {
            UserDefaults.standard.set(homeAssistantURL, forKey: "homeAssistantURL")
        }
    }
    
    @Published var accessToken: String {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: "accessToken")
        }
    }
    
    @Published var solarEntityId: String {
        didSet {
            UserDefaults.standard.set(solarEntityId, forKey: "solarEntityId")
        }
    }
    
    @Published var batteryEntityId: String {
        didSet {
            UserDefaults.standard.set(batteryEntityId, forKey: "batteryEntityId")
        }
    }
    
    @Published var refreshInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
        }
    }
    
    private init() {
        self.homeAssistantURL = UserDefaults.standard.string(forKey: "homeAssistantURL")
        self.accessToken = UserDefaults.standard.string(forKey: "accessToken") ?? ""
        self.solarEntityId = UserDefaults.standard.string(forKey: "solarEntityId") ?? "sensor.solar_power"
        self.batteryEntityId = UserDefaults.standard.string(forKey: "batteryEntityId") ?? "sensor.battery_soc"
        self.refreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        
        if refreshInterval == 0 {
            refreshInterval = 30.0
        }
    }
    
    var isConfigured: Bool {
        return homeAssistantURL != nil && !accessToken.isEmpty && !solarEntityId.isEmpty && !batteryEntityId.isEmpty
    }
    
    func reset() {
        homeAssistantURL = nil
        accessToken = ""
        solarEntityId = "sensor.solar_power"
        batteryEntityId = "sensor.battery_soc"
        refreshInterval = 30.0
    }
}