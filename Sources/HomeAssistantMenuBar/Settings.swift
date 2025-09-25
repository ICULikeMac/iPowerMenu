import Foundation

/// Represents the different types of Home Assistant entities supported by iPowerMenu
enum EntityType: String, CaseIterable, Codable {
    case solar = "solar"
    case battery = "battery"
    case batteryCharging = "batteryCharging"
    case batteryDischarging = "batteryDischarging"
    case gridUsage = "gridUsage"
    case homePower = "homePower"
    case purchasePrice = "purchasePrice"
    case feedInTariff = "feedInTariff"

    var displayName: String {
        switch self {
        case .solar: return "Solar Power"
        case .battery: return "Battery SOC"
        case .batteryCharging: return "Battery Charging"
        case .batteryDischarging: return "Battery Discharging"
        case .gridUsage: return "Grid"
        case .homePower: return "Home Power"
        case .purchasePrice: return "Buy Price"
        case .feedInTariff: return "Sell Price"
        }
    }

    var isDisplayEntity: Bool {
        switch self {
        case .batteryCharging, .batteryDischarging:
            return false // Internal use only for power flow calculations
        default:
            return true // Show in menu dropdown
        }
    }

    var sfSymbolName: String {
        switch self {
        case .solar: return "sun.min"
        case .battery: return "bolt.house"
        case .batteryCharging: return "bolt.house.fill"
        case .batteryDischarging: return "bolt.house"
        case .gridUsage: return "bolt"
        case .homePower: return "house"
        case .purchasePrice: return "dollarsign.circle"
        case .feedInTariff: return "dollarsign.circle.fill"
        }
    }

    var unitType: UnitType {
        switch self {
        case .solar, .batteryCharging, .batteryDischarging, .gridUsage, .homePower: return .watts
        case .battery: return .percentage
        case .purchasePrice, .feedInTariff: return .currency
        }
    }

    var defaultEntityId: String {
        switch self {
        case .solar: return "sensor.solar_power"
        case .battery: return "sensor.battery_soc"
        case .batteryCharging: return "sensor.battery_charging_power"
        case .batteryDischarging: return "sensor.battery_discharging_power"
        case .gridUsage: return "sensor.grid_usage"
        case .homePower: return "sensor.home_power"
        case .purchasePrice: return "sensor.purchase_price"
        case .feedInTariff: return "sensor.feed_in_tariff"
        }
    }
}

/// Unit types for different entity measurements
enum UnitType {
    case watts
    case percentage
    case currency
}

/// Configuration for a Home Assistant entity including its type and entity ID
struct EntityConfig {
    let type: EntityType
    let entityId: String
    
    var displayName: String { type.displayName }
    var sfSymbolName: String { type.sfSymbolName }
    var unitType: UnitType { type.unitType }
}

/// Manages app settings including Home Assistant connection details and entity configuration
/// Persists settings to UserDefaults and provides reactive updates via ObservableObject
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

    @Published var batteryChargingEntityId: String {
        didSet {
            UserDefaults.standard.set(batteryChargingEntityId, forKey: "batteryChargingEntityId")
        }
    }

    @Published var batteryDischargingEntityId: String {
        didSet {
            UserDefaults.standard.set(batteryDischargingEntityId, forKey: "batteryDischargingEntityId")
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

    @Published var purchasePriceEntityId: String {
        didSet {
            UserDefaults.standard.set(purchasePriceEntityId, forKey: "purchasePriceEntityId")
        }
    }

    @Published var feedInTariffEntityId: String {
        didSet {
            UserDefaults.standard.set(feedInTariffEntityId, forKey: "feedInTariffEntityId")
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
        self.batteryChargingEntityId = UserDefaults.standard.string(forKey: "batteryChargingEntityId") ?? EntityType.batteryCharging.defaultEntityId
        self.batteryDischargingEntityId = UserDefaults.standard.string(forKey: "batteryDischargingEntityId") ?? EntityType.batteryDischarging.defaultEntityId
        self.gridUsageEntityId = UserDefaults.standard.string(forKey: "gridUsageEntityId") ?? EntityType.gridUsage.defaultEntityId
        self.homePowerEntityId = UserDefaults.standard.string(forKey: "homePowerEntityId") ?? EntityType.homePower.defaultEntityId
        self.purchasePriceEntityId = UserDefaults.standard.string(forKey: "purchasePriceEntityId") ?? EntityType.purchasePrice.defaultEntityId
        self.feedInTariffEntityId = UserDefaults.standard.string(forKey: "feedInTariffEntityId") ?? EntityType.feedInTariff.defaultEntityId
        
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
        case .batteryCharging: return batteryChargingEntityId
        case .batteryDischarging: return batteryDischargingEntityId
        case .gridUsage: return gridUsageEntityId
        case .homePower: return homePowerEntityId
        case .purchasePrice: return purchasePriceEntityId
        case .feedInTariff: return feedInTariffEntityId
        }
    }

    func setEntityId(for type: EntityType, entityId: String) {
        switch type {
        case .solar: self.solarEntityId = entityId
        case .battery: self.batteryEntityId = entityId
        case .batteryCharging: self.batteryChargingEntityId = entityId
        case .batteryDischarging: self.batteryDischargingEntityId = entityId
        case .gridUsage: self.gridUsageEntityId = entityId
        case .homePower: self.homePowerEntityId = entityId
        case .purchasePrice: self.purchasePriceEntityId = entityId
        case .feedInTariff: self.feedInTariffEntityId = entityId
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
        batteryChargingEntityId = EntityType.batteryCharging.defaultEntityId
        batteryDischargingEntityId = EntityType.batteryDischarging.defaultEntityId
        gridUsageEntityId = EntityType.gridUsage.defaultEntityId
        homePowerEntityId = EntityType.homePower.defaultEntityId
        purchasePriceEntityId = EntityType.purchasePrice.defaultEntityId
        feedInTariffEntityId = EntityType.feedInTariff.defaultEntityId
        selectedEntityTypes = [.solar, .battery]
        refreshInterval = 30.0
    }
}