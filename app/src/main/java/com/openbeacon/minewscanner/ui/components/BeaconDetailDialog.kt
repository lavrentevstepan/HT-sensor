package com.openbeacon.minewscanner.ui.components

import android.content.Context
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.openbeacon.minewscanner.data.model.BeaconDevice
import com.openbeacon.minewscanner.data.model.SensorDataPoint
import com.openbeacon.minewscanner.ui.theme.AmberWarm
import com.openbeacon.minewscanner.ui.theme.BgDark
import com.openbeacon.minewscanner.ui.theme.BorderStroke
import com.openbeacon.minewscanner.ui.theme.CyanNeon
import com.openbeacon.minewscanner.ui.theme.EmeraldGreen
import com.openbeacon.minewscanner.ui.theme.PurpleAccent
import com.openbeacon.minewscanner.ui.theme.SurfaceCard
import com.openbeacon.minewscanner.ui.theme.SurfaceCardElevated
import com.openbeacon.minewscanner.ui.theme.TextMuted
import com.openbeacon.minewscanner.ui.theme.TextPrimary
import com.openbeacon.minewscanner.ui.theme.TextSecondary
import java.util.Locale

@Composable
fun BeaconDetailDialog(
    device: BeaconDevice,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val ht = device.minewHtData
    val ibeacon = device.iBeaconData

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.95f)
                .clip(RoundedCornerShape(24.dp))
                .border(1.5.dp, BorderStroke, RoundedCornerShape(24.dp)),
            color = BgDark
        ) {
            Column(
                modifier = Modifier
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                // Top Header Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = device.displayName,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.clickable {
                                copyToClipboard(context, "MAC Address", device.macAddress)
                            }
                        ) {
                            Text(
                                text = device.macAddress,
                                fontFamily = FontFamily.Monospace,
                                fontSize = 13.sp,
                                color = CyanNeon
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = "Copy MAC",
                                tint = TextSecondary,
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }

                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close",
                            tint = TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // SECTION 1: Minew S1 HT Telemetry
                if (ht != null) {
                    SectionCard(title = "Телеметрия Minew S1 (HT Sensor)", accentColor = CyanNeon) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            MetricPill(
                                icon = Icons.Default.Thermostat,
                                label = "Температура",
                                value = "${String.format(Locale.US, "%.1f", ht.temperature)} °C",
                                color = getTemperatureColor(ht.temperature),
                                modifier = Modifier.weight(1f)
                            )
                            MetricPill(
                                icon = Icons.Default.WaterDrop,
                                label = "Влажность",
                                value = "${String.format(Locale.US, "%.1f", ht.humidity)} %",
                                color = CyanNeon,
                                modifier = Modifier.weight(1f)
                            )
                            MetricPill(
                                icon = Icons.Default.Info,
                                label = "Батарея",
                                value = "${ht.batteryPercentage}%",
                                color = getBatteryColor(ht.batteryPercentage),
                                modifier = Modifier.weight(1f)
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Hardware MAC in frame
                        ParamRow("MAC в пакете S1", ht.macInFrame)
                        ParamRow("Версия кадра", "0x${String.format("%02X", ht.frameVersion)} (HT Sensor)")
                        ParamRow("Тип кадра", "0xA1 (BeaconPlus Sensor)")

                        // Live Sensor Chart (if points exist)
                        if (device.history.size >= 2) {
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "График изменения температуры (°C)",
                                fontSize = 11.sp,
                                color = TextSecondary,
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            SensorHistoryChart(
                                points = device.history.map { it.temperature },
                                lineColor = EmeraldGreen,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(70.dp)
                            )

                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "График влажности (%)",
                                fontSize = 11.sp,
                                color = TextSecondary,
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            SensorHistoryChart(
                                points = device.history.map { it.humidity },
                                lineColor = CyanNeon,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(70.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }

                // SECTION 2: iBeacon Telemetry
                if (ibeacon != null) {
                    SectionCard(title = "Пакет iBeacon (Apple Profile)", accentColor = PurpleAccent) {
                        ParamRow("UUID", ibeacon.uuid, onCopy = {
                            copyToClipboard(context, "iBeacon UUID", ibeacon.uuid)
                        })
                        ParamRow("Major", "${ibeacon.major}")
                        ParamRow("Minor", "${ibeacon.minor}")
                        ParamRow("Tx Power (1м)", "${ibeacon.txPower} dBm")

                        val dist = ibeacon.calculateDistance(device.rssi)
                        ParamRow("Примерная дистанция", if (dist > 0) "~${String.format(Locale.US, "%.2f", dist)} м" else "Неизвестно")
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }

                // SECTION 3: Signal & Stats
                SectionCard(title = "Статистика BLE сигнала", accentColor = AmberWarm) {
                    ParamRow("Уровень RSSI", "${device.rssi} dBm")
                    ParamRow("Всего пакетов принято", "${device.packetCount}")
                    ParamRow("Последнее обновление", formatTimeAgo(device.lastSeenTimestamp))
                    ParamRow("Имя устройства BLE", device.name)
                }

                Spacer(modifier = Modifier.height(16.dp))

                // SECTION 4: Raw Hex Packet Inspector
                SectionCard(title = "RAW инспектор пакетов", accentColor = TextMuted) {
                    if (device.rawScanRecordHex.isNotBlank()) {
                        Text(
                            text = "Полный скан-пакет (Hex):",
                            fontSize = 11.sp,
                            color = TextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        HexBox(
                            hex = device.rawScanRecordHex,
                            onCopy = { copyToClipboard(context, "Raw Scan Hex", device.rawScanRecordHex) }
                        )
                    }

                    if (device.rawServiceDataHex.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Text(
                            text = "Данные сервисов (Service Data):",
                            fontSize = 11.sp,
                            color = TextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                        device.rawServiceDataHex.forEach { (uuid, hex) ->
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "UUID: $uuid",
                                fontSize = 10.sp,
                                fontFamily = FontFamily.Monospace,
                                color = CyanNeon
                            )
                            HexBox(hex = hex, onCopy = { copyToClipboard(context, "Service Data Hex", hex) })
                        }
                    }

                    if (device.rawManufacturerDataHex.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Text(
                            text = "Manufacturer Data:",
                            fontSize = 11.sp,
                            color = TextSecondary,
                            fontWeight = FontWeight.Medium
                        )
                        device.rawManufacturerDataHex.forEach { (companyId, hex) ->
                            Spacer(modifier = Modifier.height(4.dp))
                            val companyName = if (companyId == 0x004C) "Apple Inc (iBeacon)" else "ID: 0x${Integer.toHexString(companyId).uppercase()}"
                            Text(
                                text = companyName,
                                fontSize = 10.sp,
                                fontFamily = FontFamily.Monospace,
                                color = PurpleAccent
                            )
                            HexBox(hex = hex, onCopy = { copyToClipboard(context, "Manufacturer Hex", hex) })
                        }
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                Button(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = CyanNeon, contentColor = BgDark)
                ) {
                    Text(
                        text = "Закрыть",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
            }
        }
    }
}

@Composable
fun SectionCard(
    title: String,
    accentColor: Color,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceCard),
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderStroke)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(
                text = title,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = accentColor
            )
            Spacer(modifier = Modifier.height(10.dp))
            content()
        }
    }
}

@Composable
fun ParamRow(
    label: String,
    value: String,
    onCopy: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            fontSize = 12.sp,
            color = TextSecondary
        )
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = if (onCopy != null) Modifier.clickable { onCopy() } else Modifier
        ) {
            Text(
                text = value,
                fontSize = 12.sp,
                fontFamily = FontFamily.Monospace,
                fontWeight = FontWeight.Medium,
                color = TextPrimary
            )
            if (onCopy != null) {
                Spacer(modifier = Modifier.width(4.dp))
                Icon(
                    imageVector = Icons.Default.ContentCopy,
                    contentDescription = "Copy",
                    tint = TextMuted,
                    modifier = Modifier.size(12.dp)
                )
            }
        }
    }
}

@Composable
fun HexBox(hex: String, onCopy: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = SurfaceCardElevated,
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderStroke),
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCopy() }
    ) {
        Row(
            modifier = Modifier.padding(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = hex,
                fontFamily = FontFamily.Monospace,
                fontSize = 11.sp,
                color = TextSecondary,
                modifier = Modifier.weight(1f)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Icon(
                imageVector = Icons.Default.ContentCopy,
                contentDescription = "Copy Hex",
                tint = TextMuted,
                modifier = Modifier.size(14.dp)
            )
        }
    }
}

@Composable
fun SensorHistoryChart(
    points: List<Float>,
    lineColor: Color,
    modifier: Modifier = Modifier
) {
    if (points.size < 2) return

    val minVal = points.minOrNull() ?: 0f
    val maxVal = points.maxOrNull() ?: 1f
    val range = if (maxVal - minVal > 0.01f) maxVal - minVal else 1f

    Surface(
        shape = RoundedCornerShape(8.dp),
        color = SurfaceCardElevated,
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderStroke),
        modifier = modifier
    ) {
        Canvas(
            modifier = Modifier
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .fillMaxWidth()
                .height(60.dp)
        ) {
            val w = size.width
            val h = size.height

            val path = Path()
            val stepX = w / (points.size - 1)

            points.forEachIndexed { i, value ->
                val x = i * stepX
                val normalizedY = (value - minVal) / range
                val y = h - (normalizedY * h)

                if (i == 0) {
                    path.moveTo(x, y)
                } else {
                    path.lineTo(x, y)
                }

                // Draw point dot
                drawCircle(
                    color = lineColor,
                    radius = 3.dp.toPx(),
                    center = Offset(x, y)
                )
            }

            drawPath(
                path = path,
                color = lineColor,
                style = Stroke(width = 2.dp.toPx())
            )
        }
    }
}
