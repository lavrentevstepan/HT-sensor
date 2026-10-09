package com.openbeacon.minewscanner.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.WifiTethering
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openbeacon.minewscanner.data.ble.BleScannerManager
import com.openbeacon.minewscanner.data.model.BeaconDevice
import com.openbeacon.minewscanner.ui.components.BeaconCard
import com.openbeacon.minewscanner.ui.components.BeaconDetailDialog
import com.openbeacon.minewscanner.ui.components.RadarScanIndicator
import com.openbeacon.minewscanner.ui.theme.BgDark
import com.openbeacon.minewscanner.ui.theme.BorderStroke
import com.openbeacon.minewscanner.ui.theme.CyanNeon
import com.openbeacon.minewscanner.ui.theme.EmeraldGreen
import com.openbeacon.minewscanner.ui.theme.RoseHot
import com.openbeacon.minewscanner.ui.theme.SurfaceCard
import com.openbeacon.minewscanner.ui.theme.SurfaceCardElevated
import com.openbeacon.minewscanner.ui.theme.TextMuted
import com.openbeacon.minewscanner.ui.theme.TextPrimary
import com.openbeacon.minewscanner.ui.theme.TextSecondary
import java.util.Locale

enum class FilterType {
    ALL,
    MINEW_S1,
    IBEACON,
    FAVORITES
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScannerScreen(
    scannerManager: BleScannerManager,
    onRequestPermissions: () -> Unit
) {
    val devices by scannerManager.devicesFlow.collectAsState()
    val isScanning by scannerManager.isScanning.collectAsState()
    val errorMessage by scannerManager.errorMessage.collectAsState()

    var searchQuery by remember { mutableStateOf("") }
    var selectedFilter by remember { mutableStateOf(FilterType.ALL) }
    var selectedDeviceForDetails by remember { mutableStateOf<BeaconDevice?>(null) }

    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(errorMessage) {
        errorMessage?.let {
            snackbarHostState.showSnackbar(it)
        }
    }

    // Filter devices
    val filteredDevices = remember(devices, searchQuery, selectedFilter) {
        val query = searchQuery.trim().lowercase(Locale.ROOT)
        devices.filter { dev ->
            val matchesSearch = query.isEmpty() ||
                    dev.macAddress.lowercase(Locale.ROOT).contains(query) ||
                    dev.name.lowercase(Locale.ROOT).contains(query) ||
                    dev.displayName.lowercase(Locale.ROOT).contains(query) ||
                    (dev.iBeaconData?.uuid?.lowercase(Locale.ROOT)?.contains(query) == true)

            val matchesFilter = when (selectedFilter) {
                FilterType.ALL -> true
                FilterType.MINEW_S1 -> dev.isMinewS1
                FilterType.IBEACON -> dev.iBeaconData != null
                FilterType.FAVORITES -> dev.isFavorite
            }

            matchesSearch && matchesFilter
        }
    }

    val minewCount = devices.count { it.isMinewS1 }
    val ibeaconCount = devices.count { it.iBeaconData != null }
    val favoriteCount = devices.count { it.isFavorite }

    Scaffold(
        containerColor = BgDark,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        RadarScanIndicator(isScanning = isScanning)
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = "Minew S1 Scanner",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = TextPrimary
                            )
                            Text(
                                text = if (isScanning) "Сканирование в эфире..." else "Сканирование остановлено",
                                fontSize = 11.sp,
                                color = if (isScanning) CyanNeon else TextSecondary
                            )
                        }
                    }
                },
                actions = {
                    if (devices.isNotEmpty()) {
                        IconButton(onClick = { scannerManager.clearDevices() }) {
                            Icon(
                                imageVector = Icons.Default.DeleteSweep,
                                contentDescription = "Clear List",
                                tint = TextSecondary
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = BgDark,
                    titleContentColor = TextPrimary
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = {
                    if (isScanning) {
                        scannerManager.stopScan()
                    } else {
                        onRequestPermissions()
                    }
                },
                containerColor = if (isScanning) RoseHot else CyanNeon,
                contentColor = BgDark,
                shape = RoundedCornerShape(16.dp),
                icon = {
                    Icon(
                        imageVector = if (isScanning) Icons.Default.Stop else Icons.Default.PlayArrow,
                        contentDescription = null
                    )
                },
                text = {
                    Text(
                        text = if (isScanning) "Остановить" else "Сканировать",
                        fontWeight = FontWeight.Bold
                    )
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                placeholder = {
                    Text("Поиск по MAC (напр. AC:23) или имени", fontSize = 13.sp, color = TextMuted)
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Search, contentDescription = null, tint = CyanNeon)
                },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(imageVector = Icons.Default.Clear, contentDescription = "Clear", tint = TextSecondary)
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = SurfaceCard,
                    unfocusedContainerColor = SurfaceCard,
                    focusedBorderColor = CyanNeon,
                    unfocusedBorderColor = BorderStroke,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                )
            )

            // Filter Chips
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedFilter == FilterType.ALL,
                        onClick = { selectedFilter = FilterType.ALL },
                        label = { Text("Все (${devices.size})") },
                        colors = chipColors()
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == FilterType.MINEW_S1,
                        onClick = { selectedFilter = FilterType.MINEW_S1 },
                        label = { Text("Minew S1 ($minewCount)") },
                        colors = chipColors()
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == FilterType.IBEACON,
                        onClick = { selectedFilter = FilterType.IBEACON },
                        label = { Text("iBeacon ($ibeaconCount)") },
                        colors = chipColors()
                    )
                }
                item {
                    FilterChip(
                        selected = selectedFilter == FilterType.FAVORITES,
                        onClick = { selectedFilter = FilterType.FAVORITES },
                        label = { Text("Избранные ($favoriteCount)") },
                        colors = chipColors()
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Device List / Empty State
            if (filteredDevices.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        RadarScanIndicator(
                            isScanning = isScanning,
                            modifier = Modifier.size(64.dp),
                            color = CyanNeon
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = if (isScanning) "Поиск BLE маячков..." else "Сканирование не запущено",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = TextPrimary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = if (isScanning)
                                "Поднесите ваш маячок Minew S1 ближе к телефону.\nУбедитесь, что батарейка установлена."
                            else
                                "Нажмите кнопку «Сканировать» внизу экрана для начала поиска.",
                            fontSize = 13.sp,
                            color = TextSecondary,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(filteredDevices, key = { it.macAddress }) { device ->
                        BeaconCard(
                            device = device,
                            onCardClick = { selectedDeviceForDetails = device },
                            onToggleFavorite = { scannerManager.toggleFavorite(device.macAddress) }
                        )
                    }
                    item {
                        Spacer(modifier = Modifier.height(72.dp)) // FAB padding
                    }
                }
            }
        }
    }

    // Detail Dialog
    selectedDeviceForDetails?.let { dev ->
        // Retrieve fresh instance from devices list if available
        val freshDev = devices.find { it.macAddress == dev.macAddress } ?: dev
        BeaconDetailDialog(
            device = freshDev,
            onDismiss = { selectedDeviceForDetails = null }
        )
    }
}

@Composable
private fun chipColors() = FilterChipDefaults.filterChipColors(
    containerColor = SurfaceCard,
    selectedContainerColor = CyanNeon.copy(alpha = 0.2f),
    labelColor = TextSecondary,
    selectedLabelColor = CyanNeon
)
