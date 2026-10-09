package com.openbeacon.minewscanner

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.openbeacon.minewscanner.data.ble.BleScannerManager
import com.openbeacon.minewscanner.ui.screens.ScannerScreen
import com.openbeacon.minewscanner.ui.theme.MinewBeaconScannerTheme

class MainActivity : ComponentActivity() {

    private lateinit var scannerManager: BleScannerManager

    private val bluetoothEnableLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            checkPermissionsAndStartScan()
        } else {
            Toast.makeText(this, "Bluetooth необходим для сканирования маячков", Toast.LENGTH_LONG).show()
        }
    }

    private val requestPermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val allGranted = permissions.entries.all { it.value }
        if (allGranted) {
            checkBluetoothAndScan()
        } else {
            Toast.makeText(
                this,
                "Для обнаружения BLE маячков требуются разрешения Bluetooth и геолокации",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        scannerManager = BleScannerManager(this)

        setContent {
            MinewBeaconScannerTheme {
                ScannerScreen(
                    scannerManager = scannerManager,
                    onRequestPermissions = { checkPermissionsAndStartScan() }
                )
            }
        }

        // Auto request permissions and start scan on app open
        checkPermissionsAndStartScan()
    }

    private fun checkPermissionsAndStartScan() {
        val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }

        val missing = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isNotEmpty()) {
            requestPermissionsLauncher.launch(missing.toTypedArray())
        } else {
            checkBluetoothAndScan()
        }
    }

    private fun checkBluetoothAndScan() {
        val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bm?.adapter

        if (adapter == null) {
            Toast.makeText(this, "Bluetooth не поддерживается данным устройством", Toast.LENGTH_SHORT).show()
            return
        }

        if (!adapter.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            bluetoothEnableLauncher.launch(enableBtIntent)
            return
        }

        scannerManager.startScan()
    }

    override fun onResume() {
        super.onResume()
        // Resume scan if permissions are ready
    }

    override fun onStop() {
        super.onStop()
        scannerManager.stopScan()
    }

    override fun onDestroy() {
        super.onDestroy()
        scannerManager.stopScan()
    }
}
