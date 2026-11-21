import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/domain/models/odometer_range.dart';

import '../helpers/fakes.dart';

void main() {
  final history = [
    refuelingAt(id: 1, km: 1000, liters: 40, date: DateTime(2026)),
    refuelingAt(id: 2, km: 1500, liters: 40, date: DateTime(2026, 1, 10)),
    refuelingAt(id: 3, km: 2000, liters: 40, date: DateTime(2026, 1, 20)),
  ];

  test('sem histórico qualquer quilometragem é válida', () {
    final range = OdometerRange.forDate(const [], DateTime(2026));
    expect(range.contains(0), isTrue);
    expect(range.minExclusive, isNull);
    expect(range.maxExclusive, isNull);
  });

  test('novo abastecimento depois do último deve ter km maior', () {
    final range = OdometerRange.forDate(history, DateTime(2026, 2));
    expect(range.previous?.id, 3);
    expect(range.next, isNull);
    expect(range.contains(2000), isFalse);
    expect(range.contains(2001), isTrue);
  });

  test('abastecimento retroativo fica entre os vizinhos', () {
    final range = OdometerRange.forDate(history, DateTime(2026, 1, 15));
    expect(range.minExclusive, 1500);
    expect(range.maxExclusive, 2000);
    expect(range.contains(1500), isFalse);
    expect(range.contains(1750), isTrue);
    expect(range.contains(2000), isFalse);
  });

  test('abastecimento antes do primeiro deve ter km menor', () {
    final range = OdometerRange.forDate(history, DateTime(2025, 12));
    expect(range.previous, isNull);
    expect(range.maxExclusive, 1000);
    expect(range.contains(999), isTrue);
    expect(range.contains(1000), isFalse);
  });

  test('ao editar, o próprio registro é ignorado', () {
    final range = OdometerRange.forDate(
      history,
      DateTime(2026, 1, 10),
      ignoreId: 2,
    );
    expect(range.minExclusive, 1000);
    expect(range.maxExclusive, 2000);
    expect(range.contains(1500), isTrue);
  });
}
