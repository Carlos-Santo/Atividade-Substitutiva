import 'package:flutter/material.dart';

import '../../domain/models/fuel_type.dart';
import '../../domain/models/vehicle_type.dart';

/// Ícones dos tipos de veículo. Ficam na camada de interface para que o
/// domínio não dependa do Flutter Material.
extension VehicleTypeIcon on VehicleType {
  IconData get icon => switch (this) {
    VehicleType.car => Icons.directions_car_filled_rounded,
    VehicleType.motorcycle => Icons.two_wheeler_rounded,
    VehicleType.truck => Icons.local_shipping_rounded,
  };
}

extension FuelTypeIcon on FuelType {
  IconData get icon => switch (this) {
    FuelType.ethanol => Icons.eco_rounded,
    FuelType.gasoline => Icons.local_gas_station_rounded,
    FuelType.diesel => Icons.oil_barrel_rounded,
  };
}
