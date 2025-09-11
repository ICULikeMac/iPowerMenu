import Foundation

struct EntityState: Codable {
    let entityId: String
    let state: String
    let attributes: [String: AnyCodable]
    let lastChanged: String
    let lastUpdated: String
    let context: Context
    
    private enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
        case context
    }
}

struct Context: Codable {
    let id: String
    let parentId: String?
    let userId: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case userId = "user_id"
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}

enum HomeAssistantError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case networkError(Error)
    case decodingError(Error)
}

extension HomeAssistantError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Home Assistant URL"
        case .invalidResponse:
            return "Invalid response from Home Assistant"
        case .unauthorized:
            return "Unauthorized - check your access token"
        case .notFound:
            return "Entity not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        }
    }
}