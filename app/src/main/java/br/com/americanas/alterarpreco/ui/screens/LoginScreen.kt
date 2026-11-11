package br.com.americanas.alterarpreco.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.americanas.alterarpreco.ui.AppColors
import br.com.americanas.alterarpreco.ui.UnderlineField
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    onEntrar: suspend (usuario: String, senha: String) -> Result<Unit>,
    onLogado: () -> Unit,
) {
    var usuario by remember { mutableStateOf("") }
    var senha by remember { mutableStateOf("") }
    var carregando by remember { mutableStateOf(false) }
    var erro by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    fun entrar() {
        if (usuario.isBlank() || senha.isBlank() || carregando) return
        carregando = true
        erro = null
        scope.launch {
            onEntrar(usuario, senha)
                .onSuccess { onLogado() }
                .onFailure { erro = it.message ?: "Falha ao entrar." }
            carregando = false
        }
    }

    Box(Modifier.fillMaxSize().background(AppColors.Background)) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(290.dp)
                .background(AppColors.Red)
                .statusBarsPadding()
        ) {
            Text(
                "Bem Vindo ao sistema de\nRetaguarda de Loja",
                color = Color.White,
                fontSize = 29.sp,
                lineHeight = 35.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                modifier = Modifier.align(Alignment.Center).padding(horizontal = 24.dp),
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(start = 24.dp, end = 24.dp, top = 230.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Surface(
                color = Color.White,
                shape = RoundedCornerShape(1.dp),
                shadowElevation = 3.dp,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    HorizontalDivider(color = AppColors.Red, thickness = 3.dp)
                    Text(
                        "LOJAS AMERICANAS",
                        color = AppColors.Red,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Black,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(vertical = 6.dp),
                    )
                    HorizontalDivider(color = AppColors.Red, thickness = 3.dp)
                }
            }

            Spacer(Modifier.height(18.dp))

            Surface(
                color = Color.White,
                shape = RoundedCornerShape(1.dp),
                shadowElevation = 3.dp,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(Modifier.padding(horizontal = 24.dp, vertical = 40.dp)) {
                    UnderlineField(
                        value = usuario,
                        onValueChange = { usuario = it },
                        placeholder = "Digite seu Prontuário",
                        keyboardType = KeyboardType.Number,
                        textSize = 16,
                    )
                    Spacer(Modifier.height(26.dp))
                    UnderlineField(
                        value = senha,
                        onValueChange = { senha = it },
                        placeholder = "Digite sua Senha",
                        password = true,
                        textSize = 16,
                    )
                    Spacer(Modifier.height(52.dp))
                    Button(
                        onClick = { entrar() },
                        enabled = !carregando,
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(1.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Red),
                    ) {
                        if (carregando) {
                            CircularProgressIndicator(
                                color = Color.White,
                                strokeWidth = 2.dp,
                                modifier = Modifier.height(22.dp).padding(horizontal = 2.dp),
                            )
                        } else {
                            Text("Entrar", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    if (erro != null) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            erro.orEmpty(),
                            color = AppColors.Red,
                            fontSize = 13.sp,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                }
            }
        }
    }
}
