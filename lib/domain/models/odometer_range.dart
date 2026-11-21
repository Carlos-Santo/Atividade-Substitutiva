import 'package:flutter/foundation.dart';

import 'refueling.dart';

/// Faixa válida de quilometragem para um abastecimento numa data.
///
/// O hodômetro só aumenta. Então um abastecimento precisa ter km maior que o
/// do abastecimento anterior a ele e menor que o do seguinte. Sem essa regra
/// a distância entre abastecimentos ficaria negativa e os indicadores
/// perderiam o sentido.
@immutable
class OdometerRange {
  const OdometerRange({this.previous, this.next});

  /// Calcula a faixa para um abastecimento em [date], considerando o
  /// histórico [history]. Use [ignoreId] ao editar um registro existente,
  /// para que ele não seja comparado com ele mesmo.
  factory OdometerRange.forDate(
    Iterable<Refueling> history,
    DateTime date, {
    int? ignoreId,
  }) {
    Refueling? previous;
    Refueling? next;
    for (final item in history) {
      if (ignoreId != null && item.id == ignoreId) continue;
      if (!item.date.isAfter(date)) {
        if (previous == null || Refueling.chronological(item, previous) > 0) {
          previous = item;
        }
      } else if (next == null || Refueling.chronological(item, next) < 0) {
        next = item;
      }
    }
    return OdometerRange(previous: previous, next: next);
  }

  /// Último abastecimento antes da data informada.
  final Refueling? previous;

  /// Primeiro abastecimento depois da data informada.
  final Refueling? next;

  /// Quilometragem mínima (exclusiva).
  int? get minExclusive => previous?.odometerKm;

  /// Quilometragem máxima (exclusiva).
  int? get maxExclusive => next?.odometerKm;

  bool contains(int km) {
    final min = minExclusive;
    final max = maxExclusive;
    if (min != null && km <= min) return false;
    if (max != null && km >= max) return false;
    return true;
  }
}
