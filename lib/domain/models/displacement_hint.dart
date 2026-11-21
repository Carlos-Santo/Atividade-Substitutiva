/// Sugere a cilindrada a partir do nome do modelo da FIPE.
///
/// Os nomes da FIPE costumam trazer a cilindrada em litros, como em
/// "ARGO DRIVE 1.3 8V Flex" (1.3 L = 1300 cm³). A sugestão só preenche o
/// campo; o usuário pode corrigir o valor.
abstract final class DisplacementHint {
  static final _litersPattern = RegExp(
    r'(?:^|[^\d.,])(\d{1,2})[.,](\d)(?![\d.,])',
  );

  static int? fromModelName(String modelName) {
    final match = _litersPattern.firstMatch(modelName);
    if (match == null) return null;
    final liters = double.parse('${match.group(1)}.${match.group(2)}');
    if (liters < 0.5 || liters > 16) return null;
    return (liters * 1000).round();
  }
}
