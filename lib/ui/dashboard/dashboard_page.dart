import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/formatters.dart';
import '../../domain/models/consumption_report.dart';
import '../../domain/models/vehicle.dart';
import '../core/layout/breakpoints.dart';
import '../core/presentation.dart';
import '../core/theme/chart_palette.dart';
import '../core/widgets/constrained_content.dart';
import '../core/widgets/message_view.dart';
import '../garage/garage_view_model.dart';
import '../routing/routes.dart';
import 'widgets/chart_card.dart';
import 'widgets/chart_point.dart';
import 'widgets/cost_bar_chart.dart';
import 'widgets/indicators_table.dart';
import 'widgets/kpi_tile.dart';
import 'widgets/trend_line_chart.dart';

/// Painel com os indicadores e gráficos de gastos e consumo.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<GarageViewModel>();
    final vehicle = garage.vehicle;
    final report = garage.report;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: report.isEmpty
          ? null
          : FloatingActionButton(
              // Tag própria: as abas ficam montadas lado a lado no shell.
              heroTag: 'dashboard-fab',
              tooltip: 'Novo abastecimento',
              onPressed: () => context.push(Routes.newRefueling),
              child: const Icon(Icons.add_rounded),
            ),
      body: vehicle == null
          ? const SizedBox.shrink()
          : report.isEmpty
          ? MessageView(
              icon: Icons.insights_rounded,
              title: 'Seu painel começa aqui',
              message:
                  'Registre os abastecimentos de ${vehicle.displayName} para '
                  'acompanhar gastos, consumo (km/L) e custo por km.',
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.newRefueling),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Registrar abastecimento'),
              ),
            )
          : _DashboardContent(vehicle: vehicle, report: report),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.vehicle, required this.report});

  final Vehicle vehicle;
  final ConsumptionReport report;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final wide = WindowSize.of(context) == WindowSize.expanded;

    final costPoints = [
      for (final (i, e) in report.entries.indexed)
        ChartPoint(
          number: i + 1,
          date: e.refueling.date,
          value: e.refueling.totalCost,
        ),
    ];
    final efficiencyPoints = <ChartPoint>[];
    final costPerKmPoints = <ChartPoint>[];
    for (final (i, e) in report.entries.indexed) {
      if (!e.hasIndicators) continue;
      efficiencyPoints.add(
        ChartPoint(number: i + 1, date: e.refueling.date, value: e.kmPerLiter!),
      );
      costPerKmPoints.add(
        ChartPoint(number: i + 1, date: e.refueling.date, value: e.costPerKm!),
      );
    }

    const needsSecond =
        'Registre o próximo abastecimento para calcular este indicador.';

    final costChart = ChartCard(
      title: 'Valor de cada abastecimento',
      subtitle: 'Total pago (R\$) por abastecimento',
      color: palette.cost,
      child: CostBarChart(points: costPoints, color: palette.cost),
    );
    final efficiencyChart = ChartCard(
      title: 'Consumo',
      subtitle: 'Quilômetros por litro (km/L)',
      color: palette.efficiency,
      trailing: _AverageBadge(
        value: report.averageKmPerLiter,
        format: Formatters.kmPerLiter,
      ),
      child: efficiencyPoints.isEmpty
          ? const ChartPlaceholder(message: needsSecond)
          : TrendLineChart(
              points: efficiencyPoints,
              color: palette.efficiency,
              average: report.averageKmPerLiter,
              axisDecimals: 1,
              formatValue: Formatters.kmPerLiter,
            ),
    );
    final costPerKmChart = ChartCard(
      title: 'Custo por quilômetro',
      subtitle: r'Reais por km rodado (R$/km)',
      color: palette.costPerKm,
      trailing: _AverageBadge(
        value: report.averageCostPerKm,
        format: Formatters.costPerKm,
      ),
      child: costPerKmPoints.isEmpty
          ? const ChartPlaceholder(message: needsSecond)
          : TrendLineChart(
              points: costPerKmPoints,
              color: palette.costPerKm,
              average: report.averageCostPerKm,
              axisDecimals: 2,
              formatValue: Formatters.costPerKm,
            ),
    );

    const gap = SizedBox(height: 16, width: 16);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      children: [
        ConstrainedContent(
          maxWidth: ContentWidth.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VehicleSummary(vehicle: vehicle, report: report),
              gap,
              _KpiGrid(report: report),
              gap,
              costChart,
              gap,
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: efficiencyChart),
                      gap,
                      Expanded(child: costPerKmChart),
                    ],
                  ),
                )
              else ...[
                efficiencyChart,
                gap,
                costPerKmChart,
              ],
              gap,
              IndicatorsTable(report: report),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleSummary extends StatelessWidget {
  const _VehicleSummary({required this.vehicle, required this.report});

  final Vehicle vehicle;
  final ConsumptionReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latest = report.latest?.refueling;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(vehicle.type.icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (latest != null)
                Text(
                  'Último abastecimento: ${Formatters.dateTime(latest.date)} · '
                  '${Formatters.km(latest.odometerKm)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.report});

  final ConsumptionReport report;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final avgKmL = report.averageKmPerLiter;
    final avgCostKm = report.averageCostPerKm;

    final tiles = [
      KpiTile(
        icon: Icons.payments_outlined,
        label: 'Total gasto',
        value: Formatters.currency(report.totalSpent),
        caption: '${report.count} abastecimento${report.count == 1 ? '' : 's'}',
        accent: palette.cost,
      ),
      KpiTile(
        icon: Icons.receipt_long_outlined,
        label: 'Valor médio',
        value: Formatters.currency(report.averageRefuelingCost ?? 0),
        caption: 'por abastecimento',
        accent: palette.cost,
      ),
      KpiTile(
        icon: Icons.eco_outlined,
        label: 'Consumo médio',
        value: avgKmL == null ? '—' : Formatters.kmPerLiter(avgKmL),
        caption: avgKmL == null ? 'aguardando 2º registro' : 'no período',
        accent: palette.efficiency,
      ),
      KpiTile(
        icon: Icons.route_outlined,
        label: 'Custo por km',
        value: avgCostKm == null ? '—' : Formatters.costPerKm(avgCostKm),
        caption: avgCostKm == null ? 'aguardando 2º registro' : 'no período',
        accent: palette.costPerKm,
      ),
      KpiTile(
        icon: Icons.straighten_rounded,
        label: 'Distância',
        value: Formatters.km(report.totalDistanceKm),
        caption: 'percorridos',
      ),
      KpiTile(
        icon: Icons.water_drop_outlined,
        label: 'Litros',
        value: Formatters.liters(report.totalLiters),
        caption: 'abastecidos no total',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = switch (constraints.maxWidth) {
          < 520 => 2,
          < 900 => 3,
          _ => 6,
        };
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.value, required this.format});

  final double? value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'média',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          format(value),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
