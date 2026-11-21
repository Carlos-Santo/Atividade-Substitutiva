import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/breakpoints.dart';

/// Estrutura com a navegação principal entre as abas.
///
/// No celular usa a barra inferior (NavigationBar); em tablets e telas
/// largas troca por uma barra lateral (NavigationRail), que aproveita melhor
/// o espaço horizontal.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Dashboard',
    ),
    (
      icon: Icons.local_gas_station_outlined,
      selectedIcon: Icons.local_gas_station_rounded,
      label: 'Abastecimentos',
    ),
    (
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car_rounded,
      label: 'Veículo',
    ),
  ];

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    // Tocar na aba atual volta ao início dela.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final index = navigationShell.currentIndex;

    if (size.isCompact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _onSelect,
              extended: size == WindowSize.expanded,
              labelType: size == WindowSize.expanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
