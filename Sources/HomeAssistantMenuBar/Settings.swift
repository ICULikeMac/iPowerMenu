import Foundation

enum EntityType: String, CaseIterable, Codable {
    case solar = "solar"
    case battery = "battery" 
    case gridUsage = "gridUsage"
    case homePower = "homePower"
    
    var displayName: String {
        switch self {
        case .solar: return "Solar Power"
        case .battery: return "Battery SOC"
        case .gridUsage: return "Grid Usage"
        case .homePower: return "Home Power"
        }
    }
    
    var sfSymbolName: String {
        switch self {
        case .solar: return "sun.min"
        case .battery: return "bolt.house"
        case .gridUsage: return "bolt"
        case .homePower: return "house"
        }
    }
    
    var unitType: UnitType {
        switch self {
        case .solar, .gridUsage, .homePower: return .watts
        case .battery: return .percentage
        }
    }
    
    var defaultEntityId: String {
        switch self {
        case .solar: return "sensor.solar_power"
        case .battery: return "sensor.battery_soc"
        case .gridUsage: return "sensor.grid_usage"
        case .homePower: return "sensor.home_power"
        }
    }
}

enum UnitType {
    case watts
    case percentage
}

struct EntityConfig {
    let type: EntityType
    let entityId: String
    
    var displayName: String { type.displayName }
    var sfSymbolName: String { type.sfSymbolName }
    var unitType: UnitType { type.unitType }
}

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
    
    @Published var gridUsageEntityId: String {
        didSet {
            UserDefaults.standard.set(gridUsageEntityId, forKey: "gridUsageEntityId")
        }
    }
    
    @Published var homePowerEntityId: String {
        didSet {
            UserDefaults.standard.set(homePowerEntityId, forKey: "homePowerEntityId")
        }
    }
    
    @Published var selectedEntityTypes: [EntityType] {
        didSet {
            let data = try? JSONEncoder().encode(selectedEntityTypes)
            UserDefaults.standard.set(data, forKey: "selectedEntityTypes")
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
        self.solarEntityId = UserDefaults.standard.string(forKey: "solarEntityId") ?? EntityType.solar.defaultEntityId
        self.batteryEntityId = UserDefaults.standard.string(forKey: "batteryEntityId") ?? EntityType.battery.defaultEntityId
        self.gridUsageEntityId = UserDefaults.standard.string(forKey: "gridUsageEntityId") ?? EntityType.gridUsage.defaultEntityId
        self.homePowerEntityId = UserDefaults.standard.string(forKey: "homePowerEntityId") ?? EntityType.homePower.defaultEntityId
        
        // Load selected entity types, default to solar and battery for backward compatibility
        if let data = UserDefaults.standard.data(forKey: "selectedEntityTypes"),
           let decoded = try? JSONDecoder().decode([EntityType].self, from: data) {
            self.selectedEntityTypes = decoded
        } else {
            self.selectedEntityTypes = [.solar, .battery]
        }
        
        self.refreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        
        if refreshInterval == 0 {
            refreshInterval = 30.0
        }
    }
    
    var isConfigured: Bool {
        // Basic requirements
        guard homeAssistantURL != nil && !accessToken.isEmpty else { return false }
        guard selectedEntityTypes.count == 2 else { return false }
        
        // Only check if SELECTED entities have valid IDs
        for entityType in selectedEntityTypes {
            if getEntityId(for: entityType).isEmpty {
                return false
            }
        }
        return true
    }
    
    func getEntityId(for type: EntityType) -> String {
        switch type {
        case .solar: return solarEntityId
        case .battery: return batteryEntityId
        case .gridUsage: return gridUsageEntityId
        case .homePower: return homePowerEntityId
        }
    }
    
    func setEntityId(for type: EntityType, entityId: String) {
        switch type {
        case .solar: self.solarEntityId = entityId
        case .battery: self.batteryEntityId = entityId
        case .gridUsage: self.gridUsageEntityId = entityId
        case .homePower: self.homePowerEntityId = entityId
        }
    }
    
    var displayedEntityConfigs: [EntityConfig] {
        // Return entities in order: top first, then bottom
        var configs: [EntityConfig] = []
        if selectedEntityTypes.count >= 1 {
            let topEntity = selectedEntityTypes[0]
            configs.append(EntityConfig(type: topEntity, entityId: getEntityId(for: topEntity)))
        }
        if selectedEntityTypes.count >= 2 {
            let bottomEntity = selectedEntityTypes[1]
            configs.append(EntityConfig(type: bottomEntity, entityId: getEntityId(for: bottomEntity)))
        }
        return configs
    }
    
    func reset() {
        homeAssistantURL = nil
        accessToken = ""
        solarEntityId = EntityType.solar.defaultEntityId
        batteryEntityId = EntityType.battery.defaultEntityId
        gridUsageEntityId = EntityType.gridUsage.defaultEntityId
        homePowerEntityId = EntityType.homePower.defaultEntityId
        selectedEntityTypes = [.solar, .battery]
        refreshInterval = 30.0
    }
}