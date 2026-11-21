import 'package:flutter/services.dart';

/// Utilitários para campos numéricos digitados pelo usuário.
abstract final class NumberInput {
  /// Converte texto digitado em número. Aceita vírgula ou ponto como
  /// separador decimal ("5,89" ou "5.89"). Retorna nulo se for inválido.
  static double? parseDecimal(String? text) {
    final normalized = text?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static int? parseInt(String? text) {
    final normalized = text?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  /// Escreve um número no formato de edição brasileiro, sem zeros finais.
  /// Exemplo: 5.9 → "5,9" e 40.0 → "40".
  static String toEditableText(double value, {int maxDecimals = 3}) {
    var text = value.toStringAsFixed(maxDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text.replaceAll('.', ',');
  }

  /// Filtro de digitação que aceita apenas dígitos e um separador decimal,
  /// com no máximo [decimals] casas.
  static TextInputFormatter decimalFormatter({int decimals = 2}) =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final pattern = RegExp('^\\d{0,9}([.,]\\d{0,$decimals})?\$');
        return pattern.hasMatch(newValue.text) ? newValue : oldValue;
      });

  static final digitsOnly = FilteringTextInputFormatter.digitsOnly;
}
