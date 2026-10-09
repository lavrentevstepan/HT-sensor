package com.openbeacon.minewscanner.data.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import com.openbeacon.minewscanner.data.model.BeaconDevice
import com.openbeacon.minewscanner.data.model.SensorDataPoint
import com.openbeacon.minewscanner.data.parser.IBeaconParser
import com.openbeacon.minewscanner.data.parser.MinewPacketParser
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.concurrent.ConcurrentHashMap

class BleScannerManager(private val context: Context) {

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    private var bleScanner: BluetoothLeScanner? = null

    private val deviceMap = ConcurrentHashMap<String, BeaconDevice>()
    private val _devicesFlow = MutableStateFlow<List<BeaconDevice>>(emptyList())
    val devicesFlow: StateFlow<List<BeaconDevice>> = _devicesFlow.asStateFlow()

    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.let { handleScanResult(it) }
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            results?.forEach { handleScanResult(it) }
        }

        override fun onScanFailed(errorCode: Int) {
            _isScanning.value = false
            _errorMessage.value = when (errorCode) {
                SCAN_FAILED_ALREADY_STARTED -> "Сканирование уже запущено"
                SCAN_FAILED_APPLICATION_REGISTRATION_FAILED -> "Ошибка регистрации в BLE стеке"
                SCAN_FAILED_INTERNAL_ERROR -> "Внутренняя ошибка Bluetooth"
                SCAN_FAILED_FEATURE_UNSUPPORTED -> "BLE сканирование не поддерживается"
                else -> "Ошибка сканирования BLE: $errorCode"
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun startScan() {
        if (_isScanning.value) return

        if (bluetoothAdapter == null || !bluetoothAdapter.isEnabled) {
            _errorMessage.value = "Bluetooth выключен. Включите Bluetooth на устройстве."
            return
        }

        bleScanner = bluetoothAdapter.bluetoothLeScanner
        if (bleScanner == null) {
            _errorMessage.value = "Не удалось инициализировать BLE сканер"
            return
        }

        _errorMessage.value = null

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setReportDelay(0)
            .build()

        // Empty filter to capture all advertising packets (Minew S1 broadcasts multiple slots)
        val filters = emptyList<ScanFilter>()

        try {
            bleScanner?.startScan(filters, settings, scanCallback)
            _isScanning.value = true
        } catch (e: Exception) {
            _errorMessage.value = "Исключение при старте сканирования: ${e.localizedMessage}"
            _isScanning.value = false
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        if (!_isScanning.value) return
        try {
            bleScanner?.stopScan(scanCallback)
        } catch (_: Exception) {
        } finally {
            _isScanning.value = false
        }
    }

    fun clearDevices() {
        deviceMap.clear()
        updateList()
    }

    fun toggleFavorite(macAddress: String) {
        deviceMap[macAddress]?.let { current ->
            deviceMap[macAddress] = current.copy(isFavorite = !current.isFavorite)
            updateList()
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleScanResult(result: ScanResult) {
        val device = result.device ?: return
        val address = device.address ?: return
        val scanRecord = result.scanRecord
        val rawBytes = scanRecord?.bytes
        val rssi = result.rssi

        val rawScanHex = MinewPacketParser.bytesToHex(rawBytes)

        // Parse Minew HT Data
        val htData = MinewPacketParser.parseHtData(scanRecord, rawBytes)
        // Parse Minew Name (from Info Frame or BLE Device Name)
        val minewName = MinewPacketParser.parseInfoName(scanRecord, rawBytes)
        // Parse iBeacon
        val iBeaconData = IBeaconParser.parseIBeacon(scanRecord, rawBytes)

        val deviceName = try {
            scanRecord?.deviceName ?: device.name ?: ""
        } catch (_: Exception) {
            ""
        }

        // Build raw maps for packet inspection
        val serviceDataMap = mutableMapOf<String, String>()
        scanRecord?.serviceData?.forEach { (uuid, data) ->
            if (uuid != null && data != null) {
                serviceDataMap[uuid.toString()] = MinewPacketParser.bytesToHex(data)
            }
        }

        val manufacturerDataMap = mutableMapOf<Int, String>()
        scanRecord?.manufacturerSpecificData?.let { sparse ->
            for (i in 0 until sparse.size()) {
                val key = sparse.keyAt(i)
                val data = sparse.valueAt(i)
                if (data != null) {
                    manufacturerDataMap[key] = MinewPacketParser.bytesToHex(data)
                }
            }
        }

        val existing = deviceMap[address]
        val updatedHistory = existing?.history?.toMutableList() ?: mutableListOf()

        // If new temperature/humidity reading arrived, append to history
        if (htData != null) {
            val shouldAdd = updatedHistory.isEmpty() ||
                    (System.currentTimeMillis() - updatedHistory.last().timestamp > 2000) ||
                    (updatedHistory.last().temperature != htData.temperature) ||
                    (updatedHistory.last().humidity != htData.humidity)

            if (shouldAdd) {
                updatedHistory.add(
                    SensorDataPoint(
                        timestamp = htData.timestamp,
                        temperature = htData.temperature,
                        humidity = htData.humidity,
                        rssi = rssi
                    )
                )
                // Keep last 40 data points
                if (updatedHistory.size > 40) {
                    updatedHistory.removeAt(0)
                }
            }
        }

        val updated = BeaconDevice(
            macAddress = address,
            name = if (deviceName.isNotBlank()) deviceName else existing?.name ?: "Unknown",
            rssi = rssi,
            lastSeenTimestamp = System.currentTimeMillis(),
            minewHtData = htData ?: existing?.minewHtData,
            iBeaconData = iBeaconData ?: existing?.iBeaconData,
            minewName = minewName ?: existing?.minewName,
            rawScanRecordHex = if (rawScanHex.isNotBlank()) rawScanHex else existing?.rawScanRecordHex ?: "",
            rawServiceDataHex = if (serviceDataMap.isNotEmpty()) (existing?.rawServiceDataHex.orEmpty() + serviceDataMap) else existing?.rawServiceDataHex.orEmpty(),
            rawManufacturerDataHex = if (manufacturerDataMap.isNotEmpty()) (existing?.rawManufacturerDataHex.orEmpty() + manufacturerDataMap) else existing?.rawManufacturerDataHex.orEmpty(),
            history = updatedHistory,
            isFavorite = existing?.isFavorite ?: false,
            packetCount = (existing?.packetCount ?: 0) + 1
        )

        deviceMap[address] = updated
        updateList()
    }

    private fun updateList() {
        val list = deviceMap.values.sortedWith(
            compareByDescending<BeaconDevice> { it.isFavorite }
                .thenByDescending { it.isMinewS1 }
                .thenByDescending { it.minewHtData != null }
                .thenByDescending { it.lastSeenTimestamp }
        )
        _devicesFlow.value = list
    }
}
