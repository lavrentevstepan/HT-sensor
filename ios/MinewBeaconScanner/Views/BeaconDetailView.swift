import SwiftUI

public struct BeaconDetailView: View {
    public let device: BeaconDevice
    public let onDismiss: () -> Void
    
    public init(device: BeaconDevice, onDismiss: @escaping () -> Void) {
        self.device = device
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header: Name & MAC Address
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.displayName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Button(action: { UIPasteboard.general.string = device.macAddress }) {
                                HStack(spacing: 6) {
                                    Text(device.macAddress)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(AppTheme.cyanNeon)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // SECTION 1: Minew S1 Sensor Telemetry
                        if let ht = device.minewHtData {
                            SectionBoxView(title: "Телеметрия Minew S1 (HT Sensor)", accentColor: AppTheme.cyanNeon) {
                                HStack(spacing: 8) {
                                    MetricPillView(
                                        icon: "thermometer.medium",
                                        label: "Температура",
                                        value: String(format: "%.1f °C", ht.temperature),
                                        color: AppTheme.temperatureColor(ht.temperature)
                                    )
                                    MetricPillView(
                                        icon: "humidity.fill",
                                        label: "Влажность",
                                        value: String(format: "%.1f %%", ht.humidity),
                                        color: AppTheme.cyanNeon
                                    )
                                    let batt = device.effectiveBattery ?? ht.batteryPercentage
                                    MetricPillView(
                                        icon: "battery.100",
                                        label: "Батарея",
                                        value: "\(batt)%",
                                        color: AppTheme.batteryColor(batt)
                                    )
                                }
                                
                                Divider().background(AppTheme.borderStroke)
                                
                                DetailParamRow(label: "MAC в кадре S1", value: ht.macInFrame)
                                DetailParamRow(label: "Версия кадра", value: "0x01 (HT Sensor)")
                                DetailParamRow(label: "Тип кадра", value: "0xA1 (BeaconPlus)")
                                
                                // Graphs
                                if device.history.count >= 2 {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("График температуры (°C)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                        SensorLineChart(
                                            points: device.history.map { $0.temperature },
                                            lineColor: AppTheme.emeraldGreen
                                        )
                                        .frame(height: 60)
                                    }
                                    .padding(.top, 4)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("График влажности (%)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                        SensorLineChart(
                                            points: device.history.map { $0.humidity },
                                            lineColor: AppTheme.cyanNeon
                                        )
                                        .frame(height: 60)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        } else if let batt = device.effectiveBattery {
                            SectionBoxView(title: "Питание устройства", accentColor: AppTheme.emeraldGreen) {
                                HStack(spacing: 8) {
                                    MetricPillView(
                                        icon: "battery.100",
                                        label: "Уровень заряда",
                                        value: "\(batt)%",
                                        color: AppTheme.batteryColor(batt)
                                    )
                                }
                            }
                        }
                        
                        // SECTION 2: iBeacon Telemetry
                        if let ib = device.iBeaconData {
                            SectionBoxView(title: "Пакет iBeacon (Apple Profile)", accentColor: AppTheme.purpleAccent) {
                                if let batt = device.effectiveBattery {
                                    DetailParamRow(label: "Заряд батареи", value: "\(batt)%")
                                }
                                DetailParamRow(label: "Major", value: "\(ib.major)")
                                DetailParamRow(label: "Minor", value: "\(ib.minor)")
                                DetailParamRow(label: "UUID", value: ib.uuid, onCopy: {
                                    UIPasteboard.general.string = ib.uuid
                                })
                                DetailParamRow(label: "Tx Power (1м)", value: "\(ib.txPower) dBm")
                                
                                let dist = ib.calculateDistance(rssi: device.rssi)
                                DetailParamRow(
                                    label: "Примерная дистанция",
                                    value: dist > 0 ? String(format: "~%.2f м", dist) : "Неизвестно"
                                )
                            }
                        }
                        
                        // SECTION 3: Signal Stats
                        SectionBoxView(title: "Статистика BLE сигнала", accentColor: AppTheme.amberWarm) {
                            DetailParamRow(label: "Уровень RSSI", value: "\(device.rssi) dBm")
                            DetailParamRow(label: "Всего пакетов принято", value: "\(device.packetCount)")
                            DetailParamRow(label: "Имя устройства BLE", value: device.name)
                            DetailParamRow(label: "CoreBluetooth UUID", value: device.peripheralId.uuidString)
                        }
                        
                        // SECTION 4: RAW Hex Inspector
                        SectionBoxView(title: "RAW инспектор пакетов", accentColor: AppTheme.textMuted) {
                            if !device.rawServiceDataHex.isEmpty {
                                Text("Данные сервисов (Service Data):")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                ForEach(device.rawServiceDataHex.sorted(by: { $0.key < $1.key }), id: \.key) { uuid, hex in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("UUID: \(uuid)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(AppTheme.cyanNeon)
                                        HexDumpBox(hex: hex)
                                    }
                                }
                            }
                            
                            if !device.rawManufacturerDataHex.isEmpty {
                                Text("Manufacturer Data:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.top, 4)
                                HexDumpBox(hex: device.rawManufacturerDataHex)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { onDismiss() }
                        .foregroundColor(AppTheme.cyanNeon)
                }
            }
        }
    }
}

public struct SectionBoxView<Content: View>: View {
    public let title: String
    public let accentColor: Color
    public let content: Content
    
    public init(title: String, accentColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.accentColor = accentColor
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accentColor)
            content
        }
        .padding(14)
        .background(AppTheme.surfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.borderStroke, lineWidth: 1)
        )
    }
}

public struct DetailParamRow: View {
    public let label: String
    public let value: String
    public var onCopy: (() -> Void)? = nil
    
    public var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            if let copyAction = onCopy {
                Button(action: copyAction) {
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            } else {
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
    }
}

public struct HexDumpBox: View {
    public let hex: String
    
    public var body: some View {
        Button(action: { UIPasteboard.general.string = hex }) {
            HStack {
                Text(hex)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(8)
            .background(AppTheme.surfaceCardElevated)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.borderStroke, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct SensorLineChart: View {
    public let points: [Float]
    public let lineColor: Color
    
    public var body: some View {
        GeometryReader { geo in
            let minVal = points.min() ?? 0
            let maxVal = points.max() ?? 1
            let range = (maxVal - minVal) > 0.01 ? (maxVal - minVal) : 1.0
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(max(points.count - 1, 1))
            
            ZStack {
                AppTheme.surfaceCardElevated
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.borderStroke, lineWidth: 1)
                    )
                
                Path { path in
                    for (i, val) in points.enumerated() {
                        let x = CGFloat(i) * step
                        let normalized = CGFloat((val - minVal) / range)
                        let y = h - (normalized * (h - 16)) - 8
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, lineWidth: 2)
                .padding(.horizontal, 8)
            }
        }
    }
}
