import '../formatting/number_input.dart';

/// Validadores dos campos de formulário. Retornam a mensagem de erro ou nulo
/// quando o valor é válido, no formato esperado por `TextFormField.validator`.
abstract final class Validators {
  static const minYear = 1900;

  static String? year(String? text, {DateTime? now}) {
    final value = NumberInput.parseInt(text);
    if (value == null) return 'Informe o ano';
    final maxYear = (now ?? DateTime.now()).year + 1;
    if (value < minYear || value > maxYear) {
      return 'Ano entre $minYear e $maxYear';
    }
    return null;
  }

  static String? displacement(String? text) {
    final value = NumberInput.parseInt(text);
    if (value == null) return 'Informe a cilindrada';
    if (value < 50 || value > 20000) return 'Entre 50 e 20.000 cm³';
    return null;
  }

  static String? pricePerLiter(String? text) {
    final value = NumberInput.parseDecimal(text);
    if (value == null) return 'Informe o preço';
    if (value <= 0) return 'O preço deve ser maior que zero';
    if (value > 100) return 'Preço muito alto';
    return null;
  }

  static String? liters(String? text) {
    final value = NumberInput.parseDecimal(text);
    if (value == null) return 'Informe os litros';
    if (value <= 0) return 'Deve ser maior que zero';
    if (value > 2000) return 'Quantidade muito alta';
    return null;
  }

  static String? odometer(String? text) {
    final value = NumberInput.parseInt(text);
    if (value == null) return 'Informe a quilometragem';
    if (value > 9999999) return 'Quilometragem muito alta';
    return null;
  }
}
