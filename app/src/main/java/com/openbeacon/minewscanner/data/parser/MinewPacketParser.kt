package com.openbeacon.minewscanner.data.parser

import android.bluetooth.le.ScanRecord
import android.os.ParcelUuid
import com.openbeacon.minewscanner.data.model.MinewHtData
import java.util.Locale

object MinewPacketParser {

    const val MINEW_SERVICE_UUID_STR = "0000ffe1-0000-1000-8000-00805f9b34fb"
    val MINEW_SERVICE_UUID: ParcelUuid by lazy { ParcelUuid.fromString(MINEW_SERVICE_UUID_STR) }

    const val MINEW_FRAME_TYPE: Byte = 0xA1.toByte()
    const val FRAME_VERSION_HT: Byte = 0x01.toByte()
    const val FRAME_VERSION_INFO: Byte = 0x08.toByte()

    /**
     * Parses Minew HT sensor data from ScanRecord or raw bytes.
     */
    fun parseHtData(scanRecord: ScanRecord?, rawBytes: ByteArray?): MinewHtData? {
        // 1. Check Service Data map first
        if (scanRecord != null) {
            val serviceData = scanRecord.serviceData
            for ((uuid, data) in serviceData) {
                if (uuid != null && isMinewUuid(uuid)) {
                    val parsed = parseHtPayload(data)
                    if (parsed != null) return parsed
                }
            }
        }

        // 2. Check raw bytes by parsing AD structures or finding 0xA1 0x01 signature
        if (rawBytes != null && rawBytes.isNotEmpty()) {
            val parsedFromAd = parseFromRawAdStructures(rawBytes)
            if (parsedFromAd != null) return parsedFromAd

            val parsedFromSearch = searchRawHtSignature(rawBytes)
            if (parsedFromSearch != null) return parsedFromSearch
        }

        return null
    }

    /**
     * Parses Minew Info frame (0xA1 0x08) to extract device name and battery.
     */
    fun parseInfoName(scanRecord: ScanRecord?, rawBytes: ByteArray?): String? {
        if (scanRecord != null) {
            for ((uuid, data) in scanRecord.serviceData) {
                if (uuid != null && isMinewUuid(uuid)) {
                    val name = parseInfoPayload(data)
                    if (name != null) return name
                }
            }
        }
        if (rawBytes != null && rawBytes.isNotEmpty()) {
            return searchRawInfoName(rawBytes)
        }
        return null
    }

    private fun isMinewUuid(uuid: ParcelUuid): Boolean {
        val s = uuid.toString().lowercase(Locale.ROOT)
        return s.contains("ffe1")
    }

    /**
     * Parses standard Minew HT payload (13 bytes):
     * [0] = 0xA1 (Frame Type)
     * [1] = 0x01 (Version HT)
     * [2] = Battery % (0..100)
     * [3..4] = Temperature (Signed 8.8 fixed-point in °C)
     * [5..6] = Humidity (Signed/Unsigned 8.8 fixed-point in %)
     * [7..12] = Device MAC address (6 bytes)
     */
    fun parseHtPayload(data: ByteArray?): MinewHtData? {
        if (data == null || data.size < 13) return null

        if (data[0] != MINEW_FRAME_TYPE || data[1] != FRAME_VERSION_HT) {
            return null
        }

        val battery = data[2].toInt() and 0xFF

        // Temperature: Signed 8.8
        val tempInt = data[3].toInt() // preserves sign
        val tempFrac = (data[4].toInt() and 0xFF) / 256.0f
        val temperature = (tempInt + (if (tempInt >= 0) tempFrac else -tempFrac)).let {
            // Alternatively standard signed 8.8 is: int8 + uint8/256.0
            data[3].toInt() + ((data[4].toInt() and 0xFF) / 256.0f)
        }

        // Relative Humidity: 8.8 (0..100)
        val humInt = data[5].toInt() and 0xFF
        val humFrac = (data[6].toInt() and 0xFF) / 256.0f
        val humidity = humInt + humFrac

        val mac = String.format(
            Locale.US,
            "%02X:%02X:%02X:%02X:%02X:%02X",
            data[7], data[8], data[9], data[10], data[11], data[12]
        )

        return MinewHtData(
            temperature = roundToOneDecimal(temperature),
            humidity = roundToOneDecimal(humidity),
            batteryPercentage = battery.coerceIn(0, 100),
            macInFrame = mac,
            frameVersion = 1
        )
    }

    private fun parseInfoPayload(data: ByteArray?): String? {
        if (data == null || data.size < 9) return null
        if (data[0] != MINEW_FRAME_TYPE || data[1] != FRAME_VERSION_INFO) {
            return null
        }
        return try {
            String(data, 9, data.size - 9, Charsets.UTF_8).trim()
        } catch (_: Exception) {
            null
        }
    }

    private fun parseFromRawAdStructures(bytes: ByteArray): MinewHtData? {
        var index = 0
        while (index < bytes.size - 2) {
            val length = bytes[index].toInt() and 0xFF
            if (length == 0) break
            if (index + length >= bytes.size) break

            val adType = bytes[index + 1].toInt() and 0xFF
            val dataStart = index + 2
            val dataLen = length - 1

            // 0x16 = Service Data - 16 bit UUID
            if (adType == 0x16 && dataLen >= 15) {
                // 16-bit UUID (2 bytes, little-endian: 0xE1 0xFF)
                val u0 = bytes[dataStart].toInt() and 0xFF
                val u1 = bytes[dataStart + 1].toInt() and 0xFF
                if (u0 == 0xE1 && u1 == 0xFF) {
                    val payload = bytes.copyOfRange(dataStart + 2, dataStart + dataLen)
                    val parsed = parseHtPayload(payload)
                    if (parsed != null) return parsed
                }
            }

            index += length + 1
        }
        return null
    }

    private fun searchRawHtSignature(bytes: ByteArray): MinewHtData? {
        for (i in 0..(bytes.size - 13)) {
            if (bytes[i] == MINEW_FRAME_TYPE && bytes[i + 1] == FRAME_VERSION_HT) {
                val candidate = bytes.copyOfRange(i, i + 13)
                val parsed = parseHtPayload(candidate)
                if (parsed != null) return parsed
            }
        }
        return null
    }

    private fun searchRawInfoName(bytes: ByteArray): String? {
        for (i in 0..(bytes.size - 9)) {
            if (bytes[i] == MINEW_FRAME_TYPE && bytes[i + 1] == FRAME_VERSION_INFO) {
                val nameBytes = bytes.copyOfRange(i + 9, bytes.size)
                val str = String(nameBytes, Charsets.UTF_8).takeWhile { it.isLetterOrDigit() || it in "_- " }
                if (str.isNotBlank()) return str.trim()
            }
        }
        return null
    }

    private fun roundToOneDecimal(value: Float): Float {
        return (Math.round(value * 10.0f) / 10.0f)
    }

    fun bytesToHex(bytes: ByteArray?): String {
        if (bytes == null || bytes.isEmpty()) return ""
        val sb = StringBuilder(bytes.size * 2)
        for (b in bytes) {
            sb.append(String.format("%02X", b))
        }
        return sb.toString()
    }
}
