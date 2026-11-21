import 'package:flutter/material.dart';

/// Moldura padrão dos gráficos: título, legenda curta e área do gráfico.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
    this.trailing,
    this.height = 220,
  });

  final String title;
  final String subtitle;

  /// Cor da série, mostrada como marcador ao lado do título.
  final Color color;
  final Widget child;

  /// Valor de destaque à direita do título (por exemplo, a média).
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

/// Texto exibido no lugar do gráfico quando ainda não há dados suficientes.
class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_rounded,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
