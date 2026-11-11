package br.com.americanas.alterarpreco

data class Produto(
    val id: String,
    val descricao: String,
    val codigoSap: String,
    val eans: List<String>,
    val departamento: String,
    val precoAtual: Double,
    val precoAtualTexto: String,
) {
    val eansTexto: String get() = eans.joinToString("\n").ifBlank { "-" }
    val precoFormatado: String get() = precoAtualTexto.ifBlank { "R$ %.2f".format(precoAtual).replace('.', ',') }
}
