import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import 'barcode_scanner_screen.dart';
import 'selected_items_screen.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  static const _borda = Color(0xFFE0E4E6);
  static const _fundo = Color(0xFFF4F5F5);

  final _buscaController = TextEditingController();
  final _selecionados = <String>{};
  List<Produto> _produtos = [];
  bool _carregando = true;
  bool _preparando = false;
  bool _buscandoServidor = false;
  bool _saidaDialogAberta = false;
  String? _erro;
  String _departamento = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(_aoDigitar);
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _aoDigitar() {
    _debounce?.cancel();
    final termo = _buscaController.text.trim();
    setState(() {});
    if (termo.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _buscarNoServidor(termo);
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final produtos = await HydraApi.instance.listarProdutos();
      if (!mounted) return;
      final porId = <String, Produto>{for (final p in _produtos) p.id: p};
      for (final p in produtos) {
        porId[p.id] = p;
      }
      setState(() {
        _produtos = porId.values.toList();
        _selecionados.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _buscarNoServidor(String termo) async {
    if (_buscandoServidor || termo.trim().length < 2) return;
    _buscandoServidor = true;
    try {
      final encontrados = await HydraApi.instance.buscar(termo);
      if (!mounted || encontrados.isEmpty) return;
      final porId = <String, Produto>{for (final p in _produtos) p.id: p};
      for (final p in encontrados) {
        porId[p.id] = p;
      }
      setState(() => _produtos = porId.values.toList());
    } catch (_) {
      // Busca incremental não deve apagar a lista já exibida.
    } finally {
      _buscandoServidor = false;
    }
  }

  String _codigoDepartamento(Produto produto) =>
      produto.departamento.split(' - ').first.trim();

  List<Produto> get _filtrados {
    final busca = _buscaController.text.trim().toLowerCase();
    final digitos = busca.replaceAll(RegExp(r'[^0-9]'), '');
    return _produtos.where((p) {
      final casaBusca = busca.isEmpty ||
          p.descricao.toLowerCase().contains(busca) ||
          p.codigoSap.toLowerCase().contains(busca) ||
          p.eans.any((ean) {
            final eanDigitos = ean.replaceAll(RegExp(r'[^0-9]'), '');
            return ean.toLowerCase().contains(busca) ||
                (digitos.length >= 8 && eanDigitos.contains(digitos));
          });
      final casaDepartamento =
          _departamento.isEmpty || _codigoDepartamento(p) == _departamento;
      return casaBusca && casaDepartamento;
    }).toList();
  }

  List<String> get _departamentos {
    return _produtos
        .map(_codigoDepartamento)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<Produto> get _selecionadosVisiveis =>
      _filtrados.where((p) => _selecionados.contains(p.id)).toList();

  bool get _todosSelecionados {
    final lista = _filtrados;
    return lista.isNotEmpty && lista.every((p) => _selecionados.contains(p.id));
  }

  bool get _algumSelecionado =>
      _filtrados.any((p) => _selecionados.contains(p.id));

  Future<void> _abrirScanner() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (codigo == null || !mounted) return;
    final somenteNumeros = codigo.replaceAll(RegExp(r'[^0-9]'), '');
    _buscaController.text = somenteNumeros.substring(
      0,
      somenteNumeros.length > 13 ? 13 : somenteNumeros.length,
    );
    _buscaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _buscaController.text.length),
    );
    _debounce?.cancel();
    await _buscarNoServidor(_buscaController.text);
  }

  Future<void> _confirmarSelecao() async {
    final selecionados = _selecionadosVisiveis;
    if (selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um produto.')),
      );
      return;
    }
    if (_preparando) return;
    setState(() {
      _preparando = true;
      _erro = null;
    });
    try {
      await HydraApi.instance.prepararEdicao(
        selecionados.map((p) => p.id).toList(),
      );
      if (!mounted) return;
      final salvou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => SelectedItemsScreen(itens: selecionados)),
      );
      if (salvou == false && mounted) {
        setState(() => _selecionados.clear());
      } else if (salvou == true && mounted) {
        await _carregar();
        if (mounted) {
          final quantidade = selecionados.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.cyan,
              content: Text(
                quantidade == 1
                    ? '1 item alterado com sucesso.'
                    : '$quantidade itens alterados com sucesso.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _preparando = false);
    }
  }

  Future<void> _confirmarSaida() async {
    if (_saidaDialogAberta) return;
    _saidaDialogAberta = true;
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do aplicativo?'),
        content: const Text('Deseja realmente fechar o Alterar Preço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'SAIR',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    _saidaDialogAberta = false;
    if (sair == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarSaida();
      },
      child: Scaffold(
        backgroundColor: _fundo,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                child: const Text(
                  'Administrar Preços da Loja 291',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 23, 15, 0),
                child: Row(
                  children: [
                    Expanded(child: _campoEan()),
                    const SizedBox(width: 7),
                    _botaoScanner(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _filtroDepartamento(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _barraSelecao(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 5),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _botaoConfirmar(),
                ),
              ),
              if (_erro != null && _produtos.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Erro ao carregar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _erro!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              else if (_carregando)
                Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.red)),
                )
              else
                Expanded(child: _listaProdutos()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoEan() {
    return Container(
      height: 57,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borda),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _buscaController,
              keyboardType: TextInputType.number,
              maxLength: 13,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              onSubmitted: (valor) => _buscarNoServidor(valor),
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Digite o EAN (até 13 dígitos)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                suffixIcon: _buscaController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _buscaController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close, size: 19, color: AppColors.textMuted),
                      )
                    : null,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _buscarNoServidor(_buscaController.text),
            icon: const Icon(Icons.search, color: AppColors.textMuted, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _botaoScanner() {
    return SizedBox(
      width: 50,
      height: 57,
      child: IconButton(
        onPressed: _abrirScanner,
        icon: const Icon(Icons.qr_code_scanner, color: AppColors.cyan, size: 31),
      ),
    );
  }

  Widget _filtroDepartamento() {
    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.only(top: 13),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border(
          top: BorderSide(color: _borda),
          left: BorderSide(color: _borda),
          right: BorderSide(color: _borda),
          bottom: BorderSide(color: AppColors.cyan, width: 3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _departamento,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.cyan, size: 28),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Todos os departamentos'),
            ),
            ..._departamentos.map(
              (dept) => DropdownMenuItem<String>(
                value: dept,
                child: Text(
                  '$dept - Departamento $dept',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _departamento = value ?? ''),
        ),
      ),
    );
  }

  Widget _barraSelecao() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.headerGray,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _todosSelecionados
                ? true
                : _algumSelecionado
                    ? null
                    : false,
            tristate: true,
            activeColor: AppColors.cyan,
            checkColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1.5),
            onChanged: (valor) {
              setState(() {
                final ids = _filtrados.map((p) => p.id).toSet();
                if (valor == true) {
                  _selecionados.addAll(ids);
                } else {
                  _selecionados.removeAll(ids);
                }
              });
            },
          ),
          const Expanded(
            child: Text(
              'Selecionar todos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${_selecionadosVisiveis.length} selecionado(s)',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _botaoConfirmar() {
    return SizedBox(
      height: 53,
      child: ElevatedButton(
        onPressed: (_selecionadosVisiveis.isEmpty || _preparando)
            ? null
            : _confirmarSelecao,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: _preparando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmar Seleção',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 23),
                ],
              ),
      ),
    );
  }

  Widget _listaProdutos() {
    final lista = _filtrados;
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto encontrado.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 25),
      itemCount: lista.length,
      itemBuilder: (context, index) => _cardProduto(lista[index]),
    );
  }

  Widget _cardProduto(Produto produto) {
    final marcado = _selecionados.contains(produto.id);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borda),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: marcado,
                activeColor: AppColors.cyan,
                onChanged: (valor) {
                  setState(() {
                    if (valor == true) {
                      _selecionados.add(produto.id);
                    } else {
                      _selecionados.remove(produto.id);
                    }
                  });
                },
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Text(
                    produto.descricao,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 23, color: _borda),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAP',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      produto.codigoSap,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'EAN',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      produto.eans.join('\n'),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(left: 13),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: _borda)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Departamento',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        produto.departamento,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            produto.precoFormatado,
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
