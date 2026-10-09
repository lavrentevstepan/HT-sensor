import SwiftUI

public struct RadarScanIndicatorView: View {
    public let isScanning: Bool
    public var size: CGFloat = 28
    
    @State private var pulseAnimation: Bool = false
    
    public init(isScanning: Bool, size: CGFloat = 28) {
        self.isScanning = isScanning
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            if isScanning {
                // Outer expanding ripple ring
                Circle()
                    .stroke(AppTheme.cyanNeon.opacity(pulseAnimation ? 0.0 : 0.8), lineWidth: 2)
                    .scaleEffect(pulseAnimation ? 1.0 : 0.3)
                    .animation(
                        Animation.easeOut(duration: 1.6).repeatForever(autoreverses: false),
                        value: pulseAnimation
                    )
            } else {
                Circle()
                    .stroke(AppTheme.cyanNeon.opacity(0.3), lineWidth: 2)
                    .frame(width: size, height: size)
            }
            
            // Core beacon center dot
            Circle()
                .fill(AppTheme.cyanNeon)
                .frame(width: 8, height: 8)
        }
        .frame(width: size, height: size)
        .onAppear {
            if isScanning {
                pulseAnimation = true
            }
        }
        .onChange(of: isScanning) { newValue in
            pulseAnimation = newValue
        }
    }
}
