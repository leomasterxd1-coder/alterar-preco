import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class HydraApi {
  HydraApi._() {
    _dio.interceptors.add(CookieManager(CookieJar()));
  }

  static final HydraApi instance = HydraApi._();
  static const String base = 'https://hydra-retaguarda.americanas.io';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      followRedirects: true,
    ),
  );

  Future<void> login(String usuario, String senha) async {
    await _dio.get('/login/auth');
    final response = await _dio.post(
      '/login/authenticate',
      data: {'username': usuario.trim(), 'password': senha},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Origin': base, 'Referer': '$base/login/auth'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final texto = _asText(response.data);
    final status = response.statusCode ?? 0;
    if (status >= 400 ||
        texto.contains('Digite seu Prontuário') ||
        texto.contains('name="password"')) {
      throw ApiException('Prontuário ou senha inválidos.');
    }
  }

  Future<List<Produto>> listarProdutos() async {
    final response = await _dio.get(
      '/price/index',
      queryParameters: {'selectedStore': '291'},
      options: Options(headers: {'Referer': '$base/'}),
    );
    return _parseHtml(_asText(response.data));
  }

  Future<List<Produto>> buscar(String termo) async {
    final term = termo.trim();
    if (term.length < 2) return [];
    final response = await _dio.get(
      '/price/search',
      queryParameters: {
        'term': term,
        'excludedIds': '[]',
        'department': 'null',
        'selectedStore': '291',
      },
      options: Options(
        headers: {
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': '$base/price/index?selectedStore=291',
        },
      ),
    );
    return _parseBusca(response.data);
  }

  Future<void> prepararEdicao(List<String> ids) async {
    final response = await _dio.post(
      '/price/edit',
      data: {'productsToEdit': jsonEncode(ids), 'selectedStore': '291'},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Origin': base,
          'Referer': '$base/price/index?selectedStore=291',
        },
      ),
    );
    _validarResposta(response);
  }

  Future<void> salvarPrecos(List<AlteracaoPreco> alteracoes) async {
    final payload = alteracoes
        .map(
          (item) => {
            '_id': item.id,
            'price': item.preco.replaceAll(',', '.'),
            'reason': item.justificativa.trim(),
            'clienteAOffer': item.clienteA,
          },
        )
        .toList();
    final response = await _dio.post(
      '/price/update',
      data: {'products': jsonEncode(payload), 'selectedStore': '291'},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Origin': base, 'Referer': '$base/price/edit'},
      ),
    );
    _validarResposta(response);
  }

  Future<void> logout() async {
    try {
      await _dio.get('/logout/index', options: Options(headers: {'Referer': '$base/'}));
    } catch (_) {
      // Sessão local é descartada de qualquer forma.
    }
  }

  void _validarResposta(Response response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) throw ApiException('Falha na requisição ($status).');
  }

  String _asText(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  List<Produto> _parseBusca(dynamic data) {
    dynamic decoded = data;
    if (decoded is String) {
      final texto = decoded.trim();
      if (texto.startsWith('[') || texto.startsWith('{')) {
        try {
          decoded = jsonDecode(texto);
        } catch (_) {
          // Pode ser um fragmento HTML.
        }
      }
    }

    List<dynamic>? lista;
    if (decoded is List) {
      lista = decoded;
    } else if (decoded is Map<String, dynamic>) {
      for (final chave in ['items', 'data', 'products', 'results', 'content']) {
        final valor = decoded[chave];
        if (valor is List) {
          lista = valor;
          break;
        }
      }
    }

    if (lista != null) {
      final produtos = lista
          .whereType<Map>()
          .map((item) => _produtoDoMapa(Map<String, dynamic>.from(item)))
          .whereType<Produto>()
          .toList();
      if (produtos.isNotEmpty) return produtos;
    }

    if (data is String) return _parseHtml(data);
    return [];
  }

  Produto? _produtoDoMapa(Map<String, dynamic> map) {
    final id = _texto(map, ['_id', 'id', 'produtoId', 'codigo']);
    if (id.isEmpty) return null;
    final descricao = _texto(map, ['descricao', 'nome', 'description', 'produto']);
    if (descricao.isEmpty) return null;

    final eans = <String>[];
    for (final chave in ['eans', 'ean', 'codigoBarras', 'barcode', 'codigosBarras']) {
      final valor = map[chave];
      if (valor == null) continue;
      if (valor is List) {
        for (final item in valor) {
          if (item is String) {
            eans.add(item);
          } else if (item is Map) {
            final texto = _texto(Map<String, dynamic>.from(item), ['ean', 'codigo', 'codigoBarras', 'codigoBarra', 'value']);
            if (texto.isNotEmpty) eans.add(texto);
          }
        }
      } else if (valor is String) {
        eans.add(valor);
      }
      if (eans.isNotEmpty) break;
    }

    final eansLimpos = eans
        .expand((e) => e.split(RegExp(r'[,;\s]+')))
        .map((e) => e.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((e) => e.isNotEmpty)
        .toList();

    final precoBruto = map['preco'] ?? map['price'] ?? map['valor'] ?? map['precoVenda'];
    final preco = _preco(precoBruto);
    return Produto(
      id: id,
      descricao: descricao,
      codigoSap: _texto(map, ['codigoSap', 'sap', 'codigo']),
      eans: eansLimpos,
      departamento: _texto(map, ['departamento', 'department', 'descricaoDepartamento']),
      precoAtual: preco,
      precoAtualTexto: _moeda(preco),
    );
  }

  List<Produto> _parseHtml(String html) {
    final doc = html_parser.parse(html);
    final produtos = <Produto>[];
    for (final row in doc.querySelectorAll('tr')) {
      final checkbox = row.querySelector('input[type=checkbox]');
      if (checkbox == null) continue;
      final cells = row.querySelectorAll('td');
      if (cells.length < 5) continue;
      final textoTabela = row.text;
      if (textoTabela.contains('Descrição') && textoTabela.contains('Preço')) continue;

      final id = (checkbox.attributes['value'] ?? checkbox.attributes['data-id'] ?? '').trim();
      if (id.length <= 5) continue;

      final checkboxIndex = cells.indexWhere((cell) => cell.querySelector('input[type=checkbox]') != null);
      final inicio = checkboxIndex >= 0 ? checkboxIndex + 1 : 0;
      if (cells.length < inicio + 5) continue;

      final descricao = cells[inicio].text.trim();
      if (descricao.isEmpty) continue;
      final codigoSap = cells[inicio + 1].text.trim();
      final eans = cells[inicio + 2]
          .text
          .trim()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      final departamento = cells[inicio + 3].text.trim();
      final precoTexto = cells[inicio + 4].text.trim();
      final preco = _preco(precoTexto);

      produtos.add(
        Produto(
          id: id,
          descricao: descricao,
          codigoSap: codigoSap,
          eans: eans,
          departamento: departamento,
          precoAtual: preco,
          precoAtualTexto: precoTexto.isNotEmpty ? precoTexto : _moeda(preco),
        ),
      );
    }
    final vistos = <String>{};
    return produtos.where((p) => vistos.add(p.id)).toList();
  }

  String _texto(Map<String, dynamic> map, List<String> chaves) {
    for (final chave in chaves) {
      final valor = map[chave];
      if (valor == null) continue;
      final texto = valor.toString().trim();
      if (texto.isNotEmpty && texto != 'null') return texto;
    }
    return '';
  }

  double _preco(dynamic valor) {
    if (valor is num) return valor.toDouble();
    final texto = valor?.toString().replaceAll('R\$', '').trim() ?? '';
    if (texto.isEmpty) return 0;
    if (texto.contains(',')) {
      return double.tryParse(texto.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    }
    final direto = double.tryParse(texto);
    if (direto != null) return direto;
    final match = RegExp(r'([0-9]+(?:[.,][0-9]{2})?)').firstMatch(texto);
    return double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '') ?? 0;
  }

  String _moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}
