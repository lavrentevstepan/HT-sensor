package com.openbeacon.minewscanner.data.model

import kotlin.math.pow

data class IBeaconData(
    val uuid: String,
    val major: Int,
    val minor: Int,
    val txPower: Int,
    val timestamp: Long = System.currentTimeMillis()
) {
    /**
     * Approximates distance in meters using the log-distance path loss model.
     */
    fun calculateDistance(rssi: Int): Double {
        if (rssi == 0 || txPower == 0) return -1.0
        val ratio = (txPower - rssi) / (10.0 * 2.0)
        return 10.0.pow(ratio)
    }
}
