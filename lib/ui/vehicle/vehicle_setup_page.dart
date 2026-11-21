import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatting/number_input.dart';
import '../../core/validation/validators.dart';
import '../../data/repositories/vehicle_catalog_repository.dart';
import '../../domain/models/vehicle_type.dart';
import '../core/layout/breakpoints.dart';
import '../core/presentation.dart';
import '../core/widgets/constrained_content.dart';
import '../core/widgets/feedback.dart';
import '../garage/garage_view_model.dart';
import 'vehicle_form_view_model.dart';
import 'widgets/catalog_picker_field.dart';

/// Tela de cadastro do veículo. Aparece sempre que não há veículo salvo.
class VehicleSetupPage extends StatelessWidget {
  const VehicleSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          VehicleFormViewModel(context.read<VehicleCatalogRepository>())
            ..loadBrands(),
      child: const _VehicleSetupView(),
    );
  }
}

class _VehicleSetupView extends StatefulWidget {
  const _VehicleSetupView();

  @override
  State<_VehicleSetupView> createState() => _VehicleSetupViewState();
}

class _VehicleSetupViewState extends State<_VehicleSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _displacementController = TextEditingController();
  bool _saving = false;

  /// Indica se a cilindrada foi preenchida pela sugestão do modelo. Nesse
  /// caso, trocar de modelo atualiza o valor; se o usuário digitou, não.
  bool _displacementWasSuggested = false;

  @override
  void dispose() {
    _yearController.dispose();
    _displacementController.dispose();
    super.dispose();
  }

  void _applyDisplacementSuggestion(VehicleFormViewModel form) {
    final suggestion = form.suggestedDisplacementCc;
    final canOverwrite =
        _displacementController.text.isEmpty || _displacementWasSuggested;
    if (!canOverwrite) return;
    _displacementController.text = suggestion?.toString() ?? '';
    _displacementWasSuggested = suggestion != null;
  }

  Future<void> _submit() async {
    final form = context.read<VehicleFormViewModel>();
    if (!_formKey.currentState!.validate()) return;
    final vehicle = form.buildVehicle(
      year: NumberInput.parseInt(_yearController.text)!,
      displacementCc: NumberInput.parseInt(_displacementController.text)!,
    );
    if (vehicle == null) return;

    setState(() => _saving = true);
    try {
      await context.read<GarageViewModel>().registerVehicle(vehicle);
      // O roteador leva ao dashboard assim que o veículo existe.
    } catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<VehicleFormViewModel>();
    final theme = Theme.of(context);
    final compact = WindowSize.of(context).isCompact;

    final yearField = TextFormField(
      controller: _yearController,
      decoration: const InputDecoration(
        labelText: 'Ano',
        prefixIcon: Icon(Icons.calendar_today_rounded),
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [NumberInput.digitsOnly],
      maxLength: 4,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: Validators.year,
    );

    final displacementField = TextFormField(
      controller: _displacementController,
      decoration: const InputDecoration(
        labelText: 'Cilindrada',
        suffixText: 'cm³',
        prefixIcon: Icon(Icons.speed_rounded),
        helperText: 'Ex.: 1.0 = 1000 cm³',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [NumberInput.digitsOnly],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: Validators.displacement,
      onChanged: (_) => _displacementWasSuggested = false,
      onFieldSubmitted: (_) => _submit(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ConstrainedContent(
                maxWidth: ContentWidth.form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Qual é o seu veículo?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marcas e modelos vêm da tabela FIPE. '
                      'Depois é só registrar os abastecimentos.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<VehicleType>(
                      segments: [
                        for (final type in VehicleType.values)
                          ButtonSegment(
                            value: type,
                            label: Text(type.label),
                            icon: Icon(type.icon),
                          ),
                      ],
                      selected: {form.type},
                      showSelectedIcon: false,
                      onSelectionChanged: _saving
                          ? null
                          : (selection) {
                              form.selectType(selection.first);
                              _applyDisplacementSuggestion(form);
                            },
                    ),
                    const SizedBox(height: 20),
                    CatalogPickerField(
                      label: 'Marca',
                      icon: Icons.factory_rounded,
                      options: form.brands,
                      value: form.brand,
                      requiredMessage: 'Selecione a marca',
                      searchHint: 'Buscar marca',
                      onRetry: form.loadBrands,
                      onSelected: (brand) {
                        form.selectBrand(brand);
                        _applyDisplacementSuggestion(form);
                      },
                    ),
                    const SizedBox(height: 16),
                    CatalogPickerField(
                      label: 'Modelo',
                      icon: Icons.directions_car_rounded,
                      options: form.models,
                      value: form.model,
                      idleHint: 'Escolha a marca primeiro',
                      requiredMessage: 'Selecione o modelo',
                      searchHint: 'Buscar modelo (ex.: "onix 1.0")',
                      onRetry: form.loadModels,
                      onSelected: (model) {
                        form.selectModel(model);
                        _applyDisplacementSuggestion(form);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (compact) ...[
                      yearField,
                      const SizedBox(height: 16),
                      displacementField,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: yearField),
                          const SizedBox(width: 16),
                          Expanded(child: displacementField),
                        ],
                      ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Salvar veículo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
