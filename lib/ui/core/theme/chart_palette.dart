import 'package:flutter/material.dart';

/// Cores dos gráficos do dashboard, com um tom próprio para cada modo.
///
/// Cada métrica tem uma cor fixa, igual em todas as telas: valor do
/// abastecimento (azul), consumo km/L (verde-água) e custo R$/km (laranja).
/// No modo escuro os tons são ajustados para manter o contraste com o fundo.
@immutable
class ChartPalette extends ThemeExtension<ChartPalette> {
  const ChartPalette({
    required this.cost,
    required this.efficiency,
    required this.costPerKm,
  });

  static const light = ChartPalette(
    cost: Color(0xFF2A78D6),
    efficiency: Color(0xFF1BAF7A),
    costPerKm: Color(0xFFEB6834),
  );

  static const dark = ChartPalette(
    cost: Color(0xFF3987E5),
    efficiency: Color(0xFF199E70),
    costPerKm: Color(0xFFD95926),
  );

  final Color cost;
  final Color efficiency;
  final Color costPerKm;

  static ChartPalette of(BuildContext context) =>
      Theme.of(context).extension<ChartPalette>() ?? light;

  @override
  ChartPalette copyWith({Color? cost, Color? efficiency, Color? costPerKm}) =>
      ChartPalette(
        cost: cost ?? this.cost,
        efficiency: efficiency ?? this.efficiency,
        costPerKm: costPerKm ?? this.costPerKm,
      );

  @override
  ChartPalette lerp(ChartPalette? other, double t) {
    if (other == null) return this;
    return ChartPalette(
      cost: Color.lerp(cost, other.cost, t)!,
      efficiency: Color.lerp(efficiency, other.efficiency, t)!,
      costPerKm: Color.lerp(costPerKm, other.costPerKm, t)!,
    );
  }
}
