import Foundation

public enum IBeaconParser {
    public static let appleCompanyId: UInt16 = 0x004C
    private static let ibeaconType: UInt8 = 0x02
    private static let ibeaconDataLen: UInt8 = 0x15
    
    /// Parses Apple iBeacon packet from Manufacturer Data
    public static func parseIBeacon(from data: Data) -> IBeaconData? {
        let bytes = [UInt8](data)
        
        // Scenario A: 25 bytes including Apple Company ID (0x4C 0x00)
        if bytes.count >= 25 && bytes[0] == 0x4C && bytes[1] == 0x00 &&
            bytes[2] == ibeaconType && bytes[3] == ibeaconDataLen {
            return parsePayload(Array(bytes[2..<25]))
        }
        
        // Scenario B: 23 bytes without Company ID
        if bytes.count >= 23 && bytes[0] == ibeaconType && bytes[1] == ibeaconDataLen {
            return parsePayload(Array(bytes[0..<23]))
        }
        
        // Scenario C: Scan for signature within data
        if bytes.count >= 23 {
            for i in 0...(bytes.count - 23) {
                if bytes[i] == ibeaconType && bytes[i + 1] == ibeaconDataLen {
                    return parsePayload(Array(bytes[i..<(i + 23)]))
                }
            }
        }
        
        return nil
    }
    
    private static func parsePayload(_ payload: [UInt8]) -> IBeaconData? {
        guard payload.count >= 23 else { return nil }
        
        // UUID: 16 bytes (payload[2...17])
        let uuidBytes = Array(payload[2...17])
        let uuidString = formatUuid(uuidBytes)
        
        // Major: 2 bytes (payload[18...19])
        let major = (Int(payload[18]) << 8) | Int(payload[19])
        
        // Minor: 2 bytes (payload[20...21])
        let minor = (Int(payload[20]) << 8) | Int(payload[21])
        
        // Measured Power: 1 byte signed int8 (payload[22])
        let txPower = Int(Int8(bitPattern: payload[22]))
        
        return IBeaconData(
            uuid: uuidString,
            major: major,
            minor: minor,
            txPower: txPower
        )
    }
    
    private static func formatUuid(_ bytes: [UInt8]) -> String {
        guard bytes.count == 16 else { return "" }
        let hex = bytes.map { String(format: "%02X", $0) }.joined()
        guard hex.count == 32 else { return hex }
        
        let p1 = hex.prefix(8)
        let p2 = hex.dropFirst(8).prefix(4)
        let p3 = hex.dropFirst(12).prefix(4)
        let p4 = hex.dropFirst(16).prefix(4)
        let p5 = hex.dropFirst(20).prefix(12)
        
        return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
    }
}
