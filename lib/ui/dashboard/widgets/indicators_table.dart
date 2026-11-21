import 'package:flutter/material.dart';

import '../../../core/formatting/formatters.dart';
import '../../../domain/models/consumption_report.dart';
import '../../../domain/models/refueling_insight.dart';

/// Tabela com os indicadores de cada abastecimento: valor, distância,
/// km/L e R$/km. Complementa os gráficos com os números exatos.
///
/// Em telas estreitas usa uma versão compacta (data curta, unidades no
/// cabeçalho) para que todas as colunas caibam sem rolagem lateral.
class IndicatorsTable extends StatelessWidget {
  const IndicatorsTable({super.key, required this.report});

  /// Abaixo desta largura a tabela usa o modo compacto.
  static const compactBelow = 560.0;

  final ConsumptionReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Indicadores por abastecimento',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'O primeiro registro é a referência inicial, por isso não tem '
              'km/L nem R\$/km.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < compactBelow;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: _buildTable(context, compact: compact),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DataTable _buildTable(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final count = report.count;

    Widget value(String? text) =>
        text == null ? Text('—', style: muted) : Text(text);

    DataRow row(int number, RefuelingInsight entry) {
      final r = entry.refueling;
      final distance = entry.distanceKm;
      final kmPerLiter = entry.kmPerLiter;
      final costPerKm = entry.costPerKm;
      return DataRow(
        cells: [
          DataCell(Text('$number')),
          DataCell(
            Text(
              compact
                  ? Formatters.compactDate(r.date)
                  : Formatters.date(r.date),
            ),
          ),
          DataCell(Text(Formatters.currency(r.totalCost))),
          DataCell(
            value(
              distance == null
                  ? null
                  : compact
                  ? Formatters.integer(distance)
                  : Formatters.km(distance),
            ),
          ),
          DataCell(
            value(
              kmPerLiter == null
                  ? null
                  : Formatters.decimal(kmPerLiter, digits: 1),
            ),
          ),
          DataCell(
            value(costPerKm == null ? null : Formatters.decimal(costPerKm)),
          ),
        ],
      );
    }

    return DataTable(
      columnSpacing: compact ? 14 : 24,
      horizontalMargin: compact ? 12 : 16,
      headingTextStyle: theme.textTheme.labelLarge,
      columns: [
        const DataColumn(label: Text('Nº'), numeric: true),
        const DataColumn(label: Text('Data')),
        const DataColumn(label: Text('Valor'), numeric: true),
        DataColumn(label: Text(compact ? 'km' : 'Distância'), numeric: true),
        const DataColumn(label: Text('km/L'), numeric: true),
        const DataColumn(label: Text(r'R$/km'), numeric: true),
      ],
      rows: [
        for (final (i, entry) in report.newestFirst.indexed)
          row(count - i, entry),
      ],
    );
  }
}
