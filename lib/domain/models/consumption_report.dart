import 'package:flutter/foundation.dart';

import 'refueling.dart';
import 'refueling_insight.dart';

/// Consolidado do histórico de abastecimentos, usado no dashboard.
///
/// Recebe os abastecimentos em qualquer ordem e os organiza em ordem
/// cronológica antes de calcular os indicadores.
@immutable
class ConsumptionReport {
  const ConsumptionReport._(this.entries);

  factory ConsumptionReport.from(Iterable<Refueling> refuelings) {
    final sorted = [...refuelings]..sort(Refueling.chronological);
    final entries = <RefuelingInsight>[
      for (var i = 0; i < sorted.length; i++)
        RefuelingInsight(
          refueling: sorted[i],
          previous: i == 0 ? null : sorted[i - 1],
        ),
    ];
    return ConsumptionReport._(List.unmodifiable(entries));
  }

  static const empty = ConsumptionReport._([]);

  /// Indicadores de cada abastecimento, do mais antigo para o mais recente.
  final List<RefuelingInsight> entries;

  bool get isEmpty => entries.isEmpty;
  int get count => entries.length;

  /// Abastecimentos que já têm km/L e R$/km (do segundo em diante).
  List<RefuelingInsight> get measured =>
      entries.where((e) => e.hasIndicators).toList(growable: false);

  /// Do mais recente para o mais antigo, para listas.
  Iterable<RefuelingInsight> get newestFirst => entries.reversed;

  RefuelingInsight? get latest => entries.isEmpty ? null : entries.last;

  double get totalSpent =>
      entries.fold(0, (sum, e) => sum + e.refueling.totalCost);

  double get totalLiters =>
      entries.fold(0, (sum, e) => sum + e.refueling.liters);

  /// Distância total entre o primeiro e o último abastecimento.
  int get totalDistanceKm => measured.fold(0, (sum, e) => sum + e.distanceKm!);

  /// Consumo médio ponderado: distância total ÷ litros consumidos nela.
  ///
  /// É mais fiel que a média simples dos km/L, porque trechos longos pesam
  /// mais. Os litros do primeiro abastecimento não entram, pois foram
  /// consumidos antes do período medido.
  double? get averageKmPerLiter {
    final measured = this.measured;
    if (measured.isEmpty) return null;
    final liters = measured.fold<double>(0, (s, e) => s + e.refueling.liters);
    return liters > 0 ? totalDistanceKm / liters : null;
  }

  /// Custo médio ponderado: valor gasto no período ÷ distância total.
  double? get averageCostPerKm {
    final measured = this.measured;
    if (measured.isEmpty) return null;
    final cost = measured.fold<double>(0, (s, e) => s + e.refueling.totalCost);
    final distance = totalDistanceKm;
    return distance > 0 ? cost / distance : null;
  }

  /// Valor médio de cada abastecimento.
  double? get averageRefuelingCost => isEmpty ? null : totalSpent / count;
}
