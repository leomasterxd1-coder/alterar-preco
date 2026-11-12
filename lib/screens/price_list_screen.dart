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
  final _buscaController = TextEditingController();
  final _selecionados = <String>{};
  List<Produto> _produtos = [];
  bool _carregando = true;
  bool _preparando = false;
  bool _buscandoServidor = false;
  String? _erro;
  String? _departamento;
  Timer? _debounce;
  bool _saidaDialogAberta = false;

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
    if (termo.length < 3) {
      setState(() {});
      return;
    }
    setState(() {});
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
      // Busca é incremental; erros não devem apagar a lista já exibida.
    } finally {
      _buscandoServidor = false;
    }
  }

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
      final casaDepartamento = _departamento == null || p.departamento == _departamento;
      return casaBusca && casaDepartamento;
    }).toList();
  }

  List<String> get _departamentos => _produtos
      .map((p) => p.departamento)
      .where((d) => d.trim().isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> _abrirScanner() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (codigo == null || !mounted) return;
    _buscaController.text = codigo;
    _buscaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _buscaController.text.length),
    );
    _debounce?.cancel();
    await _buscarNoServidor(codigo);
  }

  Future<void> _confirmarSelecao() async {
    final escolhidos = _produtos.where((p) => _selecionados.contains(p.id)).toList();
    if (escolhidos.isEmpty || _preparando) return;
    setState(() {
      _preparando = true;
      _erro = null;
    });
    try {
      await HydraApi.instance.prepararEdicao(escolhidos.map((p) => p.id).toList());
      if (!mounted) return;
      final salvou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => SelectedItemsScreen(itens: escolhidos)),
      );
      if (salvou == true && mounted) {
        await _carregar();
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
    if (sair == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final todosMarcados = filtrados.isNotEmpty && filtrados.every((p) => _selecionados.contains(p.id));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarSaida();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Text(
                  'Administrar Preços da loja 291',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 13,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _buscaController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText: '7894900011609',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.7)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.red),
                              ),
                              contentPadding: const EdgeInsets.only(bottom: 12, top: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _buscarNoServidor(_buscaController.text),
                          icon: const Icon(Icons.search, color: Color(0xFFBDBDBD)),
                        ),
                        IconButton(
                          onPressed: _abrirScanner,
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.cyan),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _departamento,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more, color: AppColors.cyan),
                            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todos os departamentos'),
                              ),
                              ..._departamentos.map(
                                (d) => DropdownMenuItem<String?>(
                                  value: d,
                                  child: Text(
                                    d,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(() => _departamento = value),
                          ),
                        ),
                        Container(height: 2, color: AppColors.cyan),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_carregando)
              Expanded(
                child: Center(child: CircularProgressIndicator(color: AppColors.red)),
              )
            else if (_erro != null && _produtos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Erro ao carregar', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_erro!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                    ],
                  ),
                ),
              )
            else ...[
              _headerTabela(
                todosMarcados,
                () {
                  final ids = filtrados.map((p) => p.id).toSet();
                  setState(() {
                    if (todosMarcados) {
                      _selecionados.removeAll(ids);
                    } else {
                      _selecionados.addAll(ids);
                    }
                  });
                },
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _selecionados.isEmpty || _preparando ? null : _confirmarSelecao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                        elevation: 0,
                      ),
                      child: _preparando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Confirmar Seleção', style: TextStyle(color: Colors.white, fontSize: 13)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              if (_erro != null)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(_erro!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                ),
              Expanded(
                child: filtrados.isEmpty
                    ? const Center(child: Text('Nenhum produto encontrado.', style: TextStyle(color: AppColors.textMuted)))
                    : Container(
                        color: Colors.white,
                        child: ListView.separated(
                          itemCount: filtrados.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, index) {
                            final produto = filtrados[index];
                            return _linhaProduto(produto);
                          },
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _headerTabela(bool todosMarcados, VoidCallback onToggle) {
    return Container(
      color: AppColors.headerGray,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: _checkbox(todosMarcados, onChanged: (_) => onToggle()),
            ),
          ),
          const Expanded(flex: 21, child: _HeaderCell('Descrição')),
          const Expanded(flex: 12, child: _HeaderCell('Código SAP')),
          const Expanded(flex: 12, child: _HeaderCell('EANs')),
          const Expanded(flex: 18, child: _HeaderCell('Departamento')),
          const Expanded(flex: 9, child: _HeaderCell('Preço')),
        ],
      ),
    );
  }

  Widget _linhaProduto(Produto produto) {
    final marcado = _selecionados.contains(produto.id);
    return InkWell(
      onTap: () {
        setState(() {
          if (marcado) {
            _selecionados.remove(produto.id);
          } else {
            _selecionados.add(produto.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: _checkbox(marcado, onChanged: (_) {
                  setState(() {
                    if (marcado) {
                      _selecionados.remove(produto.id);
                    } else {
                      _selecionados.add(produto.id);
                    }
                  });
                }),
              ),
            ),
            Expanded(
              flex: 21,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  produto.descricao,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: _corpo(produto.codigoSap),
            ),
            Expanded(
              flex: 12,
              child: _corpo(produto.eansTexto),
            ),
            Expanded(
              flex: 18,
              child: _corpo(produto.departamento),
            ),
            Expanded(
              flex: 9,
              child: _corpo(produto.precoFormatado),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corpo(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        texto,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.35),
      ),
    );
  }

  Widget _checkbox(bool value, {required ValueChanged<bool?> onChanged}) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      checkColor: AppColors.cyan,
      side: const BorderSide(color: AppColors.cyan, width: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String texto;
  const _HeaderCell(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        texto,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
