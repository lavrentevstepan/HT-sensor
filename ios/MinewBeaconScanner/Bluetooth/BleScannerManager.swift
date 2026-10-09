import Foundation
import CoreBluetooth
import CoreLocation
import Combine

public final class BleScannerManager: NSObject, ObservableObject {
    @Published public var devices: [BeaconDevice] = []
    @Published public var isScanning: Bool = false
    @Published public var bluetoothState: CBManagerState = .unknown
    @Published public var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var errorMessage: String? = nil
    
    // Default factory UUIDs for Minew S1 / BeaconPlus and standard iBeacons
    @Published public var monitoredUuids: [UUID] = [
        UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!, // Minew BeaconPlus S1 default
        UUID(uuidString: "FDA50693-A4E2-4FB1-AFCF-C6EB07647825")!, // Minew WeChat default
        UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, // Estimote default
        UUID(uuidString: "74278BDA-B644-4520-8F0C-720EAF059935")!, // Apple AirLocate default
        UUID(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")!  // Radius Networks default
    ]
    
    private var centralManager: CBCentralManager!
    private var locationManager: CLLocationManager!
    
    private var deviceMap: [String: BeaconDevice] = [:]
    // Maps temporary peripheral UUID to true hardware MAC once discovered
    private var uuidToMacMap: [UUID: String] = [:]
    // Stores active CLBeaconIdentityConstraints
    private var activeConstraints: [CLBeaconIdentityConstraint] = []
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    public func startScan() {
        // 1. CoreBluetooth Scan
        if centralManager.state == .poweredOn {
            errorMessage = nil
            let scanOptions: [String: Any] = [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
            centralManager.scanForPeripherals(withServices: nil, options: scanOptions)
            isScanning = true
        } else {
            errorMessage = "Bluetooth выключен или недоступен"
        }
        
        // 2. CoreLocation iBeacon Ranging
        startIBeaconRanging()
    }
    
    public func stopScan() {
        centralManager.stopScan()
        stopIBeaconRanging()
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
    
    /// Allows adding any custom iBeacon UUID (e.g., from BeaconSet Plus)
    public func addCustomBeaconUuid(_ uuidString: String) -> Bool {
        guard let uuid = UUID(uuidString: uuidString) else { return false }
        if !monitoredUuids.contains(uuid) {
            monitoredUuids.append(uuid)
            if isScanning {
                let constraint = CLBeaconIdentityConstraint(uuid: uuid)
                activeConstraints.append(constraint)
                locationManager.startRangingBeacons(satisfying: constraint)
            }
        }
        return true
    }
    
    private func startIBeaconRanging() {
        locationManager.requestWhenInUseAuthorization()
        
        stopIBeaconRanging()
        activeConstraints.removeAll()
        
        for uuid in monitoredUuids {
            let constraint = CLBeaconIdentityConstraint(uuid: uuid)
            activeConstraints.append(constraint)
            locationManager.startRangingBeacons(satisfying: constraint)
        }
    }
    
    private func stopIBeaconRanging() {
        for constraint in activeConstraints {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        activeConstraints.removeAll()
    }
    
    private func updateDeviceList() {
        devices = deviceMap.values.sorted { dev1, dev2 in
            if dev1.isFavorite != dev2.isFavorite {
                return dev1.isFavorite && !dev2.isFavorite
            }
            if dev1.isMinewS1 != dev2.isMinewS1 {
                return dev1.isMinewS1 && !dev2.isMinewS1
            }
            if (dev1.iBeaconData != nil) != (dev2.iBeaconData != nil) {
                return dev1.iBeaconData != nil
            }
            if (dev1.effectiveBattery != nil) != (dev2.effectiveBattery != nil) {
                return dev1.effectiveBattery != nil
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
        guard rssiValue != 127 else { return } // 127 is invalid RSSI in CoreBluetooth
        
        var parsedHt: MinewHtData? = nil
        var parsedName: String? = nil
        var parsedBattery: Int? = nil
        var resolvedMacFromFrame: String? = nil
        var serviceHexMap: [String: String] = [:]
        
        // 1. Process Service Data (Minew UUID 0xFFE1, Eddystone 0xFEAA, Battery 0x180F)
        if let serviceDataDict = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            for (uuid, data) in serviceDataDict {
                serviceHexMap[uuid.uuidString] = MinewPacketParser.dataToHexString(data)
                let uuidStr = uuid.uuidString.lowercased()
                
                // Minew BeaconPlus Service Data (0xFFE1)
                if uuidStr.contains("ffe1") {
                    if let ht = MinewPacketParser.parseHtPayload(data) {
                        parsedHt = ht
                        parsedBattery = ht.batteryPercentage
                        resolvedMacFromFrame = ht.macInFrame
                    }
                    if let info = MinewPacketParser.parseInfoPayload(data) {
                        if !info.name.isEmpty { parsedName = info.name }
                        if parsedBattery == nil { parsedBattery = info.batteryPercentage }
                        if resolvedMacFromFrame == nil && !info.macAddress.isEmpty {
                            resolvedMacFromFrame = info.macAddress
                        }
                    }
                    if parsedBattery == nil {
                        parsedBattery = MinewPacketParser.parseAnyMinewBattery(data)
                    }
                }
                
                // Eddystone TLM (0xFEAA)
                if uuidStr.contains("feaa") && parsedBattery == nil {
                    parsedBattery = MinewPacketParser.parseEddystoneTlmBattery(data)
                }
                
                // Battery Service (0x180F)
                if uuidStr.contains("180f") && parsedBattery == nil {
                    parsedBattery = MinewPacketParser.parseBatteryServiceData(data)
                }
            }
        }
        
        // 2. Process Manufacturer Specific Data
        var parsedIBeacon: IBeaconData? = nil
        var manufacturerHex = ""
        if let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerHex = MinewPacketParser.dataToHexString(mfgData)
            parsedIBeacon = IBeaconParser.parseIBeacon(from: mfgData)
            
            if parsedHt == nil {
                parsedHt = MinewPacketParser.searchRawHtSignature(mfgData)
                if let ht = parsedHt {
                    parsedBattery = ht.batteryPercentage
                    resolvedMacFromFrame = ht.macInFrame
                }
            }
            if parsedBattery == nil {
                parsedBattery = MinewPacketParser.parseAnyMinewBattery(mfgData)
            }
        }
        
        // 3. Resolve Device Name
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let devName = localName ?? peripheral.name ?? parsedName ?? "Unknown"
        
        // 4. Resolve Device Key (Hardware MAC takes absolute precedence over iOS UUID)
        let resolvedMac: String
        let deviceKey: String
        
        if let frameMac = resolvedMacFromFrame, !frameMac.isEmpty {
            resolvedMac = frameMac
            deviceKey = frameMac
            uuidToMacMap[peripheral.identifier] = frameMac
            
            // Clean up old temporary UUID key if device was registered before MAC was discovered
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
        if let batt = parsedBattery { existing.batteryLevel = batt }
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

// MARK: - CLLocationManagerDelegate (iBeacon Ranging)
extension BleScannerManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if isScanning {
                startIBeaconRanging()
            }
        }
    }
    
    public func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        for beacon in beacons {
            handleRangedBeacon(beacon)
        }
    }
    
    private func handleRangedBeacon(_ beacon: CLBeacon) {
        let uuidStr = beacon.uuid.uuidString
        let major = beacon.major.intValue
        let minor = beacon.minor.intValue
        let rssi = beacon.rssi != 0 ? beacon.rssi : -70
        let accuracy = beacon.accuracy > 0 ? beacon.accuracy : nil
        
        let ibeaconData = IBeaconData(
            uuid: uuidStr,
            major: major,
            minor: minor,
            txPower: -59,
            accuracy: accuracy
        )
        
        // 1. Check if we can link this iBeacon to a discovered Minew S1 device
        // Since Minew S1 transmits both iBeacon and HT sensor packets, if we have a Minew S1 device
        // without iBeacon data or with matching RSSI, link it!
        var linkedToMinew = false
        for (key, var dev) in deviceMap {
            if dev.isMinewS1 {
                // If it doesn't have iBeacon data, or if RSSI is close (within 15 dBm)
                let rssiDiff = abs(dev.rssi - rssi)
                if dev.iBeaconData == nil || rssiDiff <= 15 {
                    dev.iBeaconData = ibeaconData
                    dev.lastSeenTimestamp = Date()
                    deviceMap[key] = dev
                    linkedToMinew = true
                    break
                }
            }
        }
        
        // 2. Also register or update dedicated iBeacon device card
        let ibeaconKey = "ibeacon-\(uuidStr)-\(major)-\(minor)"
        
        // If not already in deviceMap or needs update:
        var ibDevice = deviceMap[ibeaconKey] ?? BeaconDevice(
            peripheralId: UUID(),
            macAddress: "iBeacon [\(major):\(minor)]",
            name: "iBeacon (\(major):\(minor))",
            rssi: rssi,
            iBeaconData: ibeaconData
        )
        
        ibDevice.rssi = rssi
        ibDevice.lastSeenTimestamp = Date()
        ibDevice.iBeaconData = ibeaconData
        ibDevice.packetCount += 1
        
        // If there's battery info from a nearby Minew S1 beacon, copy it over
        if ibDevice.effectiveBattery == nil {
            if let minewDev = deviceMap.values.first(where: { $0.isMinewS1 && $0.effectiveBattery != nil }) {
                ibDevice.batteryLevel = minewDev.effectiveBattery
                ibDevice.minewHtData = minewDev.minewHtData
                if ibDevice.macAddress.hasPrefix("iBeacon") && minewDev.macAddress.contains(":") {
                    ibDevice.macAddress = minewDev.macAddress
                }
            }
        }
        
        deviceMap[ibeaconKey] = ibDevice
        updateDeviceList()
    }
}
