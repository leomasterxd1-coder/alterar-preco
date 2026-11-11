package br.com.americanas.alterarpreco.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.americanas.alterarpreco.Produto
import br.com.americanas.alterarpreco.network.HydraClient
import br.com.americanas.alterarpreco.ui.AppColors
import br.com.americanas.alterarpreco.ui.CheckBoxCyan
import br.com.americanas.alterarpreco.ui.UnderlineField
import kotlinx.coroutines.launch

@Composable
fun PriceListScreen(
    client: HydraClient,
    onVoltarLogin: () -> Unit,
    onSelecionados: (List<Produto>) -> Unit,
) {
    var produtos by remember { mutableStateOf<List<Produto>>(emptyList()) }
    var carregando by remember { mutableStateOf(true) }
    var preparando by remember { mutableStateOf(false) }
    var erro by remember { mutableStateOf<String?>(null) }
    var busca by remember { mutableStateOf("") }
    var departamento by remember { mutableStateOf<String?>(null) }
    var menuDepto by remember { mutableStateOf(false) }
    var selecionados by remember { mutableStateOf<Set<String>>(emptySet()) }
    val scope = rememberCoroutineScope()

    fun carregar() {
        carregando = true
        erro = null
        scope.launch {
            client.listarProdutos()
                .onSuccess { produtos = it; selecionados = emptySet() }
                .onFailure { erro = it.message ?: "Falha ao carregar preços." }
            carregando = false
        }
    }

    LaunchedEffect(Unit) { carregar() }

    val filtrados = remember(produtos, busca, departamento) {
        val q = busca.trim().lowercase()
        produtos.filter { p ->
            val casaBusca = q.isBlank() ||
                p.descricao.lowercase().contains(q) ||
                p.codigoSap.lowercase().contains(q) ||
                p.eans.any { it.lowercase().contains(q) }
            val casaDepto = departamento == null || p.departamento == departamento
            casaBusca && casaDepto
        }
    }
    val todosFiltradosMarcados = filtrados.isNotEmpty() && filtrados.all { it.id in selecionados }

    Column(
        Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Text(
            "Administrar Preços da loja 291",
            color = AppColors.Red,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 18.dp, bottom = 6.dp),
        )

        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.Bottom,
        ) {
            Row(Modifier.weight(1.08f), verticalAlignment = Alignment.Bottom) {
                UnderlineField(
                    value = busca,
                    onValueChange = { busca = it },
                    placeholder = "7894900011609",
                    modifier = Modifier.weight(1f),
                    textSize = 15,
                )
                Icon(
                    Icons.Filled.Search,
                    contentDescription = "Buscar",
                    tint = Color(0xFFBDBDBD),
                    modifier = Modifier.padding(start = 8.dp, bottom = 12.dp).size(26.dp),
                )
            }
            Spacer(Modifier.width(18.dp))
            Column(Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth().clickable { menuDepto = true }.padding(vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        departamento?.let { it.substringBefore(" - ").trim() + " - Departamento" }
                            ?: "Todos os departamentos",
                        color = AppColors.TextDark,
                        fontSize = 14.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    Icon(Icons.Filled.ArrowDropDown, contentDescription = null, tint = AppColors.Cyan)
                    DropdownMenu(expanded = menuDepto, onDismissRequest = { menuDepto = false }) {
                        DropdownMenuItem(
                            text = { Text("Todos os departamentos") },
                            onClick = { departamento = null; menuDepto = false },
                        )
                        produtos.map { it.departamento }.distinct().sorted().forEach { depto ->
                            DropdownMenuItem(
                                text = { Text(depto, fontSize = 13.sp) },
                                onClick = { departamento = depto; menuDepto = false },
                            )
                        }
                    }
                }
                HorizontalDivider(color = AppColors.Cyan, thickness = 2.dp)
            }
        }

        when {
            carregando -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AppColors.Red)
            }

            erro != null && produtos.isEmpty() -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Erro ao carregar", fontWeight = FontWeight.Bold)
                    Text(erro.orEmpty(), color = AppColors.TextMuted, fontSize = 12.sp)
                    TextButton(onClick = { carregar() }) { Text("Tentar novamente") }
                }
            }

            else -> {
                HeaderTabela(
                    todosMarcados = todosFiltradosMarcados,
                    onToggleTodos = {
                        selecionados = if (todosFiltradosMarcados) {
                            selecionados - filtrados.map { it.id }.toSet()
                        } else {
                            selecionados + filtrados.map { it.id }
                        }
                    },
                )

                Row(
                    Modifier.fillMaxWidth().background(Color.White).padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Button(
                        onClick = {
                            val escolhidos = produtos.filter { it.id in selecionados }
                            if (escolhidos.isEmpty()) return@Button
                            preparando = true
                            erro = null
                            scope.launch {
                                client.prepararEdicao(escolhidos.map { it.id })
                                    .onSuccess { onSelecionados(escolhidos) }
                                    .onFailure { erro = it.message ?: "Falha ao preparar edição." }
                                preparando = false
                            }
                        },
                        enabled = selecionados.isNotEmpty() && !preparando,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AppColors.Cyan,
                            disabledContainerColor = AppColors.Cyan.copy(alpha = 0.45f),
                        ),
                        shape = RoundedCornerShape(2.dp),
                    ) {
                        Text("Confirmar Seleção", color = Color.White, fontSize = 13.sp)
                        Spacer(Modifier.width(10.dp))
                        Icon(Icons.Filled.ArrowForward, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                    }
                }
                if (erro != null) {
                    Text(
                        erro.orEmpty(),
                        color = AppColors.Red,
                        fontSize = 12.sp,
                        modifier = Modifier.fillMaxWidth().background(Color.White).padding(horizontal = 16.dp, vertical = 4.dp),
                    )
                }

                if (filtrados.isEmpty()) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("Nenhum produto encontrado.", color = AppColors.TextMuted)
                    }
                } else {
                    LazyColumn(Modifier.fillMaxSize().background(Color.White)) {
                        items(filtrados, key = { it.id }) { produto ->
                            LinhaProduto(
                                produto = produto,
                                marcado = produto.id in selecionados,
                                onToggle = {
                                    selecionados = if (produto.id in selecionados) {
                                        selecionados - produto.id
                                    } else {
                                        selecionados + produto.id
                                    }
                                },
                            )
                            HorizontalDivider(color = AppColors.Divider, thickness = 1.dp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HeaderTabela(todosMarcados: Boolean, onToggleTodos: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppColors.HeaderGray).padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.width(40.dp), contentAlignment = Alignment.Center) {
            CheckBoxCyan(todosMarcados, { onToggleTodos() }, Modifier.size(28.dp))
        }
        CelulaHeader("Descrição", 2.1f)
        CelulaHeader("Código SAP", 1.15f)
        CelulaHeader("EANs", 1.15f)
        CelulaHeader("Departamento", 1.75f)
        CelulaHeader("Preço", 0.85f)
    }
}

@Composable
private fun RowScope.CelulaHeader(text: String, weight: Float) {
    Text(
        text,
        color = Color.White,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        maxLines = 1,
        modifier = Modifier.weight(weight).padding(horizontal = 4.dp),
    )
}

@Composable
private fun LinhaProduto(produto: Produto, marcado: Boolean, onToggle: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onToggle() }.padding(vertical = 12.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Box(Modifier.width(40.dp), contentAlignment = Alignment.TopCenter) {
            CheckBoxCyan(marcado, { onToggle() }, Modifier.size(28.dp))
        }
        CelulaCorpo(produto.descricao, 2.1f, FontWeight.Bold)
        CelulaCorpo(produto.codigoSap, 1.15f)
        CelulaCorpo(produto.eansTexto, 1.15f)
        CelulaCorpo(produto.departamento, 1.75f)
        CelulaCorpo(produto.precoFormatado, 0.85f)
    }
}

@Composable
private fun RowScope.CelulaCorpo(text: String, weight: Float, weightFont: FontWeight = FontWeight.Normal) {
    Text(
        text,
        color = AppColors.TextMuted,
        fontSize = 11.sp,
        lineHeight = 15.sp,
        fontWeight = weightFont,
        modifier = Modifier.weight(weight).padding(horizontal = 4.dp),
    )
}
