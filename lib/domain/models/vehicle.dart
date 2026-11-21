import 'package:flutter/foundation.dart';

import 'catalog_item.dart';
import 'vehicle_type.dart';

/// Veículo cadastrado pelo usuário. O app mantém apenas um por vez.
@immutable
class Vehicle {
  const Vehicle({
    this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.year,
    required this.engineDisplacementCc,
  });

  /// Identificador local. É nulo até o veículo ser salvo.
  final int? id;
  final VehicleType type;
  final CatalogItem brand;
  final CatalogItem model;
  final int year;

  /// Cilindrada do motor em centímetros cúbicos (cm³).
  final int engineDisplacementCc;

  /// Nome curto para títulos, por exemplo "Fiat Argo 1.0 6V Flex".
  String get displayName => '${brand.name} ${model.name}';

  /// Cilindrada em litros, por exemplo 1598 cm³ → 1.6 L.
  double get engineDisplacementLiters => engineDisplacementCc / 1000;

  Vehicle copyWith({int? id}) => Vehicle(
    id: id ?? this.id,
    type: type,
    brand: brand,
    model: model,
    year: year,
    engineDisplacementCc: engineDisplacementCc,
  );

  @override
  bool operator ==(Object other) =>
      other is Vehicle &&
      other.id == id &&
      other.type == type &&
      other.brand == brand &&
      other.model == model &&
      other.year == year &&
      other.engineDisplacementCc == engineDisplacementCc;

  @override
  int get hashCode =>
      Object.hash(id, type, brand, model, year, engineDisplacementCc);
}
