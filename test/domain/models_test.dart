import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/domain/models/displacement_hint.dart';
import 'package:tanque_cheio/domain/models/refueling.dart';

import '../helpers/fakes.dart';

void main() {
  group('Refueling.totalCost', () {
    test('multiplica preço por litros', () {
      final r = refuelingAt(
        km: 1,
        liters: 40,
        price: 5.899,
        date: DateTime(2026),
      );
      expect(r.totalCost, 235.96);
    });

    test('arredonda para centavos', () {
      final r = refuelingAt(
        km: 1,
        liters: 33.333,
        price: 5.999,
        date: DateTime(2026),
      );
      // 33,333 × 5,999 = 199,964667 → 199,96
      expect(r.totalCost, 199.96);
    });
  });

  test('ordem cronológica desempata pela quilometragem', () {
    final sameTime = DateTime(2026, 5, 5, 10);
    final a = refuelingAt(id: 2, km: 500, liters: 1, date: sameTime);
    final b = refuelingAt(id: 1, km: 400, liters: 1, date: sameTime);
    final c = refuelingAt(id: 3, km: 100, liters: 1, date: DateTime(2026));

    expect(([a, b, c]..sort(Refueling.chronological)).map((r) => r.id), [
      3,
      1,
      2,
    ]);
  });

  group('DisplacementHint', () {
    test('extrai a cilindrada em litros do nome do modelo', () {
      expect(DisplacementHint.fromModelName('ARGO DRIVE 1.3 8V Flex'), 1300);
      expect(DisplacementHint.fromModelName('Gol 1.6 Flex'), 1600);
      expect(DisplacementHint.fromModelName('Onix Hatch LT 1,0 12V'), 1000);
    });

    test('não sugere quando não há cilindrada reconhecível', () {
      expect(DisplacementHint.fromModelName('CG 160 TITAN Flex'), isNull);
      expect(DisplacementHint.fromModelName('147 C/ CL'), isNull);
      // Versões como "2.0.1" não são cilindrada.
      expect(DisplacementHint.fromModelName('Modelo 2.0.1'), isNull);
    });
  });
}
