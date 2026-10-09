import SwiftUI

public enum FilterType: String, CaseIterable {
    case all = "Все"
    case minewS1 = "Minew S1"
    case ibeacon = "iBeacon"
    case favorites = "Избранные"
}

public struct ScannerView: View {
    @ObservedObject public var scannerManager: BleScannerManager
    
    @State private var searchQuery: String = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedDevice: BeaconDevice? = nil
    @State private var showUuidSheet: Bool = false
    @State private var customUuidInput: String = ""
    @State private var uuidAddError: String? = nil
    
    public init(scannerManager: BleScannerManager) {
        self.scannerManager = scannerManager
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.bgDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Custom Navigation Bar
                HStack(spacing: 12) {
                    RadarScanIndicatorView(isScanning: scannerManager.isScanning, size: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Minew S1 Scanner")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(scannerManager.isScanning ? "Сканирование в эфире..." : "Сканирование остановлено")
                            .font(.system(size: 11))
                            .foregroundColor(scannerManager.isScanning ? AppTheme.cyanNeon : AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // iBeacon UUID Manager Button
                    Button(action: { showUuidSheet = true }) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.purpleAccent)
                            .padding(8)
                            .background(AppTheme.purpleAccent.opacity(0.12))
                            .cornerRadius(8)
                    }
                    
                    if !scannerManager.devices.isEmpty {
                        Button(action: { scannerManager.clearDevices() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.bgDark)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.cyanNeon)
                        .font(.system(size: 14))
                    
                    TextField("Поиск по MAC (напр. AC:23), имени или Major:Minor", text: $searchQuery)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.surfaceCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.borderStroke, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // Filter Tabs (Chips)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            let count = getFilterCount(filter)
                            let isSelected = selectedFilter == filter
                            
                            Button(action: { selectedFilter = filter }) {
                                HStack(spacing: 4) {
                                    Text("\(filter.rawValue) (\(count))")
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? AppTheme.cyanNeon.opacity(0.2) : AppTheme.surfaceCard)
                                .foregroundColor(isSelected ? AppTheme.cyanNeon : AppTheme.textSecondary)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isSelected ? AppTheme.cyanNeon.opacity(0.4) : AppTheme.borderStroke, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                
                // Error Banner if Bluetooth is off
                if let err = scannerManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.amberWarm)
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.amberWarm.opacity(0.15))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
                
                // Device List or Empty State
                let filtered = filteredDevices
                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        RadarScanIndicatorView(isScanning: scannerManager.isScanning, size: 64)
                        
                        Text(scannerManager.isScanning ? "Поиск BLE маячков..." : "Сканирование не запущено")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(scannerManager.isScanning ?
                             "Поднесите маячок Minew S1 ближе к iPhone.\nУбедитесь, что Bluetooth и Геолокация включены." :
                             "Нажмите кнопку «Сканировать» внизу экрана для начала поиска.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { device in
                                BeaconCardView(
                                    device: device,
                                    onCardClick: { selectedDevice = device },
                                    onToggleFavorite: { scannerManager.toggleFavorite(id: device.id) }
                                )
                            }
                            Spacer().frame(height: 80) // Floating action button padding
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    }
                }
            }
            
            // Floating Action Button
            Button(action: {
                if scannerManager.isScanning {
                    scannerManager.stopScan()
                } else {
                    scannerManager.startScan()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: scannerManager.isScanning ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(scannerManager.isScanning ? "Остановить" : "Сканировать")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(AppTheme.bgDark)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(scannerManager.isScanning ? AppTheme.roseHot : AppTheme.cyanNeon)
                .cornerRadius(24)
                .shadow(color: (scannerManager.isScanning ? AppTheme.roseHot : AppTheme.cyanNeon).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedDevice) { device in
            let freshDevice = scannerManager.devices.first(where: { $0.id == device.id }) ?? device
            BeaconDetailView(device: freshDevice, onDismiss: { selectedDevice = nil })
        }
        .sheet(isPresented: $showUuidSheet) {
            UuidManagerSheet(
                scannerManager: scannerManager,
                onDismiss: { showUuidSheet = false }
            )
        }
    }
    
    private var filteredDevices: [BeaconDevice] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return scannerManager.devices.filter { dev in
            let majorStr = dev.iBeaconData.map { "\($0.major)" } ?? ""
            let minorStr = dev.iBeaconData.map { "\($0.minor)" } ?? ""
            
            let matchesSearch = query.isEmpty ||
                dev.macAddress.lowercased().contains(query) ||
                dev.name.lowercased().contains(query) ||
                dev.displayName.lowercased().contains(query) ||
                majorStr.contains(query) ||
                minorStr.contains(query) ||
                (dev.iBeaconData?.uuid.lowercased().contains(query) == true)
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .minewS1:
                matchesFilter = dev.isMinewS1
            case .ibeacon:
                matchesFilter = dev.iBeaconData != nil
            case .favorites:
                matchesFilter = dev.isFavorite
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    private func getFilterCount(_ filter: FilterType) -> Int {
        switch filter {
        case .all:
            return scannerManager.devices.count
        case .minewS1:
            return scannerManager.devices.filter { $0.isMinewS1 }.count
        case .ibeacon:
            return scannerManager.devices.filter { $0.iBeaconData != nil }.count
        case .favorites:
            return scannerManager.devices.filter { $0.isFavorite }.count
        }
    }
}

public struct UuidManagerSheet: View {
    @ObservedObject public var scannerManager: BleScannerManager
    public let onDismiss: () -> Void
    
    @State private var inputUuid: String = ""
    @State private var errorMessage: String? = nil
    
    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("iOS требует предварительного указания UUID для сканирования iBeacon через CoreLocation. Маячки Minew S1 обычно используют заводской UUID Minew BeaconPlus.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        // Add Custom UUID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Добавить пользовательский UUID")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.cyanNeon)
                            
                            HStack {
                                TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $inputUuid)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Button("Добавить") {
                                    let trimmed = inputUuid.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if scannerManager.addCustomBeaconUuid(trimmed) {
                                        inputUuid = ""
                                        errorMessage = nil
                                    } else {
                                        errorMessage = "Некорректный формат UUID"
                                    }
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.bgDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppTheme.cyanNeon)
                                .cornerRadius(8)
                            }
                            .padding(10)
                            .background(AppTheme.surfaceCard)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.borderStroke, lineWidth: 1)
                            )
                            
                            if let err = errorMessage {
                                Text(err)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.roseHot)
                            }
                        }
                        
                        // Active UUIDs List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Активные UUID для поиска iBeacon (\(scannerManager.monitoredUuids.count))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            ForEach(scannerManager.monitoredUuids, id: \.self) { uuid in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(uuidLabel(uuid.uuidString))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.purpleAccent)
                                        Text(uuid.uuidString)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Button(action: { UIPasteboard.general.string = uuid.uuidString }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                }
                                .padding(10)
                                .background(AppTheme.surfaceCard)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.borderStroke, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("iBeacon UUID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { onDismiss() }
                        .foregroundColor(AppTheme.cyanNeon)
                }
            }
        }
    }
    
    private func uuidLabel(_ uuidStr: String) -> String {
        switch uuidStr.uppercased() {
        case "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0":
            return "Minew BeaconPlus (S1 по умолчанию)"
        case "FDA50693-A4E2-4FB1-AFCF-C6EB07647825":
            return "Minew WeChat (Альтернативный)"
        case "B9407F30-F5F8-466E-AFF9-25556B57FE6D":
            return "Estimote"
        case "74278BDA-B644-4520-8F0C-720EAF059935":
            return "Apple AirLocate"
        case "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6":
            return "Radius Networks"
        default:
            return "Пользовательский"
        }
    }
}
