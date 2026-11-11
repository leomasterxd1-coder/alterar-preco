class Produto {
  final String id;
  final String descricao;
  final String codigoSap;
  final List<String> eans;
  final String departamento;
  final double precoAtual;
  final String precoAtualTexto;

  const Produto({
    required this.id,
    required this.descricao,
    required this.codigoSap,
    required this.eans,
    required this.departamento,
    required this.precoAtual,
    required this.precoAtualTexto,
  });

  String get eansTexto => eans.isEmpty ? '-' : eans.join('\n');

  String get precoFormatado {
    if (precoAtualTexto.trim().isNotEmpty) return precoAtualTexto;
    return 'R\$ ${precoAtual.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class AlteracaoPreco {
  final String id;
  final String preco;
  final String justificativa;
  final bool clienteA;

  const AlteracaoPreco({
    required this.id,
    required this.preco,
    required this.justificativa,
    required this.clienteA,
  });
}
