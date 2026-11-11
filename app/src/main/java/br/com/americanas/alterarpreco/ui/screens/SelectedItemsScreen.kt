package br.com.americanas.alterarpreco.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.americanas.alterarpreco.Produto
import br.com.americanas.alterarpreco.ui.AppColors
import br.com.americanas.alterarpreco.ui.CheckBoxCyan

@Composable
fun SelectedItemsScreen(
    itens: List<Produto>,
    onDeselecionarTodos: () -> Unit,
    onEditar: (List<Produto>) -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Row(
            Modifier.fillMaxWidth().background(AppColors.HeaderGray).padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "%02d".format(itens.size),
                color = Color.White.copy(alpha = 0.72f),
                fontSize = 20.sp,
                fontStyle = FontStyle.Italic,
                fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.width(8.dp))
            Text("Selecionados", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        }

        Row(
            Modifier.fillMaxWidth().background(Color.White).padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            OutlinedButton(
                onClick = onDeselecionarTodos,
                shape = RoundedCornerShape(1.dp),
                border = BorderStroke(1.dp, AppColors.Cyan),
                modifier = Modifier.height(40.dp),
            ) {
                Text("Deselecionar todos", color = AppColors.Cyan, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.weight(1f))
            Surface(
                color = AppColors.Red,
                shape = CircleShape,
                shadowElevation = 2.dp,
                modifier = Modifier.size(50.dp).clickable { onEditar(itens) },
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Edit, contentDescription = "Editar preços", tint = Color.White, modifier = Modifier.size(22.dp))
                }
            }
        }

        LazyColumn(Modifier.fillMaxSize().background(Color.White)) {
            items(itens, key = { it.id }) { produto ->
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    CheckBoxCyan(true, null, Modifier.size(26.dp))
                    Spacer(Modifier.width(14.dp))
                    Text(
                        produto.descricao,
                        color = AppColors.TextMuted,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f),
                    )
                    Text(produto.codigoSap, color = AppColors.TextMuted, fontSize = 13.sp)
                }
                HorizontalDivider(color = AppColors.Divider, thickness = 1.dp)
            }
        }
    }
}
