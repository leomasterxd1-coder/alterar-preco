package br.com.americanas.alterarpreco

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import br.com.americanas.alterarpreco.ui.AlterarPrecoTheme
import br.com.americanas.alterarpreco.ui.App

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AlterarPrecoTheme {
                App()
            }
        }
    }
}
