import Foundation
import CoreBluetooth

public enum MinewPacketParser {
    public static let minewServiceUUID = CBUUID(string: "FFE1")
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
    
    /// Parses Minew Info frame to extract advertised device name
    public static func parseInfoPayload(_ data: Data) -> String? {
        guard data.count >= 9 else { return nil }
        let bytes = [UInt8](data)
        guard bytes[0] == minewFrameType, bytes[1] == frameVersionInfo else {
            return nil
        }
        
        let nameData = data.subdata(in: 9..<data.count)
        guard let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return nil
        }
        return name
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
