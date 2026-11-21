/// Busca textual tolerante a acentos e maiúsculas.
///
/// Exemplo: "citroen" encontra "Citroën" e "caminhao" encontra "Caminhão".
abstract final class TextSearch {
  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Verdadeiro se todas as palavras da [query] aparecem em [text], em
  /// qualquer ordem. Assim "argo 1.0" encontra "ARGO DRIVE 1.0 6V Flex".
  static bool matches(String text, String query) {
    final terms = normalize(query).split(' ').where((t) => t.isNotEmpty);
    if (terms.isEmpty) return true;
    final haystack = normalize(text);
    return terms.every(haystack.contains);
  }
}
