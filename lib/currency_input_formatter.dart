import 'package:flutter/services.dart';

class MoedaInputFormatter extends TextInputFormatter {
  const MoedaInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue();
    final centavos = int.tryParse(digitos) ?? 0;
    final texto = formatarCentavos(centavos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String formatarCentavos(int centavos) {
  final inteiro = (centavos ~/ 100).toString();
  final decimal = (centavos % 100).toString().padLeft(2, '0');
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return '$buffer,$decimal';
}

String precoParaApi(String texto) {
  final limpo = texto.replaceAll(RegExp(r'[^0-9,.]'), '');
  if (limpo.contains(',')) {
    return limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return limpo;
}
