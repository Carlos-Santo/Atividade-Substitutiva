import 'package:flutter/foundation.dart';

/// Item do catálogo FIPE (uma marca ou um modelo).
///
/// [code] é o identificador usado pela API e [name] é o texto exibido.
@immutable
class CatalogItem {
  const CatalogItem({required this.code, required this.name});

  final String code;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CatalogItem && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'CatalogItem($code, $name)';
}
