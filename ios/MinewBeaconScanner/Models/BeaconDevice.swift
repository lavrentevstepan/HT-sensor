import Foundation

public struct BeaconDevice: Identifiable, Equatable {
    public var id: String {
        if let ht = minewHtData, !ht.macInFrame.isEmpty {
            return ht.macInFrame
        }
        if !macAddress.isEmpty && macAddress.contains(":") {
            return macAddress
        }
        if let ib = iBeaconData {
            return "ibeacon-\(ib.uuid)-\(ib.major)-\(ib.minor)"
        }
        return peripheralId.uuidString
    }
    
    public let peripheralId: UUID
    public var macAddress: String
    public var name: String
    public var rssi: Int
    public var lastSeenTimestamp: Date
    public var minewHtData: MinewHtData?
    public var iBeaconData: IBeaconData?
    public var minewName: String?
    public var batteryLevel: Int?              // Battery percentage from Info, TLM, Battery service or GATT
    public var rawServiceDataHex: [String: String]
    public var rawManufacturerDataHex: String
    public var history: [SensorDataPoint]
    public var isFavorite: Bool
    public var packetCount: Int
    
    public init(
        peripheralId: UUID,
        macAddress: String,
        name: String,
        rssi: Int,
        lastSeenTimestamp: Date = Date(),
        minewHtData: MinewHtData? = nil,
        iBeaconData: IBeaconData? = nil,
        minewName: String? = nil,
        batteryLevel: Int? = nil,
        rawServiceDataHex: [String: String] = [:],
        rawManufacturerDataHex: String = "",
        history: [SensorDataPoint] = [],
        isFavorite: Bool = false,
        packetCount: Int = 1
    ) {
        self.peripheralId = peripheralId
        self.macAddress = macAddress
        self.name = name
        self.rssi = rssi
        self.lastSeenTimestamp = lastSeenTimestamp
        self.minewHtData = minewHtData
        self.iBeaconData = iBeaconData
        self.minewName = minewName
        self.batteryLevel = batteryLevel
        self.rawServiceDataHex = rawServiceDataHex
        self.rawManufacturerDataHex = rawManufacturerDataHex
        self.history = history
        self.isFavorite = isFavorite
        self.packetCount = packetCount
    }
    
    public var effectiveBattery: Int? {
        return minewHtData?.batteryPercentage ?? batteryLevel
    }
    
    public var isMinewS1: Bool {
        return minewHtData != nil ||
            (minewName?.localizedCaseInsensitiveContains("S1") == true) ||
            name.localizedCaseInsensitiveContains("S1")
    }
    
    public var displayName: String {
        if let minew = minewName, !minew.isEmpty {
            return minew
        }
        if !name.isEmpty && name != "Unknown" {
            return name
        }
        if isMinewS1 {
            return "Minew S1"
        }
        if let ib = iBeaconData {
            return "iBeacon [\(ib.major):\(ib.minor)]"
        }
        return "BLE Beacon"
    }
}
