package com.openbeacon.minewscanner.data.model

data class SensorDataPoint(
    val timestamp: Long,
    val temperature: Float,
    val humidity: Float,
    val rssi: Int
)
