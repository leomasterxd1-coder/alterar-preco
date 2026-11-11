package br.com.americanas.alterarpreco.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.americanas.alterarpreco.Produto
import br.com.americanas.alterarpreco.network.AlteracaoPreco
import br.com.americanas.alterarpreco.ui.AppColors
import br.com.americanas.alterarpreco.ui.CheckBoxCyan
import br.com.americanas.alterarpreco.ui.InfoBlock
import br.com.americanas.alterarpreco.ui.InfoRow
import br.com.americanas.alterarpreco.ui.UnderlineField
import kotlinx.coroutines.launch

private data class EdicaoItem(
    val produto: Produto,
    val preco: String = "",
    val justificativa: String = "",
    val clienteA: Boolean = false,
)

@Composable
fun EditPriceScreen(
    itens: List<Produto>,
    onCancelar: () -> Unit,
    onSalvar: suspend (List<AlteracaoPreco>) -> Result<Unit>,
    onSalvo: () -> Unit,
) {
    val estados = remember(itens) {
        mutableStateListOf(*itens.map { EdicaoItem(it) }.toTypedArray())
    }
    var salvando by remember { mutableStateOf(false) }
    var erro by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    fun salvar() {
        if (salvando) return
        if (estados.isEmpty()) {
            erro = "Nenhum item selecionado."
            return
        }
        if (estados.any { it.preco.isBlank() || it.justificativa.isBlank() }) {
            erro = "Preencha o preço provisório e a justificativa de todos os itens."
            return
        }
        salvando = true
        erro = null
        scope.launch {
            val alteracoes = estados.map {
                AlteracaoPreco(
                    id = it.produto.id,
                    preco = it.preco,
                    justificativa = it.justificativa,
                    clienteA = it.clienteA,
                )
            }
            onSalvar(alteracoes)
                .onSuccess { onSalvo() }
                .onFailure { erro = it.message ?: "Falha ao salvar os preços." }
            salvando = false
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(Modifier.fillMaxWidth().background(Color.White).padding(16.dp)) {
            Text(
                "Edição de Preços da Loja 291",
                color = AppColors.Red,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "Os preços alterados permanecerão válidos só até 23:59h da Data de Início escolhida.",
                    color = AppColors.Gold,
                    fontSize = 12.sp,
                    lineHeight = 16.sp,
                    modifier = Modifier.weight(1f),
                )
                Spacer(Modifier.width(8.dp))
                OutlinedButton(
                    onClick = onCancelar,
                    border = BorderStroke(1.dp, AppColors.Red),
                    shape = RoundedCornerShape(1.dp),
                    enabled = !salvando,
                    modifier = Modifier.height(42.dp),
                ) {
                    Text("Cancelar", color = AppColors.Red, fontSize = 13.sp)
                }
                Spacer(Modifier.width(8.dp))
                Button(
                    onClick = { salvar() },
                    enabled = !salvando,
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Red),
                    shape = RoundedCornerShape(1.dp),
                    modifier = Modifier.height(42.dp).width(96.dp),
                ) {
                    if (salvando) {
                        CircularProgressIndicator(color = Color.White, strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
                    } else {
                        Text("Salvar", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
            if (erro != null) {
                Spacer(Modifier.height(10.dp))
                Text(erro.orEmpty(), color = AppColors.Red, fontSize = 12.sp)
            }
        }

        HorizontalDivider(color = Color(0xFFD9D9D9), thickness = 6.dp)

        LazyColumn(
            Modifier.fillMaxSize().background(Color(0xFFE3E3E3)),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            itemsIndexed(estados, key = { _, item -> item.produto.id }) { index, item ->
                Column(Modifier.fillMaxWidth().background(Color.White).padding(16.dp)) {
                    Row(verticalAlignment = Alignment.Top) {
                        Text(
                            item.produto.descricao,
                            color = AppColors.TextDark,
                            fontSize = 18.sp,
                            lineHeight = 23.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f),
                        )
                        IconButton(
                            onClick = { estados.removeAt(index) },
                            modifier = Modifier.size(36.dp),
                        ) {
                            Icon(
                                Icons.Filled.Delete,
                                contentDescription = "Remover item",
                                tint = AppColors.Cyan,
                                modifier = Modifier.size(24.dp),
                            )
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    InfoRow(
                        "Código" to item.produto.codigoSap,
                        "EAN" to item.produto.eansTexto.replace("\n", ", "),
                        "Departamento" to item.produto.departamento,
                    )
                    Spacer(Modifier.height(14.dp))
                    InfoBlock("Preço Atual", item.produto.precoFormatado, Modifier.fillMaxWidth(0.38f))
                    Spacer(Modifier.height(20.dp))
                    Text(
                        "Dados para Alteração de Preço",
                        color = AppColors.Red,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                    )
                    Spacer(Modifier.height(10.dp))
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                        UnderlineField(
                            value = item.preco,
                            onValueChange = { valor ->
                                estados[index] = estados[index].copy(
                                    preco = valor.filter { it.isDigit() || it == ',' || it == '.' }
                                )
                            },
                            placeholder = "Preço Provisório",
                            modifier = Modifier.weight(0.8f),
                            keyboardType = KeyboardType.Decimal,
                            textSize = 14,
                        )
                        Spacer(Modifier.width(18.dp))
                        UnderlineField(
                            value = item.justificativa,
                            onValueChange = { valor ->
                                estados[index] = estados[index].copy(justificativa = valor)
                            },
                            placeholder = "Justifique a Alteração",
                            modifier = Modifier.weight(1.4f),
                            textSize = 14,
                        )
                    }
                    Spacer(Modifier.height(18.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Exclusivo Cliente A", color = AppColors.TextMuted, fontSize = 13.sp)
                        Spacer(Modifier.width(8.dp))
                        CheckBoxCyan(
                            checked = item.clienteA,
                            onCheckedChange = { marcado ->
                                estados[index] = estados[index].copy(clienteA = marcado)
                            },
                            modifier = Modifier.size(26.dp),
                        )
                    }
                    Spacer(Modifier.height(4.dp))
                }
            }
        }
    }
}
