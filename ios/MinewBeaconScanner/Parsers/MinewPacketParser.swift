import Foundation
import CoreBluetooth

public struct MinewInfoData {
    public let name: String
    public let batteryPercentage: Int
    public let macAddress: String
    
    public init(name: String, batteryPercentage: Int, macAddress: String) {
        self.name = name
        self.batteryPercentage = batteryPercentage
        self.macAddress = macAddress
    }
}

public enum MinewPacketParser {
    public static let minewServiceUUID = CBUUID(string: "FFE1")
    public static let eddystoneServiceUUID = CBUUID(string: "FEAA")
    public static let batteryServiceUUID = CBUUID(string: "180F")
    
    public static let minewFrameType: UInt8 = 0xA1
    public static let frameVersionHT: UInt8 = 0x01
    public static let frameVersionInfo: UInt8 = 0x08
    
    /// Parses Minew HT sensor payload (temperature, humidity, battery, embedded MAC)
    public static func parseHtPayload(_ data: Data) -> MinewHtData? {
        guard data.count >= 13 else { return nil }
        
        let bytes = [UInt8](data)
        guard bytes[0] == minewFrameType, bytes[1] == frameVersionHT else {
            return nil
        }
        
        let battery = Int(bytes[2])
        
        // Temperature: Signed 8.8 fixed-point (°C)
        let tempInt = Int8(bitPattern: bytes[3])
        let tempFrac = Float(bytes[4]) / 256.0
        let temperature = Float(tempInt) + tempFrac
        
        // Humidity: 8.8 fixed-point (%)
        let humInt = Float(bytes[5])
        let humFrac = Float(bytes[6]) / 256.0
        let humidity = humInt + humFrac
        
        // Hardware MAC address embedded in frame: bytes 7..12
        let macString = String(
            format: "%02X:%02X:%02X:%02X:%02X:%02X",
            bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12]
        )
        
        return MinewHtData(
            temperature: (temperature * 10.0).rounded() / 10.0,
            humidity: (humidity * 10.0).rounded() / 10.0,
            batteryPercentage: min(max(battery, 0), 100),
            macInFrame: macString,
            frameVersion: frameVersionHT
        )
    }
    
    /// Parses Minew Info frame to extract advertised device name, battery, and hardware MAC
    public static func parseInfoPayload(_ data: Data) -> MinewInfoData? {
        guard data.count >= 9 else { return nil }
        let bytes = [UInt8](data)
        guard bytes[0] == minewFrameType, bytes[1] == frameVersionInfo else {
            return nil
        }
        
        let battery = Int(bytes[2])
        let macString = String(
            format: "%02X:%02X:%02X:%02X:%02X:%02X",
            bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8]
        )
        
        var name = ""
        if data.count > 9 {
            let nameData = data.subdata(in: 9..<data.count)
            name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        
        return MinewInfoData(
            name: name,
            batteryPercentage: min(max(battery, 0), 100),
            macAddress: macString
        )
    }
    
    /// Extracts battery percentage from ANY Minew BeaconPlus frame (Byte 2 is always battery %)
    public static func parseAnyMinewBattery(_ data: Data) -> Int? {
        guard data.count >= 3 else { return nil }
        let bytes = [UInt8](data)
        guard bytes[0] == minewFrameType else { return nil }
        let battery = Int(bytes[2])
        if battery >= 0 && battery <= 100 {
            return battery
        }
        return nil
    }
    
    /// Extracts battery from Eddystone TLM frame (Service UUID 0xFEAA)
    public static func parseEddystoneTlmBattery(_ data: Data) -> Int? {
        guard data.count >= 4 else { return nil }
        let bytes = [UInt8](data)
        guard bytes[0] == 0x20 else { return nil } // 0x20 = TLM frame
        let mv = (Int(bytes[2]) << 8) | Int(bytes[3])
        if mv > 2000 && mv < 3600 {
            let percent = Int((Double(mv - 2200) / 800.0) * 100.0)
            return min(max(percent, 0), 100)
        }
        return nil
    }
    
    /// Extracts battery from standard Bluetooth SIG Battery Service (UUID 0x180F)
    public static func parseBatteryServiceData(_ data: Data) -> Int? {
        guard !data.isEmpty else { return nil }
        let b = Int(data[0])
        return (b >= 0 && b <= 100) ? b : nil
    }
    
    /// Scans arbitrary data buffer for 0xA1 0x01 frame pattern
    public static func searchRawHtSignature(_ data: Data) -> MinewHtData? {
        guard data.count >= 13 else { return nil }
        let bytes = [UInt8](data)
        for i in 0...(bytes.count - 13) {
            if bytes[i] == minewFrameType && bytes[i + 1] == frameVersionHT {
                let candidate = Data(bytes[i..<(i + 13)])
                if let parsed = parseHtPayload(candidate) {
                    return parsed
                }
            }
        }
        return nil
    }
    
    /// Helper: Converts binary Data to uppercase Hexadecimal String
    public static func dataToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined()
    }
}
