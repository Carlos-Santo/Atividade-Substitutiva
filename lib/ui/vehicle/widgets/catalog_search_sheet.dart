import 'package:flutter/material.dart';

import '../../../core/formatting/text_search.dart';
import '../../../domain/models/catalog_item.dart';

/// Abre a folha de busca e devolve o item escolhido (ou nulo se fechar).
Future<CatalogItem?> showCatalogSearchSheet(
  BuildContext context, {
  required String title,
  required List<CatalogItem> items,
  CatalogItem? selected,
  String searchHint = 'Buscar',
}) {
  return showModalBottomSheet<CatalogItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: CatalogSearchSheet(
        title: title,
        items: items,
        selected: selected,
        searchHint: searchHint,
      ),
    ),
  );
}

/// Lista com busca instantânea, que ignora acentos e maiúsculas.
class CatalogSearchSheet extends StatefulWidget {
  const CatalogSearchSheet({
    super.key,
    required this.title,
    required this.items,
    this.selected,
    this.searchHint = 'Buscar',
  });

  final String title;
  final List<CatalogItem> items;
  final CatalogItem? selected;
  final String searchHint;

  @override
  State<CatalogSearchSheet> createState() => _CatalogSearchSheetState();
}

class _CatalogSearchSheetState extends State<CatalogSearchSheet> {
  String _query = '';

  List<CatalogItem> get _filtered => _query.isEmpty
      ? widget.items
      : widget.items
            .where((item) => TextSearch.matches(item.name, _query))
            .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(widget.title, style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              '${results.length} de ${widget.items.length} opções',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nenhum resultado para "$_query".',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final isSelected = item == widget.selected;
                      return ListTile(
                        title: Text(item.name),
                        selected: isSelected,
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
