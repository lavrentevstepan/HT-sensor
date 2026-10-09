import Foundation
import CoreBluetooth
import Combine

public final class BleScannerManager: NSObject, ObservableObject {
    @Published public var devices: [BeaconDevice] = []
    @Published public var isScanning: Bool = false
    @Published public var bluetoothState: CBManagerState = .unknown
    @Published public var errorMessage: String? = nil
    
    private var centralManager: CBCentralManager!
    private var deviceMap: [String: BeaconDevice] = [:]
    // Maps temporary peripheral UUID to true hardware MAC once discovered
    private var uuidToMacMap: [UUID: String] = [:]
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    public func startScan() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth выключен или недоступен"
            return
        }
        
        errorMessage = nil
        // Allow duplicates so continuous beacon sensor updates are received in real-time
        let scanOptions: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
        isScanning = true
    }
    
    public func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    public func clearDevices() {
        deviceMap.removeAll()
        uuidToMacMap.removeAll()
        devices.removeAll()
    }
    
    public func toggleFavorite(id: String) {
        if var device = deviceMap[id] {
            device.isFavorite.toggle()
            deviceMap[id] = device
            updateDeviceList()
        }
    }
    
    private func updateDeviceList() {
        devices = deviceMap.values.sorted { dev1, dev2 in
            if dev1.isFavorite != dev2.isFavorite {
                return dev1.isFavorite && !dev2.isFavorite
            }
            if dev1.isMinewS1 != dev2.isMinewS1 {
                return dev1.isMinewS1 && !dev2.isMinewS1
            }
            if (dev1.minewHtData != nil) != (dev2.minewHtData != nil) {
                return dev1.minewHtData != nil
            }
            return dev1.lastSeenTimestamp > dev2.lastSeenTimestamp
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BleScannerManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        switch central.state {
        case .poweredOn:
            errorMessage = nil
            startScan()
        case .poweredOff:
            isScanning = false
            errorMessage = "Bluetooth выключен на устройстве"
        case .unauthorized:
            isScanning = false
            errorMessage = "Доступ к Bluetooth запрещен в настройках iOS"
        case .unsupported:
            isScanning = false
            errorMessage = "BLE не поддерживается данным устройством"
        default:
            break
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rssiValue = RSSI.intValue
        guard rssiValue != 127 else { return } // 127 is invalid/unavailable RSSI in CoreBluetooth
        
        var parsedHt: MinewHtData? = nil
        var parsedName: String? = nil
        var serviceHexMap: [String: String] = [:]
        
        // 1. Process Service Data (Minew UUID 0xFFE1)
        if let serviceDataDict = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (uuid, data) in serviceDataDict {
                serviceHexMap[uuid.uuidString] = MinewPacketParser.dataToHexString(data)
                
                let uuidStr = uuid.uuidString.lowercased()
                if uuidStr.contains("ffe1") {
                    if let ht = MinewPacketParser.parseHtPayload(data) {
                        parsedHt = ht
                    }
                    if let name = MinewPacketParser.parseInfoPayload(data) {
                        parsedName = name
                    }
                }
            }
        }
        
        // 2. Process Manufacturer Specific Data (Apple iBeacon or Minew signature)
        var parsedIBeacon: IBeaconData? = nil
        var manufacturerHex = ""
        if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerHex = MinewPacketParser.dataToHexString(mfgData)
            parsedIBeacon = IBeaconParser.parseIBeacon(from: mfgData)
            
            // Fallback check: sometimes firmware places 0xA1 frame in manufacturer data
            if parsedHt == nil {
                parsedHt = MinewPacketParser.searchRawHtSignature(mfgData)
            }
        }
        
        // 3. Resolve Device Name
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let devName = localName ?? peripheral.name ?? "Unknown"
        
        // 4. Resolve Device Key (Hardware MAC takes absolute precedence over iOS UUID)
        let resolvedMac: String
        let deviceKey: String
        
        if let ht = parsedHt, !ht.macInFrame.isEmpty {
            resolvedMac = ht.macInFrame
            deviceKey = ht.macInFrame
            uuidToMacMap[peripheral.identifier] = ht.macInFrame
            
            // Clean up old UUID key if device was registered before MAC was discovered
            if let old = deviceMap.removeValue(forKey: peripheral.identifier.uuidString) {
                deviceMap[deviceKey] = old
            }
        } else if let knownMac = uuidToMacMap[peripheral.identifier] {
            resolvedMac = knownMac
            deviceKey = knownMac
        } else {
            resolvedMac = peripheral.identifier.uuidString
            deviceKey = peripheral.identifier.uuidString
        }
        
        // 5. Update or Create Beacon Device Entry
        var existing = deviceMap[deviceKey] ?? BeaconDevice(
            peripheralId: peripheral.identifier,
            macAddress: resolvedMac,
            name: devName,
            rssi: rssiValue
        )
        
        var history = existing.history
        if let ht = parsedHt {
            let shouldAdd = history.isEmpty ||
                (Date().timeIntervalSince(history.last!.timestamp) > 2.0) ||
                (history.last!.temperature != ht.temperature) ||
                (history.last!.humidity != ht.humidity)
            
            if shouldAdd {
                history.append(
                    SensorDataPoint(
                        timestamp: ht.timestamp,
                        temperature: ht.temperature,
                        humidity: ht.humidity,
                        rssi: rssiValue
                    )
                )
                if history.count > 40 {
                    history.removeFirst()
                }
            }
        }
        
        existing.macAddress = resolvedMac
        if devName != "Unknown" {
            existing.name = devName
        }
        existing.rssi = rssiValue
        existing.lastSeenTimestamp = Date()
        if let ht = parsedHt { existing.minewHtData = ht }
        if let ib = parsedIBeacon { existing.iBeaconData = ib }
        if let name = parsedName { existing.minewName = name }
        if !serviceHexMap.isEmpty {
            existing.rawServiceDataHex.merge(serviceHexMap) { _, new in new }
        }
        if !manufacturerHex.isEmpty {
            existing.rawManufacturerDataHex = manufacturerHex
        }
        existing.history = history
        existing.packetCount += 1
        
        deviceMap[deviceKey] = existing
        updateDeviceList()
    }
}
