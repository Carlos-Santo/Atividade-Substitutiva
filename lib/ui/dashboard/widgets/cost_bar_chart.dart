import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/formatters.dart';
import 'chart_point.dart';

/// Gráfico de barras com o valor pago em cada abastecimento.
class CostBarChart extends StatelessWidget {
  const CostBarChart({super.key, required this.points, required this.color});

  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final interval = ChartScale.labelInterval(points.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = (constraints.maxWidth - 48) / points.length;
        final barWidth = (slot * 0.6).clamp(4.0, 32.0);

        return BarChart(
          BarChartData(
            maxY: maxValue * 1.15,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        Formatters.decimal(value, digits: 0),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final step = interval.toInt();
                    final previous = index - step;
                    if (index % step != 0 ||
                        (previous >= 0 &&
                            ChartScale.sameDay(
                              points[previous].date,
                              points[index].date,
                            ))) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        Formatters.shortDate(points[index].date),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, _, rod, _) {
                  final point = points[group.x];
                  return BarTooltipItem(
                    'Abastecimento ${point.number}\n',
                    TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                    children: [
                      TextSpan(
                        text: Formatters.currency(point.value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '\n${Formatters.date(point.date)}'),
                    ],
                  );
                },
              ),
            ),
            barGroups: [
              for (final (i, point) in points.indexed)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: point.value,
                      color: color,
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
