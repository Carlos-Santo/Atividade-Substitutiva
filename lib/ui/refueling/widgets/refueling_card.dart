import 'package:flutter/material.dart';

import '../../../core/formatting/formatters.dart';
import '../../../domain/models/refueling_insight.dart';
import '../../core/presentation.dart';
import '../../core/theme/chart_palette.dart';

enum RefuelingAction { edit, delete }

/// Card de um abastecimento na lista, com os dados digitados e os
/// indicadores calculados em relação ao abastecimento anterior.
class RefuelingCard extends StatelessWidget {
  const RefuelingCard({
    super.key,
    required this.insight,
    required this.onAction,
  });

  final RefuelingInsight insight;
  final ValueChanged<RefuelingAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final refueling = insight.refueling;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onAction(RefuelingAction.edit),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    child: Icon(refueling.fuelType.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refueling.fuelType.label,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          Formatters.dateTime(refueling.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(refueling.totalCost),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PopupMenuButton<RefuelingAction>(
                    tooltip: 'Opções',
                    onSelected: onAction,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: RefuelingAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: RefuelingAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _Detail(
                      icon: Icons.water_drop_outlined,
                      text: Formatters.liters(refueling.liters),
                    ),
                    _Detail(
                      icon: Icons.sell_outlined,
                      text:
                          '${Formatters.pricePerLiter(refueling.pricePerLiter)}/L',
                    ),
                    _Detail(
                      icon: Icons.speed_rounded,
                      text: Formatters.km(refueling.odometerKm),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _Indicators(insight: insight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.insight});

  final RefuelingInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = ChartPalette.of(context);

    if (!insight.hasIndicators) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Referência inicial: o consumo é calculado a partir do '
                  'próximo abastecimento.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        _Metric(
          label: 'Rodados',
          value: '+${Formatters.km(insight.distanceKm!)}',
          color: scheme.outline,
        ),
        _Metric(
          label: 'Consumo',
          value: Formatters.kmPerLiter(insight.kmPerLiter!),
          color: palette.efficiency,
        ),
        _Metric(
          label: 'Custo',
          value: Formatters.costPerKm(insight.costPerKm!),
          color: palette.costPerKm,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;

  /// Cor da métrica nos gráficos. Aparece só na marca lateral; o texto fica
  /// na cor padrão para manter a legibilidade.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(left: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
