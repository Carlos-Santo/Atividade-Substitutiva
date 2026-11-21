import 'package:flutter/foundation.dart';

import 'fuel_type.dart';

/// Um abastecimento do veículo.
///
/// Para os cálculos do app, todo abastecimento completa o tanque.
@immutable
class Refueling {
  const Refueling({
    this.id,
    required this.vehicleId,
    required this.fuelType,
    required this.pricePerLiter,
    required this.liters,
    required this.odometerKm,
    required this.date,
  });

  /// Identificador local. É nulo até o abastecimento ser salvo.
  final int? id;
  final int vehicleId;
  final FuelType fuelType;

  /// Preço por litro em reais. Aceita 3 casas decimais, como nas bombas.
  final double pricePerLiter;
  final double liters;

  /// Quilometragem do hodômetro no momento do abastecimento.
  final int odometerKm;
  final DateTime date;

  /// Valor total pago: preço por litro × litros, arredondado para centavos
  /// (é o valor que a bomba cobra).
  double get totalCost => (pricePerLiter * liters * 100).roundToDouble() / 100;

  Refueling copyWith({
    int? id,
    int? vehicleId,
    FuelType? fuelType,
    double? pricePerLiter,
    double? liters,
    int? odometerKm,
    DateTime? date,
  }) => Refueling(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    fuelType: fuelType ?? this.fuelType,
    pricePerLiter: pricePerLiter ?? this.pricePerLiter,
    liters: liters ?? this.liters,
    odometerKm: odometerKm ?? this.odometerKm,
    date: date ?? this.date,
  );

  /// Ordem cronológica. Em caso de empate na data, vale a quilometragem.
  static int chronological(Refueling a, Refueling b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byKm = a.odometerKm.compareTo(b.odometerKm);
    if (byKm != 0) return byKm;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      other is Refueling &&
      other.id == id &&
      other.vehicleId == vehicleId &&
      other.fuelType == fuelType &&
      other.pricePerLiter == pricePerLiter &&
      other.liters == liters &&
      other.odometerKm == odometerKm &&
      other.date == date;

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    fuelType,
    pricePerLiter,
    liters,
    odometerKm,
    date,
  );
}
