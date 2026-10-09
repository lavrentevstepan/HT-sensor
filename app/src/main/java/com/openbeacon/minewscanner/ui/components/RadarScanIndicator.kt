package com.openbeacon.minewscanner.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.openbeacon.minewscanner.ui.theme.CyanNeon

@Composable
fun RadarScanIndicator(
    isScanning: Boolean,
    modifier: Modifier = Modifier,
    color: Color = CyanNeon
) {
    if (!isScanning) {
        Canvas(modifier = modifier.size(24.dp)) {
            drawCircle(
                color = color.copy(alpha = 0.4f),
                radius = size.minDimension / 2,
                style = Stroke(width = 2.dp.toPx())
            )
            drawCircle(
                color = color,
                radius = 4.dp.toPx()
            )
        }
        return
    }

    val transition = rememberInfiniteTransition(label = "radar_pulse")
    val radiusRatio by transition.animateFloat(
        initialValue = 0.2f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1600, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "radius"
    )
    val alpha by transition.animateFloat(
        initialValue = 0.8f,
        targetValue = 0.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1600, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "alpha"
    )

    Box(
        modifier = modifier.size(28.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.matchParentSize()) {
            val maxR = size.minDimension / 2
            // Expanding wave
            drawCircle(
                color = color.copy(alpha = alpha),
                radius = maxR * radiusRatio,
                style = Stroke(width = 2.dp.toPx())
            )
            // Center beacon core
            drawCircle(
                color = color,
                radius = 4.dp.toPx()
            )
        }
    }
}
