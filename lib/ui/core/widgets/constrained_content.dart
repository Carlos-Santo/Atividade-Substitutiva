import 'package:flutter/material.dart';

/// Centraliza o conteúdo e limita sua largura em telas grandes, mantendo
/// margens confortáveis no celular.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.maxWidth,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
