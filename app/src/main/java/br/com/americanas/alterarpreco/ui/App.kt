package br.com.americanas.alterarpreco.ui

import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import androidx.compose.runtime.setValue
import br.com.americanas.alterarpreco.Produto
import br.com.americanas.alterarpreco.network.HydraClient
import br.com.americanas.alterarpreco.ui.screens.EditPriceScreen
import br.com.americanas.alterarpreco.ui.screens.LoginScreen
import br.com.americanas.alterarpreco.ui.screens.PriceListScreen
import br.com.americanas.alterarpreco.ui.screens.ScannerScreen
import br.com.americanas.alterarpreco.ui.screens.SelectedItemsScreen

private sealed interface Tela {
    data object Login : Tela
    data object Lista : Tela
    data object Scanner : Tela
    data class Selecionados(val itens: List<Produto>) : Tela
    data class Edicao(val itens: List<Produto>) : Tela
}

@Composable
fun App() {
    val client = remember { HydraClient() }
    var tela by remember { mutableStateOf<Tela>(Tela.Login) }
    var eanPendente by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    BackHandler(enabled = tela != Tela.Login) {
        when (tela) {
            is Tela.Edicao -> tela = Tela.Selecionados((tela as Tela.Edicao).itens)
            is Tela.Selecionados -> tela = Tela.Lista
            else -> tela = Tela.Lista
        }
    }

    when (val atual = tela) {
        Tela.Login -> LoginScreen(
            onEntrar = { usuario, senha -> client.login(usuario, senha) },
            onLogado = { tela = Tela.Lista },
        )

        Tela.Lista -> PriceListScreen(
            client = client,
            eanInicial = eanPendente,
            onEanConsumido = { eanPendente = null },
            onScanner = { tela = Tela.Scanner },
            onVoltarLogin = {
                scope.launch { client.logout() }
                tela = Tela.Login
            },
            onSelecionados = { tela = Tela.Selecionados(it) },
        )

        Tela.Scanner -> ScannerScreen(
            onVoltar = { tela = Tela.Lista },
            onResult = { ean ->
                eanPendente = ean
                tela = Tela.Lista
            },
        )

        is Tela.Selecionados -> SelectedItemsScreen(
            itens = atual.itens,
            onDeselecionarTodos = { tela = Tela.Lista },
            onEditar = { tela = Tela.Edicao(it) },
        )

        is Tela.Edicao -> EditPriceScreen(
            itens = atual.itens,
            onCancelar = { tela = Tela.Selecionados(atual.itens) },
            onSalvar = { alteracoes -> client.salvarPrecos(alteracoes) },
            onSalvo = { tela = Tela.Lista },
        )
    }
}
