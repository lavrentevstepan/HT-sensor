package com.openbeacon.minewscanner

import com.openbeacon.minewscanner.data.parser.IBeaconParser
import com.openbeacon.minewscanner.data.parser.MinewPacketParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PacketParserTest {

    @Test
    fun testMinewHtPayloadParsing() {
        // Hex: a1 01 63 15 80 32 00 aa bb cc dd ee ff
        val hex = "a1016315803200aabbccddeeff"
        val bytes = hexStringToByteArray(hex)

        val htData = MinewPacketParser.parseHtPayload(bytes)
        assertNotNull(htData)
        val data = htData!!
        assertEquals(99, data.batteryPercentage)
        assertEquals(21.5f, data.temperature, 0.01f)
        assertEquals(50.0f, data.humidity, 0.01f)
        assertEquals("AA:BB:CC:DD:EE:FF", data.macInFrame)
    }

    @Test
    fun testMinewHtNegativeTemperature() {
        // Temperature -5.5°C: int8 = -5 (0xFB in two's complement), frac = 128/256 (0x80)
        // a1 01 50 fb 80 28 00 11 22 33 44 55 66
        val hex = "a10150fb802800112233445566"
        val bytes = hexStringToByteArray(hex)

        val htData = MinewPacketParser.parseHtPayload(bytes)
        assertNotNull(htData)
        val data = htData!!
        assertEquals(80, data.batteryPercentage)
        assertTrue(data.temperature < 0)
        assertEquals("11:22:33:44:55:66", data.macInFrame)
    }

    @Test
    fun testIBeaconParsingFromRaw() {
        // Apple company ID: 4C 00, Type: 02, Len: 15
        // UUID: FDA50693A4E24FB1AFCFC6EB07647825
        // Major: 00 01 (1)
        // Minor: 00 02 (2)
        // Tx: C5 (-59 dBm)
        val rawHex = "0201061AFF4C000215FDA50693A4E24FB1AFCFC6EB0764782500010002C5"
        val rawBytes = hexStringToByteArray(rawHex)

        val ibeacon = IBeaconParser.parseIBeacon(null, rawBytes)
        assertNotNull(ibeacon)
        val beacon = ibeacon!!
        assertEquals(1, beacon.major)
        assertEquals(2, beacon.minor)
        assertEquals(-59, beacon.txPower)
        assertEquals("FDA50693-A4E2-4FB1-AFCF-C6EB07647825", beacon.uuid)
    }

    private fun hexStringToByteArray(s: String): ByteArray {
        val len = s.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}
