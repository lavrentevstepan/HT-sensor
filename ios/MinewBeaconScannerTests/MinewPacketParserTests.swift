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
    
    func testMinewInfoFrameParsing() {
        // Hex: a1 08 55 aa bb cc dd ee ff + "Beacon" in ascii (42 65 61 63 6f 6e)
        let hex = "a10855aabbccddeeff426561636f6e"
        let data = hexStringToData(hex)!
        
        let info = MinewPacketParser.parseInfoPayload(data)
        XCTAssertNotNil(info)
        guard let parsed = info else { return }
        
        XCTAssertEqual(parsed.batteryPercentage, 85)
        XCTAssertEqual(parsed.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(parsed.name, "Beacon")
    }
    
    func testAnyMinewBatteryParsing() {
        // Hex: a1 05 48 ... (e.g. Minew frame type with 72% battery)
        let hex = "a105481122"
        let data = hexStringToData(hex)!
        
        let battery = MinewPacketParser.parseAnyMinewBattery(data)
        XCTAssertEqual(battery, 72)
    }
    
    func testEddystoneTlmBatteryParsing() {
        // Hex: 20 00 0B B8 (3000 mV => (3000-2200)/800 = 100%)
        let hex = "20000bb8"
        let data = hexStringToData(hex)!
        
        let battery = MinewPacketParser.parseEddystoneTlmBattery(data)
        XCTAssertEqual(battery, 100)
    }
    
    func testBatteryServiceDataParsing() {
        let data = Data([85])
        let battery = MinewPacketParser.parseBatteryServiceData(data)
        XCTAssertEqual(battery, 85)
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

