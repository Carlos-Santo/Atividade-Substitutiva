import 'package:flutter/widgets.dart';

/// Pontos de quebra de layout, baseados nas "window size classes" do
/// Material 3: compacto (celular), médio (tablet em pé) e expandido.
enum WindowSize {
  compact,
  medium,
  expanded;

  static const mediumMin = 600.0;
  static const expandedMin = 1000.0;

  static WindowSize fromWidth(double width) {
    if (width >= expandedMin) return expanded;
    if (width >= mediumMin) return medium;
    return compact;
  }

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;
}

/// Larguras máximas do conteúdo, para não esticar textos e formulários em
/// telas grandes.
abstract final class ContentWidth {
  static const form = 640.0;
  static const page = 1200.0;
}
