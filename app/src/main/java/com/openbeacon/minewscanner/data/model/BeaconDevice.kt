package com.openbeacon.minewscanner.data.model

data class BeaconDevice(
    val macAddress: String,
    val name: String,
    val rssi: Int,
    val lastSeenTimestamp: Long = System.currentTimeMillis(),
    val minewHtData: MinewHtData? = null,
    val iBeaconData: IBeaconData? = null,
    val minewName: String? = null,
    val rawScanRecordHex: String = "",
    val rawServiceDataHex: Map<String, String> = emptyMap(),
    val rawManufacturerDataHex: Map<Int, String> = emptyMap(),
    val history: List<SensorDataPoint> = emptyList(),
    val isFavorite: Boolean = false,
    val packetCount: Int = 1
) {
    val isMinewS1: Boolean
        get() = minewHtData != null ||
                (minewName?.contains("S1", ignoreCase = true) == true) ||
                (name.contains("S1", ignoreCase = true))

    val displayName: String
        get() = when {
            !minewName.isNullOrBlank() -> minewName
            name.isNotBlank() && name != "Unknown" -> name
            isMinewS1 -> "Minew S1"
            else -> "BLE Beacon"
        }
}
