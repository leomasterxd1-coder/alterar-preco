package br.com.americanas.alterarpreco.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun UnderlineField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
    keyboardType: KeyboardType = KeyboardType.Text,
    password: Boolean = false,
    textSize: Int = 15,
) {
    Column(modifier) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            textStyle = TextStyle(fontSize = textSize.sp, color = AppColors.TextDark),
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            visualTransformation = if (password) PasswordVisualTransformation() else VisualTransformation.None,
            cursorBrush = SolidColor(AppColors.Red),
            decorationBox = { inner ->
                androidx.compose.foundation.layout.Box(
                    Modifier.fillMaxWidth().padding(vertical = 10.dp)
                ) {
                    if (value.isEmpty()) {
                        Text(placeholder, color = AppColors.TextMuted, fontSize = textSize.sp)
                    }
                    inner()
                }
            }
        )
        HorizontalDivider(color = AppColors.Divider, thickness = 1.dp)
    }
}

@Composable
fun CheckBoxCyan(
    checked: Boolean,
    onCheckedChange: ((Boolean) -> Unit)?,
    modifier: Modifier = Modifier,
) {
    Checkbox(
        checked = checked,
        onCheckedChange = onCheckedChange,
        modifier = modifier,
        colors = CheckboxDefaults.colors(
            checkedColor = AppColors.Cyan,
            uncheckedColor = AppColors.Cyan,
            checkmarkColor = androidx.compose.ui.graphics.Color.White,
        ),
    )
}

@Composable
fun InfoBlock(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
) {
    Column(modifier) {
        Text(label, color = AppColors.TextMuted, fontSize = 12.sp)
        Spacer(Modifier.height(3.dp))
        Text(value.ifBlank { "-" }, color = AppColors.TextMuted, fontSize = 13.sp, lineHeight = 17.sp)
    }
}

@Composable
fun InfoRow(vararg blocks: Pair<String, String>) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
        blocks.forEachIndexed { index, (label, value) ->
            InfoBlock(label, value, Modifier.weight(1f))
            if (index < blocks.lastIndex) Spacer(Modifier.width(12.dp))
        }
    }
}
