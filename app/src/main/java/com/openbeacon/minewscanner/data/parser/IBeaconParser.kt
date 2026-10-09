package com.openbeacon.minewscanner.data.parser

import android.bluetooth.le.ScanRecord
import com.openbeacon.minewscanner.data.model.IBeaconData
import java.util.Locale

object IBeaconParser {

    const val APPLE_MANUFACTURER_ID = 0x004C
    private const val IBEACON_TYPE: Byte = 0x02
    private const val IBEACON_DATA_LEN: Byte = 0x15

    /**
     * Parses iBeacon packet from ScanRecord or raw bytes.
     */
    fun parseIBeacon(scanRecord: ScanRecord?, rawBytes: ByteArray?): IBeaconData? {
        if (scanRecord != null) {
            val appleData = scanRecord.getManufacturerSpecificData(APPLE_MANUFACTURER_ID)
            if (appleData != null && appleData.size >= 23) {
                val parsed = parseFromApplePayload(appleData)
                if (parsed != null) return parsed
            }

            // Sometimes the manufacturer ID might be keyed differently in some phone implementations
            val sparseArray = scanRecord.manufacturerSpecificData
            for (i in 0 until sparseArray.size()) {
                val data = sparseArray.valueAt(i)
                val parsed = parseFromApplePayload(data)
                if (parsed != null) return parsed
            }
        }

        if (rawBytes != null && rawBytes.isNotEmpty()) {
            return searchRawIBeaconSignature(rawBytes)
        }

        return null
    }

    private fun parseFromApplePayload(data: ByteArray): IBeaconData? {
        if (data.size < 23) return null

        // Byte 0: 0x02, Byte 1: 0x15
        if (data[0] != IBEACON_TYPE || data[1] != IBEACON_DATA_LEN) {
            return null
        }

        val uuidBytes = data.copyOfRange(2, 18)
        val uuid = formatUuid(uuidBytes)

        val major = ((data[18].toInt() and 0xFF) shl 8) or (data[19].toInt() and 0xFF)
        val minor = ((data[20].toInt() and 0xFF) shl 8) or (data[21].toInt() and 0xFF)
        val txPower = data[22].toInt() // signed int8

        return IBeaconData(
            uuid = uuid,
            major = major,
            minor = minor,
            txPower = txPower
        )
    }

    private fun searchRawIBeaconSignature(bytes: ByteArray): IBeaconData? {
        // Pattern: [0x4C, 0x00, 0x02, 0x15, ...] or [0x02, 0x15, ...]
        for (i in 0..(bytes.size - 25)) {
            // Check for 0x4C 0x00 0x02 0x15
            if (bytes[i] == 0x4C.toByte() &&
                bytes[i + 1] == 0x00.toByte() &&
                bytes[i + 2] == IBEACON_TYPE &&
                bytes[i + 3] == IBEACON_DATA_LEN
            ) {
                val payload = bytes.copyOfRange(i + 2, i + 25)
                return parseFromApplePayload(payload)
            }
        }
        return null
    }

    private fun formatUuid(bytes: ByteArray): String {
        if (bytes.size != 16) return ""
        val hex = MinewPacketParser.bytesToHex(bytes).uppercase(Locale.ROOT)
        // Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX (8-4-4-4-12)
        return try {
            "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}"
        } catch (_: Exception) {
            hex
        }
    }
}
