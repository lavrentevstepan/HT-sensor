import Foundation

public struct IBeaconData: Equatable {
    public let uuid: String
    public let major: Int
    public let minor: Int
    public let txPower: Int
    public let accuracy: Double?   // Direct accuracy from CoreLocation (in meters)
    public let timestamp: Date
    
    public init(
        uuid: String,
        major: Int,
        minor: Int,
        txPower: Int = -59,
        accuracy: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.txPower = txPower
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
    
    /// Estimates distance in meters: uses CoreLocation accuracy if present, otherwise log-distance formula
    public func calculateDistance(rssi: Int) -> Double {
        if let acc = accuracy, acc > 0 {
            return acc
        }
        guard rssi != 0 && txPower != 0 else { return -1.0 }
        let ratio = Double(txPower - rssi) / (10.0 * 2.0)
        return pow(10.0, ratio)
    }
}
