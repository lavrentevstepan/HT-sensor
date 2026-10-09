import XCTest
@testable import MinewBeaconScanner

final class MinewPacketParserTests: XCTestCase {
    
    func testMinewHtPayloadParsing() {
        // Hex: a1 01 63 15 80 32 00 aa bb cc dd ee ff
        let hex = "a1016315803200aabbccddeeff"
        let data = hexStringToData(hex)!
        
        let ht = MinewPacketParser.parseHtPayload(data)
        XCTAssertNotNil(ht)
        guard let parsed = ht else { return }
        
        XCTAssertEqual(parsed.batteryPercentage, 99)
        XCTAssertEqual(parsed.temperature, 21.5, accuracy: 0.05)
        XCTAssertEqual(parsed.humidity, 50.0, accuracy: 0.05)
        XCTAssertEqual(parsed.macInFrame, "AA:BB:CC:DD:EE:FF")
    }
    
    func testMinewHtNegativeTemperature() {
        // Temperature -5.5°C: int8 = -5 (0xFB), frac = 128/256 (0x80)
        let hex = "a10150fb802800112233445566"
        let data = hexStringToData(hex)!
        
        let ht = MinewPacketParser.parseHtPayload(data)
        XCTAssertNotNil(ht)
        guard let parsed = ht else { return }
        
        XCTAssertEqual(parsed.batteryPercentage, 80)
        XCTAssertTrue(parsed.temperature < 0)
        XCTAssertEqual(parsed.macInFrame, "11:22:33:44:55:66")
    }
    
    func testIBeaconParsingFromManufacturerData() {
        // Apple company ID: 4C 00, Type: 02, Len: 15
        // UUID: FDA50693A4E24FB1AFCFC6EB07647825
        // Major: 00 01 (1)
        // Minor: 00 02 (2)
        // Tx: C5 (-59 dBm)
        let hex = "4C000215FDA50693A4E24FB1AFCFC6EB0764782500010002C5"
        let data = hexStringToData(hex)!
        
        let ibeacon = IBeaconParser.parseIBeacon(from: data)
        XCTAssertNotNil(ibeacon)
        guard let beacon = ibeacon else { return }
        
        XCTAssertEqual(beacon.major, 1)
        XCTAssertEqual(beacon.minor, 2)
        XCTAssertEqual(beacon.txPower, -59)
        XCTAssertEqual(beacon.uuid, "FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
    }
    
    private func hexStringToData(_ hex: String) -> Data? {
        var data = Data()
        var tempHex = hex
        while !tempHex.isEmpty {
            let subHex = String(tempHex.prefix(2))
            tempHex = String(tempHex.dropFirst(2))
            guard let byte = UInt8(subHex, radix: 16) else { return nil }
            data.append(byte)
        }
        return data
    }
}
