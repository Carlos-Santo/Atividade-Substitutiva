// Gera as capturas de tela do README a partir do app real, com dados de
// exemplo e as fontes Roboto/Material Icons do SDK do Flutter.
//
// Uso (na raiz do projeto):
//   flutter test --update-goldens --tags screenshots tool/screenshots
//
// As imagens são gravadas em docs/screenshots/.
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tanque_cheio/domain/models/fuel_type.dart';
import 'package:tanque_cheio/ui/vehicle/widgets/catalog_picker_field.dart';

import '../../test/helpers/fakes.dart';
import '../../test/helpers/pump_app.dart';

const _out = '../../docs/screenshots';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT não definido.');
  final dir = '$root/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('$dir/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-light.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

/// Histórico de exemplo: um Fiat Argo rodando ~400–520 km por tanque.
InMemoryRefuelingRepository _sampleHistory() {
  final data = [
    // data, km, litros, preço por litro, combustível
    (DateTime(2026, 8, 4, 18, 20), 32150, 38.2, 5.79, FuelType.gasoline),
    (DateTime(2026, 8, 19, 8, 5), 32610, 37.5, 5.85, FuelType.gasoline),
    (DateTime(2026, 9, 2, 19, 40), 33090, 39.1, 5.89, FuelType.gasoline),
    (DateTime(2026, 9, 18, 12, 10), 33445, 42.0, 3.99, FuelType.ethanol),
    (DateTime(2026, 10, 1, 7, 55), 33790, 41.6, 4.09, FuelType.ethanol),
    (DateTime(2026, 10, 15, 17, 30), 34300, 38.4, 5.99, FuelType.gasoline),
    (DateTime(2026, 10, 30, 9, 15), 34795, 37.9, 6.09, FuelType.gasoline),
    (DateTime(2026, 11, 14, 20), 35310, 39.4, 6.19, FuelType.gasoline),
  ];
  return InMemoryRefuelingRepository([
    for (final (i, (date, km, liters, price, fuel)) in data.indexed)
      refuelingAt(
        id: i + 1,
        km: km,
        liters: liters,
        price: price,
        date: date,
        fuel: fuel,
      ),
  ]);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_out/$name.png'),
  );
}

Future<void> _scrollDown(WidgetTester tester, double offset) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -offset));
  await tester.pumpAndSettle();
}

/// Igual a `testWidgets`, mas com as sombras reais. Nos testes o Flutter
/// troca sombras por contornos sólidos, e a variável precisa voltar ao
/// valor padrão antes do fim de cada teste.
void _screenshotTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
    await _loadFonts();
  });

  _screenshotTest('cadastro do veículo', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(CatalogPickerField, 'Marca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fiat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CatalogPickerField, 'Modelo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'argo');
    await _shot(tester, '02-busca-modelo');

    await tester.tap(find.text('ARGO DRIVE 1.3 8V Flex'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Ano'), '2022');
    FocusManager.instance.primaryFocus?.unfocus();
    await _shot(tester, '01-cadastro-veiculo');
  });

  _screenshotTest('dashboard, lista e formulário', (tester) async {
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: _sampleHistory(),
    );
    await _shot(tester, '03-dashboard');

    await _scrollDown(tester, 640);
    await _shot(tester, '04-dashboard-graficos');

    await _scrollDown(tester, 900);
    await _shot(tester, '05-dashboard-tabela');

    await tester.tap(find.text('Abastecimentos').last);
    await _shot(tester, '06-abastecimentos');

    await tester.tap(find.text('Abastecer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço por litro'),
      '6,19',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Litros abastecidos'),
      '38,6',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quilometragem atual'),
      '35790',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await _shot(tester, '07-novo-abastecimento');
  });

  _screenshotTest('veículo e exclusão', (tester) async {
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: _sampleHistory(),
    );
    await tester.tap(find.text('Veículo'));
    await _shot(tester, '08-veiculo');

    await tester.tap(find.text('Excluir veículo'));
    await _shot(tester, '09-confirmar-exclusao');
  });

  _screenshotTest('tablet e modo escuro', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(
      tester,
      size: tabletSize,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: _sampleHistory(),
    );
    await _shot(tester, '10-tablet-modo-escuro');
  });
}
