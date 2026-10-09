import Foundation

public struct MinewHtData: Identifiable, Equatable {
    public var id: String { macInFrame }
    
    public let temperature: Float        // In degrees Celsius (°C)
    public let humidity: Float           // Relative humidity in %
    public let batteryPercentage: Int    // 0 - 100%
    public let macInFrame: String        // True hardware MAC address from frame payload
    public let frameVersion: UInt8       // 0x01 (HT Sensor)
    public let timestamp: Date
    
    public init(
        temperature: Float,
        humidity: Float,
        batteryPercentage: Int,
        macInFrame: String,
        frameVersion: UInt8 = 0x01,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.batteryPercentage = batteryPercentage
        self.macInFrame = macInFrame
        self.frameVersion = frameVersion
        self.timestamp = timestamp
    }
}
