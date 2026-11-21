import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/core/formatting/formatters.dart';
import 'package:tanque_cheio/core/formatting/number_input.dart';
import 'package:tanque_cheio/core/formatting/text_search.dart';
import 'package:tanque_cheio/core/validation/validators.dart';

/// Normaliza o espaço especial que o intl usa entre "R$" e o número.
String _plain(String text) => text.replaceAll('\u00A0', ' ');

void main() {
  group('Formatters (pt-BR)', () {
    test('moeda e preço por litro', () {
      expect(_plain(Formatters.currency(1234.5)), r'R$ 1.234,50');
      expect(_plain(Formatters.pricePerLiter(5.899)), r'R$ 5,899');
      expect(_plain(Formatters.costPerKm(0.4812)), r'R$ 0,48/km');
    });

    test('unidades', () {
      expect(Formatters.kmPerLiter(12.345), '12,3 km/L');
      expect(Formatters.km(45200), '45.200 km');
      expect(Formatters.liters(40), '40 L');
      expect(Formatters.liters(40.456), '40,46 L');
      expect(Formatters.displacement(1598), '1.598 cm³');
    });

    test('datas', () {
      final date = DateTime(2026, 11, 20, 14, 5);
      expect(Formatters.date(date), '20/11/2026');
      expect(Formatters.shortDate(date), '20/11');
      expect(Formatters.dateTime(date), '20/11/2026 às 14:05');
    });
  });

  group('NumberInput', () {
    test('aceita vírgula ou ponto como separador decimal', () {
      expect(NumberInput.parseDecimal('5,89'), 5.89);
      expect(NumberInput.parseDecimal(' 5.89 '), 5.89);
      expect(NumberInput.parseDecimal(''), isNull);
      expect(NumberInput.parseDecimal('abc'), isNull);
    });

    test('converte número para texto editável', () {
      expect(NumberInput.toEditableText(5.9), '5,9');
      expect(NumberInput.toEditableText(40), '40');
      expect(NumberInput.toEditableText(5.899), '5,899');
    });

    test('filtro decimal limita casas e caracteres', () {
      final formatter = NumberInput.decimalFormatter(decimals: 3);
      TextEditingValue apply(String old, String typed) =>
          formatter.formatEditUpdate(
            TextEditingValue(text: old),
            TextEditingValue(text: typed),
          );

      expect(apply('5,89', '5,899').text, '5,899');
      expect(apply('5,899', '5,8991').text, '5,899');
      expect(apply('5', '5a').text, '5');
      expect(apply('5,8', '5,8,').text, '5,8');
    });
  });

  group('TextSearch', () {
    test('ignora acentos, maiúsculas e ordem das palavras', () {
      expect(TextSearch.matches('Citroën', 'citroen'), isTrue);
      expect(TextSearch.matches('ARGO DRIVE 1.3 8V Flex', 'argo flex'), isTrue);
      expect(TextSearch.matches('ARGO DRIVE 1.3 8V Flex', 'flex argo'), isTrue);
      expect(TextSearch.matches('ARGO DRIVE 1.3 8V Flex', 'mobi'), isFalse);
      expect(TextSearch.matches('Qualquer', '   '), isTrue);
    });
  });

  group('Validators', () {
    test('ano', () {
      final now = DateTime(2026, 11, 20);
      expect(Validators.year('', now: now), isNotNull);
      expect(Validators.year('1899', now: now), isNotNull);
      expect(Validators.year('2028', now: now), isNotNull);
      expect(Validators.year('2027', now: now), isNull);
      expect(Validators.year('2015', now: now), isNull);
    });

    test('cilindrada', () {
      expect(Validators.displacement(''), isNotNull);
      expect(Validators.displacement('49'), isNotNull);
      expect(Validators.displacement('1000'), isNull);
    });

    test('preço, litros e quilometragem', () {
      expect(Validators.pricePerLiter('0'), isNotNull);
      expect(Validators.pricePerLiter('5,89'), isNull);
      expect(Validators.liters(''), isNotNull);
      expect(Validators.liters('40,5'), isNull);
      expect(Validators.odometer(''), isNotNull);
      expect(Validators.odometer('0'), isNull);
    });
  });
}
