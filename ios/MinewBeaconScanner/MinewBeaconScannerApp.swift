import SwiftUI

@main
struct MinewBeaconScannerApp: App {
    @StateObject private var scannerManager = BleScannerManager()
    
    var body: some Scene {
        WindowGroup {
            ScannerView(scannerManager: scannerManager)
                .preferredColorScheme(.dark)
        }
    }
}
