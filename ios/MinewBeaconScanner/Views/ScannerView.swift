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
                    
                    TextField("Поиск по MAC (напр. AC:23) или имени", text: $searchQuery)
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
                             "Поднесите маячок Minew S1 ближе к iPhone.\nУбедитесь, что батарейка установлена." :
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
            // Use fresh instance from manager if available
            let freshDevice = scannerManager.devices.first(where: { $0.id == device.id }) ?? device
            BeaconDetailView(device: freshDevice, onDismiss: { selectedDevice = nil })
        }
    }
    
    private var filteredDevices: [BeaconDevice] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return scannerManager.devices.filter { dev in
            let matchesSearch = query.isEmpty ||
                dev.macAddress.lowercased().contains(query) ||
                dev.name.lowercased().contains(query) ||
                dev.displayName.lowercased().contains(query) ||
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
