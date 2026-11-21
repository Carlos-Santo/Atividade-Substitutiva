import 'package:flutter/foundation.dart';

import 'refueling.dart';

/// Indicadores de um abastecimento, calculados em relação ao anterior.
///
/// Regras da atividade (todo abastecimento completa o tanque):
/// * distância = km atual − km do abastecimento anterior;
/// * consumo (km/L) = distância ÷ litros do abastecimento atual;
/// * custo (R$/km) = valor total do abastecimento atual ÷ distância.
///
/// O primeiro abastecimento é só a referência inicial ([isBaseline]) e não
/// tem km/L nem R$/km.
@immutable
class RefuelingInsight {
  const RefuelingInsight({required this.refueling, this.previous});

  final Refueling refueling;

  /// Abastecimento imediatamente anterior, na ordem cronológica.
  final Refueling? previous;

  bool get isBaseline => previous == null;

  /// Quilômetros rodados desde o abastecimento anterior.
  int? get distanceKm {
    final previous = this.previous;
    if (previous == null) return null;
    final distance = refueling.odometerKm - previous.odometerKm;
    return distance > 0 ? distance : null;
  }

  double? get kmPerLiter {
    final distance = distanceKm;
    if (distance == null || refueling.liters <= 0) return null;
    return distance / refueling.liters;
  }

  double? get costPerKm {
    final distance = distanceKm;
    if (distance == null) return null;
    return refueling.totalCost / distance;
  }

  bool get hasIndicators => distanceKm != null;
}
