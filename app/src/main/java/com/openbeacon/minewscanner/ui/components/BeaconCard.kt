package com.openbeacon.minewscanner.ui.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BatteryFull
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material3.Badge
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openbeacon.minewscanner.data.model.BeaconDevice
import com.openbeacon.minewscanner.ui.theme.AmberWarm
import com.openbeacon.minewscanner.ui.theme.BorderStroke
import com.openbeacon.minewscanner.ui.theme.CyanNeon
import com.openbeacon.minewscanner.ui.theme.EmeraldGlow
import com.openbeacon.minewscanner.ui.theme.EmeraldGreen
import com.openbeacon.minewscanner.ui.theme.PurpleAccent
import com.openbeacon.minewscanner.ui.theme.RoseHot
import com.openbeacon.minewscanner.ui.theme.SignalExcellent
import com.openbeacon.minewscanner.ui.theme.SignalFair
import com.openbeacon.minewscanner.ui.theme.SignalGood
import com.openbeacon.minewscanner.ui.theme.SignalWeak
import com.openbeacon.minewscanner.ui.theme.SurfaceCard
import com.openbeacon.minewscanner.ui.theme.SurfaceCardElevated
import com.openbeacon.minewscanner.ui.theme.TextMuted
import com.openbeacon.minewscanner.ui.theme.TextPrimary
import com.openbeacon.minewscanner.ui.theme.TextSecondary
import java.util.Locale

@Composable
fun BeaconCard(
    device: BeaconDevice,
    onCardClick: () -> Unit,
    onToggleFavorite: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val isMinew = device.isMinewS1
    val ht = device.minewHtData
    val ibeacon = device.iBeaconData

    val cardBorderColor = when {
        device.isFavorite -> AmberWarm.copy(alpha = 0.7f)
        isMinew -> CyanNeon.copy(alpha = 0.5f)
        else -> BorderStroke
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .border(1.5.dp, cardBorderColor, RoundedCornerShape(16.dp))
            .clickable { onCardClick() },
        colors = CardDefaults.cardColors(containerColor = SurfaceCard),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header: Name, MAC address, Favorite, Minew badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Device Icon / Status Dot
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(
                            if (isMinew) CyanNeon.copy(alpha = 0.15f)
                            else SurfaceCardElevated
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (ht != null) Icons.Default.Thermostat else Icons.Default.Wifi,
                        contentDescription = null,
                        tint = if (isMinew) CyanNeon else TextSecondary,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = device.displayName,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        if (isMinew) {
                            Surface(
                                shape = RoundedCornerShape(4.dp),
                                color = CyanNeon.copy(alpha = 0.2f),
                                border = androidx.compose.foundation.BorderStroke(1.dp, CyanNeon.copy(alpha = 0.4f))
                            ) {
                                Text(
                                    text = "Minew S1",
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = CyanNeon,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(2.dp))

                    // MAC Address with Copy button
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.clickable {
                            copyToClipboard(context, "MAC Address", device.macAddress)
                        }
                    ) {
                        Text(
                            text = device.macAddress,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 12.sp,
                            color = TextSecondary
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(
                            imageVector = Icons.Default.ContentCopy,
                            contentDescription = "Copy MAC",
                            tint = TextMuted,
                            modifier = Modifier.size(12.dp)
                        )
                    }
                }

                // Favorite Star
                IconButton(
                    onClick = onToggleFavorite,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = if (device.isFavorite) Icons.Default.Star else Icons.Default.StarBorder,
                        contentDescription = "Favorite",
                        tint = if (device.isFavorite) AmberWarm else TextMuted
                    )
                }
            }

            // SENSOR TELEMETRY ROW (Temperature, Humidity, Battery)
            if (ht != null) {
                Spacer(modifier = Modifier.height(14.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Temperature Tile
                    val tempColor = getTemperatureColor(ht.temperature)
                    MetricPill(
                        icon = Icons.Default.Thermostat,
                        label = "Температура",
                        value = "${String.format(Locale.US, "%.1f", ht.temperature)} °C",
                        color = tempColor,
                        modifier = Modifier.weight(1f)
                    )

                    // Humidity Tile
                    MetricPill(
                        icon = Icons.Default.WaterDrop,
                        label = "Влажность",
                        value = "${String.format(Locale.US, "%.1f", ht.humidity)} %",
                        color = CyanNeon,
                        modifier = Modifier.weight(1f)
                    )

                    // Battery Tile
                    MetricPill(
                        icon = Icons.Default.BatteryFull,
                        label = "Батарея",
                        value = "${ht.batteryPercentage}%",
                        color = getBatteryColor(ht.batteryPercentage),
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // iBeacon Details Row (if present)
            if (ibeacon != null) {
                Spacer(modifier = Modifier.height(10.dp))
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = SurfaceCardElevated,
                    border = androidx.compose.foundation.BorderStroke(1.dp, BorderStroke)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "iBeacon",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = PurpleAccent
                            )
                            Text(
                                text = "Major: ${ibeacon.major}  |  Minor: ${ibeacon.minor}",
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = TextSecondary
                            )
                        }

                        val distance = ibeacon.calculateDistance(device.rssi)
                        Text(
                            text = if (distance > 0) "Дистанция: ~${String.format(Locale.US, "%.1f", distance)} м" else "Tx: ${ibeacon.txPower} dBm",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Footer: Signal RSSI, packet count, and timestamp
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Signal RSSI meter
                Row(verticalAlignment = Alignment.CenterVertically) {
                    RssiBars(rssi = device.rssi)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "${device.rssi} dBm",
                        fontSize = 12.sp,
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.Medium,
                        color = getRssiColor(device.rssi)
                    )
                }

                // Packet count & Time
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Пакетов: ${device.packetCount}",
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = formatTimeAgo(device.lastSeenTimestamp),
                        fontSize = 11.sp,
                        color = TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
fun MetricPill(
    icon: ImageVector,
    label: String,
    value: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(10.dp),
        color = color.copy(alpha = 0.08f),
        border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.25f))
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(3.dp))
                Text(
                    text = label,
                    fontSize = 10.sp,
                    color = TextSecondary
                )
            }
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text = value,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

@Composable
fun RssiBars(rssi: Int, modifier: Modifier = Modifier) {
    val level = when {
        rssi >= -60 -> 4
        rssi >= -75 -> 3
        rssi >= -85 -> 2
        else -> 1
    }
    val activeColor = getRssiColor(rssi)

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        for (i in 1..4) {
            val barHeight = (4 + (i * 3)).dp
            val isFilled = i <= level
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .height(barHeight)
                    .clip(RoundedCornerShape(1.dp))
                    .background(if (isFilled) activeColor else TextMuted.copy(alpha = 0.3f))
            )
        }
    }
}

fun getTemperatureColor(temp: Float): Color {
    return when {
        temp < 18.0f -> CyanNeon
        temp in 18.0f..25.5f -> EmeraldGreen
        temp in 25.5f..30.0f -> AmberWarm
        else -> RoseHot
    }
}

fun getBatteryColor(battery: Int): Color {
    return when {
        battery >= 60 -> EmeraldGreen
        battery >= 25 -> AmberWarm
        else -> RoseHot
    }
}

fun getRssiColor(rssi: Int): Color {
    return when {
        rssi >= -65 -> SignalExcellent
        rssi >= -78 -> SignalGood
        rssi >= -88 -> SignalFair
        else -> SignalWeak
    }
}

fun formatTimeAgo(timestamp: Long): String {
    val diffSec = (System.currentTimeMillis() - timestamp) / 1000
    return when {
        diffSec < 2 -> "сейчас"
        diffSec < 60 -> "${diffSec} сек назад"
        diffSec < 3600 -> "${diffSec / 60} мин назад"
        else -> "${diffSec / 3600} ч назад"
    }
}

fun copyToClipboard(context: Context, label: String, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
    clipboard?.setPrimaryClip(ClipData.newPlainText(label, text))
    Toast.makeText(context, "Скопировано: $text", Toast.LENGTH_SHORT).show()
}
