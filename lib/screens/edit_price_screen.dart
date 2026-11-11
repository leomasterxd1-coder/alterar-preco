import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
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

  Future<void> _salvar() async {
    if (_salvando) return;
    if (_itens.isEmpty) {
      setState(() => _erro = 'Nenhum item selecionado.');
      return;
    }
    if (_itens.any((i) => i.preco.text.trim().isEmpty || i.justificativa.text.trim().isEmpty)) {
      setState(() => _erro = 'Preencha o preço provisório e a justificativa de todos os itens.');
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
              (i) => AlteracaoPreco(
                id: i.produto.id,
                preco: i.preco.text.trim(),
                justificativa: i.justificativa.text.trim(),
                clienteA: i.clienteA,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edição de Preços da Loja 291',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Os preços alterados permanecerão válidos só até 23:59h da Data de Início escolhida.',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                          minimumSize: const Size(0, 42),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _salvando ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            disabledBackgroundColor: AppColors.red.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                            elevation: 0,
                          ),
                          child: _salvando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Salvar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 10),
                    Text(_erro!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Container(height: 6, color: const Color(0xFFD9D9D9)),
            Expanded(
              child: Container(
                color: const Color(0xFFE3E3E3),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _itens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _itens[index];
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: _cardEdicao(item, index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardEdicao(_EdicaoItem item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.produto.descricao,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _itens.removeAt(index)),
              icon: const Icon(Icons.delete_outline, color: AppColors.cyan, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _info('Código', item.produto.codigoSap)),
            const SizedBox(width: 12),
            Expanded(child: _info('EAN', item.produto.eans.join(', '))),
            const SizedBox(width: 12),
            Expanded(child: _info('Departamento', item.produto.departamento)),
          ],
        ),
        const SizedBox(height: 14),
        _info('Preço Atual', item.produto.precoFormatado),
        const SizedBox(height: 20),
        Text(
          'Dados para Alteração de Preço',
          style: TextStyle(color: AppColors.red, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 8,
              child: _campo(
                controller: item.preco,
                hint: 'Preço Provisório',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 14,
              child: _campo(
                controller: item.justificativa,
                hint: 'Justifique a Alteração',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('Exclusivo Cliente A', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(width: 8),
            Checkbox(
              value: item.clienteA,
              onChanged: (value) => setState(() => item.clienteA = value ?? false),
              activeColor: Colors.white,
              checkColor: AppColors.cyan,
              side: const BorderSide(color: AppColors.cyan, width: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.3),
        ),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.7)),
        ),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.red)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
