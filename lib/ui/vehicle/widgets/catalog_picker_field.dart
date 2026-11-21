import 'package:flutter/material.dart';

import '../../../domain/models/catalog_item.dart';
import '../../core/load_state.dart';
import 'catalog_search_sheet.dart';

/// Campo de formulário para escolher uma marca ou um modelo.
///
/// As listas da FIPE são longas (centenas de modelos), então o campo abre
/// uma folha com busca em vez de um dropdown simples. Também mostra o
/// carregamento e os erros da API, com a opção de tentar de novo.
class CatalogPickerField extends StatelessWidget {
  const CatalogPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onSelected,
    required this.onRetry,
    required this.requiredMessage,
    this.idleHint,
    this.searchHint = 'Buscar',
  });

  final String label;
  final IconData icon;
  final LoadState<List<CatalogItem>> options;
  final CatalogItem? value;
  final ValueChanged<CatalogItem> onSelected;
  final VoidCallback onRetry;
  final String requiredMessage;

  /// Texto exibido enquanto o campo ainda não pode ser usado.
  final String? idleHint;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    return FormField<CatalogItem>(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) => value == null ? requiredMessage : null,
      builder: (field) {
        final scheme = Theme.of(context).colorScheme;
        final (hint, suffix, errorText, enabled) = switch (options) {
          Idle() => (idleHint, null, null, false),
          Loading() => (
            'Carregando…',
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
            null,
            false,
          ),
          LoadFailed(:final error) => (
            null,
            IconButton(
              tooltip: 'Tentar novamente',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRetry,
            ),
            error.message,
            false,
          ),
          Loaded() => (
            'Selecione',
            const Icon(Icons.unfold_more_rounded),
            null,
            true,
          ),
        };

        Future<void> open() async {
          final items = options.dataOrNull;
          if (items == null) return;
          final selected = await showCatalogSearchSheet(
            context,
            title: label,
            items: items,
            selected: value,
            searchHint: searchHint,
          );
          if (selected != null) {
            onSelected(selected);
            field.didChange(selected);
          }
        }

        return Semantics(
          button: enabled,
          label: label,
          value: value?.name,
          child: InkWell(
            onTap: enabled ? open : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              isEmpty: value == null,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon),
                suffixIcon: suffix,
                errorText: field.errorText ?? errorText,
                errorMaxLines: 3,
                enabled: enabled || options is LoadFailed,
              ),
              child: Text(
                value?.name ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        );
      },
    );
  }
}
