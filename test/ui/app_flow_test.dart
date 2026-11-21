import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanque_cheio/core/errors/app_exception.dart';
import 'package:tanque_cheio/ui/dashboard/widgets/cost_bar_chart.dart';
import 'package:tanque_cheio/ui/dashboard/widgets/trend_line_chart.dart';
import 'package:tanque_cheio/ui/vehicle/widgets/catalog_picker_field.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// Abre a folha de busca de marca ou modelo.
Future<void> _openPicker(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(CatalogPickerField, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem veículo, abre o cadastro e leva ao dashboard ao salvar', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Qual é o seu veículo?'), findsOneWidget);

    // Marca e modelo vêm do catálogo (API) e o modelo depende da marca.
    await _openPicker(tester, 'Marca');
    await _tapText(tester, 'Fiat');
    await _openPicker(tester, 'Modelo');
    expect(find.text('ARGO DRIVE 1.3 8V Flex'), findsOneWidget);
    await _tapText(tester, 'ARGO DRIVE 1.3 8V Flex');

    // A cilindrada é sugerida pelo nome do modelo.
    expect(find.text('1300'), findsOneWidget);

    await tester.enterText(_field('Ano'), '2022');
    await _tapText(tester, 'Salvar veículo');

    expect(find.text('Seu painel começa aqui'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('cadastro exige marca, modelo, ano e cilindrada', (tester) async {
    await pumpApp(tester);

    await _tapText(tester, 'Salvar veículo');

    expect(find.text('Selecione a marca'), findsOneWidget);
    expect(find.text('Selecione o modelo'), findsOneWidget);
    expect(find.text('Informe o ano'), findsOneWidget);
    expect(find.text('Informe a cilindrada'), findsOneWidget);
  });

  testWidgets('erro na API mostra a mensagem e permite tentar de novo', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository()
      ..failBrandsWith = const NetworkException();
    await pumpApp(tester, catalog: catalog);

    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);

    catalog.failBrandsWith = null;
    await tester.tap(find.byTooltip('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível conectar'), findsNothing);
    await _openPicker(tester, 'Marca');
    expect(find.text('Fiat'), findsOneWidget);
  });

  testWidgets('registra abastecimentos e mostra indicadores e gráficos', (
    tester,
  ) async {
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: InMemoryRefuelingRepository([
        refuelingAt(km: 10000, liters: 40, date: DateTime(2026, 11)),
      ]),
    );

    // Com um registro só, o consumo ainda não pode ser calculado.
    expect(find.text('aguardando 2º registro'), findsNWidgets(2));
    expect(find.byType(CostBarChart), findsOneWidget);

    await tester.tap(find.byTooltip('Novo abastecimento'));
    await tester.pumpAndSettle();
    expect(find.text('Novo abastecimento'), findsOneWidget);

    await tester.enterText(_field('Preço por litro'), '6');
    await tester.enterText(_field('Litros abastecidos'), '40');
    await tester.pumpAndSettle();
    // Valor total = 6,00 × 40 L, calculado enquanto o usuário digita.
    expect(find.textContaining('240,00'), findsOneWidget);

    await tester.enterText(_field('Quilometragem atual'), '10500');
    await _tapText(tester, 'Registrar abastecimento');

    // De volta ao dashboard: 500 km ÷ 40 L = 12,5 km/L; R$ 240 ÷ 500 km.
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('12,5 km/L'), findsWidgets);
    expect(find.textContaining('0,48/km'), findsWidgets);
    expect(find.byType(TrendLineChart), findsNWidgets(2));
  });

  testWidgets('não aceita quilometragem menor que a do último registro', (
    tester,
  ) async {
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: InMemoryRefuelingRepository([
        refuelingAt(km: 10000, liters: 40, date: DateTime(2026, 11, 2)),
      ]),
    );

    await tester.tap(find.byTooltip('Novo abastecimento'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Preço por litro'), '6');
    await tester.enterText(_field('Litros abastecidos'), '40');
    await tester.enterText(_field('Quilometragem atual'), '9000');
    await _tapText(tester, 'Registrar abastecimento');

    expect(find.textContaining('Deve ser maior que 10.000 km'), findsOneWidget);
    expect(find.text('Novo abastecimento'), findsOneWidget);
  });

  testWidgets('lista mostra referência inicial e permite excluir', (
    tester,
  ) async {
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: InMemoryRefuelingRepository([
        refuelingAt(id: 1, km: 10000, liters: 40, date: DateTime(2026, 11)),
        refuelingAt(id: 2, km: 10400, liters: 32, date: DateTime(2026, 11, 9)),
      ]),
    );

    await tester.tap(find.text('Abastecimentos').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Referência inicial'), findsOneWidget);
    expect(find.text('12,5 km/L'), findsOneWidget);

    await tester.tap(find.byTooltip('Opções').first);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Excluir');
    await _tapText(tester, 'Excluir');

    expect(find.text('12,5 km/L'), findsNothing);
    expect(find.textContaining('1 registro'), findsOneWidget);
  });

  testWidgets('excluir o veículo pede confirmação e volta ao cadastro', (
    tester,
  ) async {
    final refuelings = InMemoryRefuelingRepository([
      refuelingAt(km: 10000, liters: 40, date: DateTime(2026, 11)),
    ]);
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: refuelings,
    );

    await tester.tap(find.text('Veículo'));
    await tester.pumpAndSettle();
    expect(find.text('ARGO DRIVE 1.3 8V Flex'), findsOneWidget);

    await _tapText(tester, 'Excluir veículo');
    expect(find.text('Excluir veículo?'), findsOneWidget);
    expect(find.textContaining('único abastecimento'), findsOneWidget);

    // Cancelar mantém tudo.
    await _tapText(tester, 'Cancelar');
    expect(find.text('ARGO DRIVE 1.3 8V Flex'), findsOneWidget);

    await _tapText(tester, 'Excluir veículo');
    await _tapText(tester, 'Excluir tudo');

    expect(find.text('Qual é o seu veículo?'), findsOneWidget);
    expect(await refuelings.getByVehicle(testVehicle.id!), isEmpty);
  });

  testWidgets('em telas largas usa navegação lateral', (tester) async {
    await pumpApp(
      tester,
      size: tabletSize,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: InMemoryRefuelingRepository([
        refuelingAt(km: 10000, liters: 40, date: DateTime(2026, 11)),
        refuelingAt(km: 10500, liters: 40, date: DateTime(2026, 11, 9)),
      ]),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TrendLineChart), findsNWidgets(2));
  });

  testWidgets('abre o formulário depois de visitar as duas abas', (
    tester,
  ) async {
    // Regressão: os botões flutuantes das abas tinham a mesma heroTag.
    await pumpApp(
      tester,
      vehicles: InMemoryVehicleRepository(initial: testVehicle),
      refuelings: InMemoryRefuelingRepository([
        refuelingAt(km: 10000, liters: 40, date: DateTime(2026, 11)),
      ]),
    );

    await tester.tap(find.text('Abastecimentos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abastecer'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Novo abastecimento'), findsOneWidget);
  });
}
