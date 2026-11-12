import 'package:flutter/material.dart';

import '../api.dart';
import '../currency_input_formatter.dart';
import '../models.dart';
import '../theme.dart';

class EditPriceScreen extends StatefulWidget {
  final List<Produto> itens;
  const EditPriceScreen({super.key, required this.itens});

  @override
  State<EditPriceScreen> createState() => _EditPriceScreenState();
}

class _EdicaoItem {
  final Produto produto;
  final TextEditingController preco;
  final TextEditingController justificativa;
  bool clienteA;

  _EdicaoItem(this.produto)
      : preco = TextEditingController(),
        justificativa = TextEditingController(),
        clienteA = false;

  void dispose() {
    preco.dispose();
    justificativa.dispose();
  }
}

class _EditPriceScreenState extends State<EditPriceScreen> {
  static const _vermelho = Color(0xFFA92327);
  static const _vermelhoBotao = Color(0xFFB51F24);
  static const _cinza = Color(0xFF888888);
  static const _texto = Color(0xFF30383E);
  static const _borda = Color(0xFFE0E4E6);
  static const _fundo = Color(0xFFF4F5F5);

  late final List<_EdicaoItem> _itens;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _itens = widget.itens.map(_EdicaoItem.new).toList();
  }

  @override
  void dispose() {
    for (final item in _itens) {
      item.dispose();
    }
    super.dispose();
  }

  void _remover(int index) {
    setState(() {
      final item = _itens.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (_salvando) return;
    if (_itens.isEmpty) {
      setState(() => _erro = 'Nenhum item selecionado.');
      return;
    }
    final invalido = _itens.any((item) {
      final preco = precoParaApi(item.preco.text);
      final numero = double.tryParse(preco);
      return item.preco.text.trim().isEmpty ||
          numero == null ||
          numero <= 0 ||
          item.justificativa.text.trim().isEmpty;
    });
    if (invalido) {
      setState(() => _erro = 'Preencha o preço e a justificativa de todos os itens.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await HydraApi.instance.salvarPrecos(
        _itens
            .map(
              (item) => AlteracaoPreco(
                id: item.produto.id,
                preco: item.preco.text.trim(),
                justificativa: item.justificativa.text.trim(),
                clienteA: item.clienteA,
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        bottom: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 25),
          children: [
            const Text(
              'Edição de Preços',
              style: TextStyle(
                color: _vermelho,
                fontSize: 27,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'LOJA 291',
              style: TextStyle(
                color: _cinza,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 22),
            _avisoValidade(),
            const SizedBox(height: 20),
            ..._itens.asMap().entries.map(
                  (entry) => _cardItem(entry.key, entry.value),
                ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _erro!,
                  style: const TextStyle(color: _vermelho, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _barraInferior(),
    );
  }

  Widget _avisoValidade() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9DDB8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFA68B43), size: 23),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validade dos preços',
                  style: TextStyle(
                    color: Color(0xFF806A32),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Os preços alterados permanecerão válidos só até 23:59h da Data de Início escolhida.',
                  style: TextStyle(
                    color: Color(0xFF9A854B),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardItem(int index, _EdicaoItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borda),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
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
              Expanded(
                child: Text(
                  item.produto.descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Excluir produto',
                onPressed: () => _remover(index),
                icon: const Icon(Icons.delete_outline, color: AppColors.cyan, size: 28),
              ),
            ],
          ),
          const Divider(height: 25, color: _borda),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _colunaInfo('Código', item.produto.codigoSap)),
              const SizedBox(width: 8),
              Expanded(child: _colunaInfo('EAN', item.produto.eans.join(', '))),
              const SizedBox(width: 8),
              Expanded(child: _colunaInfo('Departamento', item.produto.departamento)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _fundo,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preço atual', style: TextStyle(color: _cinza, fontSize: 13)),
                const SizedBox(height: 5),
                Text(
                  item.produto.precoFormatado,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Dados para Alteração de Preço',
            style: TextStyle(color: _vermelho, fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _campoPreco(item),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _campoJustificativa(item),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => item.clienteA = !item.clienteA),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: item.clienteA,
                    activeColor: AppColors.cyan,
                    side: const BorderSide(color: AppColors.cyan, width: 2),
                    onChanged: (valor) => setState(() => item.clienteA = valor ?? false),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Exclusivo Cliente A',
                      style: TextStyle(color: _cinza, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colunaInfo(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(color: _cinza, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          valor.isEmpty ? '-' : valor,
          style: const TextStyle(color: _texto, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _campoPreco(_EdicaoItem item) {
    return TextField(
      controller: item.preco,
      keyboardType: TextInputType.number,
      inputFormatters: const [MoedaInputFormatter()],
      style: const TextStyle(fontSize: 15, color: _texto),
      decoration: const InputDecoration(
        labelText: 'Preço Provisório',
        prefixText: 'R\$ ',
        labelStyle: TextStyle(color: _cinza),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _borda)),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _vermelho, width: 2),
        ),
      ),
    );
  }

  Widget _campoJustificativa(_EdicaoItem item) {
    return TextField(
      controller: item.justificativa,
      style: const TextStyle(fontSize: 15, color: _texto),
      decoration: const InputDecoration(
        labelText: 'Justifique a Alteração',
        labelStyle: TextStyle(color: _cinza),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _borda)),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _vermelho, width: 2),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(top: BorderSide(color: _borda)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _vermelho,
                      side: const BorderSide(color: _vermelho, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _vermelhoBotao,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _vermelhoBotao.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined, size: 19),
                              SizedBox(width: 7),
                              Text(
                                'Salvar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
