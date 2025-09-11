import Foundation

class HomeAssistantClient {
    private let session = URLSession.shared
    
    func getEntityState(entityId: String) async throws -> EntityState {
        guard let baseURL = Settings.shared.homeAssistantURL,
              let url = URL(string: "\(baseURL)/api/states/\(entityId)") else {
            throw HomeAssistantError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(Settings.shared.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HomeAssistantError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw HomeAssistantError.unauthorized
            case 404:
                throw HomeAssistantError.notFound
            default:
                throw HomeAssistantError.invalidResponse
            }
            
            let entityState = try JSONDecoder().decode(EntityState.self, from: data)
            return entityState
            
        } catch let error as HomeAssistantError {
            throw error
        } catch let decodingError as DecodingError {
            throw HomeAssistantError.decodingError(decodingError)
        } catch {
            throw HomeAssistantError.networkError(error)
        }
    }
    
    func testConnection() async throws -> Bool {
        guard let baseURL = Settings.shared.homeAssistantURL,
              let url = URL(string: "\(baseURL)/api/") else {
            throw HomeAssistantError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(Settings.shared.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HomeAssistantError.invalidResponse
            }
            
            return httpResponse.statusCode == 200
            
        } catch {
            throw HomeAssistantError.networkError(error)
        }
    }
}