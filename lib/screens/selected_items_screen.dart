import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'edit_price_screen.dart';

class SelectedItemsResult {
  final bool salvou;
  final Set<String> selecionados;

  const SelectedItemsResult({
    required this.salvou,
    required this.selecionados,
  });
}

class SelectedItemsScreen extends StatefulWidget {
  final List<Produto> itens;
  const SelectedItemsScreen({super.key, required this.itens});

  @override
  State<SelectedItemsScreen> createState() => _SelectedItemsScreenState();
}

class _SelectedItemsScreenState extends State<SelectedItemsScreen> {
  late final Set<String> _selecionados;

  @override
  void initState() {
    super.initState();
    _selecionados = widget.itens.map((p) => p.id).toSet();
  }

  bool get _todosSelecionados =>
      widget.itens.isNotEmpty && _selecionados.length == widget.itens.length;

  Future<void> _editar() async {
    final itens = widget.itens.where((p) => _selecionados.contains(p.id)).toList();
    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um produto.')),
      );
      return;
    }
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditPriceScreen(itens: itens)),
    );
    if (salvou == true && mounted) {
      Navigator.of(context).pop(
        SelectedItemsResult(salvou: true, selecionados: _selecionados),
      );
    }
  }

  void _alternarTodos() {
    setState(() {
      if (_todosSelecionados) {
        _selecionados.clear();
      } else {
        _selecionados.addAll(widget.itens.map((p) => p.id));
      }
    });
  }

  void _voltarComSelecao() {
    Navigator.of(context).pop(
      SelectedItemsResult(salvou: false, selecionados: _selecionados),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(top: BorderSide(color: AppColors.divider)),
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
                      onPressed: _voltarComSelecao,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Adicionar mais',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _selecionados.isEmpty ? null : _editar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.red.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      label: const Text(
                        'Alterar preços',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.headerGray,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _selecionados.length.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Selecionados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selecionados.length}/${widget.itens.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _alternarTodos,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: const BorderSide(color: AppColors.cyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(
                      _todosSelecionados ? 'Deselecionar todos' : 'Selecionar todos',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: _selecionados.isEmpty
                        ? AppColors.red.withValues(alpha: 0.4)
                        : AppColors.red,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _selecionados.isEmpty ? null : _editar,
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(Icons.edit, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.separated(
                  itemCount: widget.itens.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) {
                    final produto = widget.itens[index];
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            IgnorePointer(
                              child: Checkbox(
                                value: marcado,
                                onChanged: (_) {},
                                activeColor: AppColors.cyan,
                                checkColor: Colors.white,
                                side: const BorderSide(color: AppColors.cyan, width: 2),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                produto.descricao,
                                maxLines: 2,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              produto.codigoSap,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
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
}
