package br.com.americanas.alterarpreco.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object AppColors {
    val Red = Color(0xFFB01C1C)
    val RedDark = Color(0xFF8F1515)
    val HeaderGray = Color(0xFF7C878A)
    val Cyan = Color(0xFF5FC5D6)
    val CyanDark = Color(0xFF2E9FB3)
    val Background = Color(0xFFF0F0F0)
    val TextDark = Color(0xFF333333)
    val TextMuted = Color(0xFF8A8A8A)
    val Divider = Color(0xFFE0E0E0)
    val Gold = Color(0xFFB68A2E)
}

private val colors = lightColorScheme(
    primary = AppColors.Red,
    onPrimary = Color.White,
    secondary = AppColors.Cyan,
    background = AppColors.Background,
    surface = Color.White,
    onSurface = AppColors.TextDark,
)

@Composable
fun AlterarPrecoTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, typography = Typography(), content = content)
}
