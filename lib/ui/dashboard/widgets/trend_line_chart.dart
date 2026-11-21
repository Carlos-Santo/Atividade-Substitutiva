import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/formatters.dart';
import 'chart_point.dart';

/// Gráfico de linha com a evolução de uma métrica ao longo dos
/// abastecimentos, com uma linha tracejada na média.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    required this.color,
    required this.formatValue,
    required this.axisDecimals,
    this.average,
  });

  final List<ChartPoint> points;
  final Color color;

  /// Formata o valor no tooltip (por exemplo, "12,4 km/L").
  final String Function(double value) formatValue;

  /// Casas decimais dos rótulos do eixo Y.
  final int axisDecimals;

  /// Média do período, desenhada como referência.
  final double? average;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final values = [...points.map((p) => p.value), ?average];
    final yRange = ChartScale.paddedRange(values);
    final byNumber = {for (final p in points) p.number: p};
    final first = points.first.number.toDouble();
    final last = points.last.number.toDouble();
    // Com um ponto só, abre espaço dos dois lados para ele ficar no centro.
    final minX = first == last ? first - 1 : first;
    final maxX = first == last ? last + 1 : last;
    final interval = ChartScale.labelInterval(points.length);

    // Respiro à direita para o último rótulo do eixo X não encostar na borda.
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: yRange.min,
          maxY: yRange.max,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          extraLinesData: average == null
              ? null
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average!,
                      color: scheme.outline,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: labelStyle,
                        labelResolver: (_) => 'média',
                      ),
                    ),
                  ],
                ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatters.decimal(value, digits: axisDecimals),
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
                interval: interval,
                getTitlesWidget: (value, meta) {
                  final point = byNumber[value.toInt()];
                  if (point == null || value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatters.shortDate(point.date),
                      style: labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    'Abastecimento ${spot.x.toInt()}\n',
                    TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                    children: [
                      TextSpan(
                        text: formatValue(spot.y),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            '\n${Formatters.date(byNumber[spot.x.toInt()]!.date)}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final p in points) FlSpot(p.number.toDouble(), p.value),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: scheme.surfaceContainerLow,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
