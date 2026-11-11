package br.com.americanas.alterarpreco.network

import br.com.americanas.alterarpreco.Produto
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.FormBody
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import org.jsoup.Jsoup
import java.util.concurrent.TimeUnit

class HydraClient {
    private val base = "https://hydra-retaguarda.americanas.io"
    private val gson = Gson()
    private val cookies = linkedMapOf<String, Cookie>()

    private val client = OkHttpClient.Builder()
        .connectTimeout(25, TimeUnit.SECONDS)
        .readTimeout(45, TimeUnit.SECONDS)
        .followRedirects(true)
        .cookieJar(object : CookieJar {
            override fun saveFromResponse(url: HttpUrl, list: List<Cookie>) {
                list.forEach { cookies[it.name] = it }
            }

            override fun loadForRequest(url: HttpUrl): List<Cookie> = cookies.values.toList()
        })
        .build()

    suspend fun login(usuario: String, senha: String): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val pre = Request.Builder().url("$base/login/auth").get().build()
            client.newCall(pre).execute().use { it.body?.string() }
            val form = FormBody.Builder()
                .add("username", usuario.trim())
                .add("password", senha)
                .build()
            val request = Request.Builder()
                .url("$base/login/authenticate")
                .post(form)
                .header("Origin", base)
                .header("Referer", "$base/login/auth")
                .build()
            client.newCall(request).execute().use { response ->
                val html = response.body?.string().orEmpty()
                val finalPath = response.request.url.encodedPath
                val stillLogin = finalPath.contains("/login") ||
                    html.contains("Digite seu Prontuário", ignoreCase = true) ||
                    html.contains("name=\"password\"", ignoreCase = true)
                if (!response.isSuccessful || stillLogin) {
                    error("Prontuário ou senha inválidos.")
                }
            }
        }
    }

    suspend fun listarProdutos(): Result<List<Produto>> = withContext(Dispatchers.IO) {
        runCatching {
            val request = Request.Builder()
                .url("$base/price/index?selectedStore=291")
                .get()
                .header("Referer", "$base/")
                .build()
            val html = executeText(request)
            parseProdutos(html)
        }
    }

    suspend fun prepararEdicao(ids: List<String>): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val form = FormBody.Builder()
                .add("productsToEdit", gson.toJson(ids))
                .add("selectedStore", "291")
                .build()
            val request = Request.Builder()
                .url("$base/price/edit")
                .post(form)
                .header("Origin", base)
                .header("Referer", "$base/price/index?selectedStore=291")
                .build()
            executeText(request)
            Unit
        }
    }

    suspend fun salvarPrecos(itens: List<AlteracaoPreco>): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val payload = itens.map {
                linkedMapOf(
                    "_id" to it.id,
                    "price" to it.preco.replace(',', '.'),
                    "reason" to it.justificativa.trim(),
                    "clienteAOffer" to it.clienteA,
                )
            }
            val form = FormBody.Builder()
                .add("products", gson.toJson(payload))
                .add("selectedStore", "291")
                .build()
            val request = Request.Builder()
                .url("$base/price/update")
                .post(form)
                .header("Origin", base)
                .header("Referer", "$base/price/edit")
                .build()
            executeText(request)
            Unit
        }
    }

    suspend fun logout(): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val request = Request.Builder()
                .url("$base/logout/index")
                .get()
                .header("Referer", "$base/")
                .build()
            executeText(request)
            cookies.clear()
        }
    }

    private fun executeText(request: Request): String {
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) error("Falha na requisição (${response.code}).")
            return response.body?.string().orEmpty()
        }
    }

    private fun parseProdutos(html: String): List<Produto> {
        val doc = Jsoup.parse(html)
        val result = mutableListOf<Produto>()
        doc.select("tr").forEach { row ->
            val checkbox = row.selectFirst("input[type=checkbox]") ?: return@forEach
            val cells = row.select("td")
            if (cells.size < 5) return@forEach
            if (row.text().contains("Descrição", ignoreCase = true) &&
                row.text().contains("Preço", ignoreCase = true)
            ) return@forEach

            val id = checkbox.attr("value").takeIf { it.length > 5 }
                ?: checkbox.attr("data-id").takeIf { it.isNotBlank() }
                ?: return@forEach
            val checkboxCell = cells.indexOfFirst { it.selectFirst("input[type=checkbox]") != null }
            val start = if (checkboxCell >= 0) checkboxCell + 1 else 0
            if (cells.size < start + 5) return@forEach

            val descricao = cells[start].text().trim()
            val codigoSap = cells[start + 1].text().trim()
            val eans = cells[start + 2].text()
                .split(Regex("\\s+"))
                .map { it.trim() }
                .filter { it.isNotBlank() }
            val departamento = cells[start + 3].text().trim()
            val precoTexto = cells[start + 4].text().trim()
            val preco = Regex("([0-9]+(?:[.,][0-9]{2})?)")
                .find(precoTexto.replace("R$", "").trim())
                ?.groupValues?.get(1)
                ?.replace(',', '.')
                ?.toDoubleOrNull() ?: 0.0

            if (descricao.isBlank()) return@forEach
            result += Produto(
                id = id,
                descricao = descricao,
                codigoSap = codigoSap,
                eans = eans,
                departamento = departamento,
                precoAtual = preco,
                precoAtualTexto = precoTexto,
            )
        }
        return result.distinctBy { it.id }
    }
}

data class AlteracaoPreco(
    val id: String,
    val preco: String,
    val justificativa: String,
    val clienteA: Boolean,
)
