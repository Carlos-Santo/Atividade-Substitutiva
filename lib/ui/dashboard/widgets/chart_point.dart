import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Um ponto de gráfico: o número do abastecimento (1, 2, 3…, em ordem
/// cronológica), a data e o valor da métrica.
///
/// Usar o número do abastecimento no eixo X alinha os três gráficos: o
/// abastecimento nº 5 fica na mesma posição em todos eles.
@immutable
class ChartPoint {
  const ChartPoint({
    required this.number,
    required this.date,
    required this.value,
  });

  final int number;
  final DateTime date;
  final double value;
}

/// Utilitários de escala dos eixos.
abstract final class ChartScale {
  /// Intervalo entre rótulos do eixo X para mostrar no máximo [maxLabels].
  static double labelInterval(int count, {int maxLabels = 6}) =>
      math.max(1, (count / maxLabels).ceil()).toDouble();

  /// Indica se dois rótulos do eixo X mostrariam a mesma data (dd/MM).
  /// Usado para não repetir o dia quando há vários abastecimentos nele.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Limites do eixo Y com uma folga, para a linha não encostar nas bordas.
  static ({double min, double max}) paddedRange(Iterable<double> values) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = maxValue - minValue;
    final padding = span == 0
        ? (maxValue.abs() * 0.2).clamp(0.1, 10)
        : span * 0.25;
    return (
      min: math.max(0, minValue - padding).toDouble(),
      max: (maxValue + padding).toDouble(),
    );
  }
}
