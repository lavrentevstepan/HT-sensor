import Foundation

public struct SensorDataPoint: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let temperature: Float
    public let humidity: Float
    public let rssi: Int
    
    public init(timestamp: Date, temperature: Float, humidity: Float, rssi: Int) {
        self.timestamp = timestamp
        self.temperature = temperature
        self.humidity = humidity
        self.rssi = rssi
    }
}
