import SwiftUI

public struct BeaconCardView: View {
    public let device: BeaconDevice
    public let onCardClick: () -> Void
    public let onToggleFavorite: () -> Void
    
    @State private var showCopiedAlert = false
    
    public init(
        device: BeaconDevice,
        onCardClick: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void
    ) {
        self.device = device
        self.onCardClick = onCardClick
        self.onToggleFavorite = onToggleFavorite
    }
    
    public var body: some View {
        Button(action: onCardClick) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Header Row
                HStack(alignment: .center, spacing: 12) {
                    // Status Beacon Icon
                    ZStack {
                        Circle()
                            .fill(device.isMinewS1 ? AppTheme.cyanNeon.opacity(0.15) : AppTheme.surfaceCardElevated)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: device.minewHtData != nil ? "thermometer.medium" : "dot.radiowaves.left.and.right")
                            .font(.system(size: 18))
                            .foregroundColor(device.isMinewS1 ? AppTheme.cyanNeon : AppTheme.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(device.displayName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                            
                            if device.isMinewS1 {
                                Text("Minew S1")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(AppTheme.cyanNeon)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.cyanNeon.opacity(0.18))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(AppTheme.cyanNeon.opacity(0.35), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // MAC Address with Copy Action
                        Button(action: copyMac) {
                            HStack(spacing: 4) {
                                Text(device.macAddress)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundColor(AppTheme.textSecondary)
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textMuted)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Favorite Toggle
                    Button(action: onToggleFavorite) {
                        Image(systemName: device.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundColor(device.isFavorite ? AppTheme.amberWarm : AppTheme.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Sensor Telemetry Pills (Temperature, Humidity, Battery)
                if let ht = device.minewHtData {
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
                        
                        MetricPillView(
                            icon: "battery.100",
                            label: "Батарея",
                            value: "\(ht.batteryPercentage)%",
                            color: AppTheme.batteryColor(ht.batteryPercentage)
                        )
                    }
                }
                
                // iBeacon Section
                if let ibeacon = device.iBeaconData {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iBeacon")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.purpleAccent)
                            Text("Major: \(ibeacon.major)  |  Minor: \(ibeacon.minor)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        let dist = ibeacon.calculateDistance(rssi: device.rssi)
                        Text(dist > 0 ? String(format: "Дистанция: ~%.1f м", dist) : "Tx: \(ibeacon.txPower) dBm")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(8)
                    .background(AppTheme.surfaceCardElevated)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.borderStroke, lineWidth: 1)
                    )
                }
                
                // Footer: RSSI Bars, Packet Count, Time Ago
                HStack {
                    RssiBarsView(rssi: device.rssi)
                    Text("\(device.rssi) dBm")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.rssiColor(device.rssi))
                    
                    Spacer()
                    
                    Text("Пакетов: \(device.packetCount)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                    
                    Text(formatTimeAgo(device.lastSeenTimestamp))
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(16)
            .background(AppTheme.surfaceCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var borderColor: Color {
        if device.isFavorite {
            return AppTheme.amberWarm.opacity(0.6)
        }
        if device.isMinewS1 {
            return AppTheme.cyanNeon.opacity(0.5)
        }
        return AppTheme.borderStroke
    }
    
    private func copyMac() {
        UIPasteboard.general.string = device.macAddress
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let sec = Int(Date().timeIntervalSince(date))
        if sec < 2 { return "сейчас" }
        if sec < 60 { return "\(sec) сек назад" }
        if sec < 3600 { return "\(sec / 60) мин назад" }
        return "\(sec / 3600) ч назад"
    }
}

public struct MetricPillView: View {
    public let icon: String
    public let label: String
    public let value: String
    public let color: Color
    
    public var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(color.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

public struct RssiBarsView: View {
    public let rssi: Int
    
    public var body: some View {
        let level: Int = {
            if rssi >= -60 { return 4 }
            if rssi >= -75 { return 3 }
            if rssi >= -85 { return 2 }
            return 1
        }()
        let barColor = AppTheme.rssiColor(rssi)
        
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i <= level ? barColor : AppTheme.textMuted.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + (i * 3)))
            }
        }
    }
}
