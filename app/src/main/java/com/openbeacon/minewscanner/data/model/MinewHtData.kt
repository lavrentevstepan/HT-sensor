package com.openbeacon.minewscanner.data.model

data class MinewHtData(
    val temperature: Float,       // In degrees Celsius (°C)
    val humidity: Float,          // Relative humidity in %
    val batteryPercentage: Int,   // 0 - 100%
    val macInFrame: String,       // Hardware MAC embedded in Minew payload
    val frameVersion: Int = 1,
    val timestamp: Long = System.currentTimeMillis()
)
