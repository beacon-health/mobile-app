import 'dart:async';

import 'package:beacon_app/features/ask/data/assistant_service.dart';
import 'package:beacon_app/features/ask/domain/ask_request.dart';
import 'package:beacon_app/features/ask/presentation/pages/ask_page.dart';
import 'package:beacon_app/features/home/presentation/pages/home_page.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/pages/map_page.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The tabs, in bar order. Ask is the middle one, and is only in the bar on
/// phones with a language model it can use.
enum AppTab { home, map, ask, profile, settings }

/// Position of the two tabs whose place in the bar never changes.
abstract final class NavTab {
  static const int home = 0;
  static const int map = 1;
}

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  AppTab _selected = AppTab.home;
  final PageStorageBucket _bucket = PageStorageBucket();
  final List<Widget> _pages = [];
  final GlobalKey<_MapPageWrapperState> _mapPageKey =
      GlobalKey<_MapPageWrapperState>();

  @override
  void initState() {
    super.initState();
    // One page per AppTab, in enum order. All five are always built, so a
    // tab keeps its state even while Ask comes and goes from the bar.
    _pages.addAll([
      HomePage(
        key: const PageStorageKey('home_page'),
        onNavigateToMap: _handleNavigateToMap,
      ),
      _MapPageWrapper(key: _mapPageKey),
      AskPage(
        onOpenMap: _openMapWithFilters,
        onShowFacility: (facility) =>
            _handleNavigateToMap(NavTab.map, facility),
      ),
      const ProfilePage(),
      const SettingsPage(),
    ]);
  }

  /// Ask couldn't answer, or the person asked to see its results on the map.
  void _openMapWithFilters(AskFilters filters) {
    setState(() => _selected = AppTab.map);
    Future.delayed(MapConstants.navSettleDelay, () {
      _mapPageKey.currentState?.applyFilters(filters);
    });
  }

  void _handleNavigateToMap(
    int pageIndex,
    Facility? facility, {
    String? categoryFilter,
  }) {
    setState(() => _selected = AppTab.map);

    if (facility != null) {
      Future.delayed(MapConstants.navSettleDelay, () {
        _mapPageKey.currentState?.showFacility(facility);
      });
    } else if (categoryFilter != null) {
      Future.delayed(MapConstants.navSettleDelay, () {
        _mapPageKey.currentState?.filterByCategory(categoryFilter);
      });
    } else {
      // Plain "open the map" (e.g. the Home map cutout) — re-center on the
      // user's saved location.
      Future.delayed(MapConstants.navSettleDelay, () {
        _mapPageKey.currentState?.recenterOnUserLocation();
      });
    }
  }

  /// A back press the system did not act on, because [PopScope] below said it
  /// couldn't. The tabs aren't routes, so going "back one step" is ours to
  /// define: first whatever is open on the map, then the Home tab.
  void _onBackBlocked() {
    if (_selected == AppTab.map &&
        (_mapPageKey.currentState?.handleBack() ?? false)) {
      return;
    }
    setState(() => _selected = AppTab.home);
  }

  @override
  Widget build(BuildContext context) {
    // Only Home lets a back press through, which is what leaves the app —
    // Android's convention for the start tab. Dialogs, sheets, and pushed
    // pages are routes above this one and pop before this is ever asked.
    return PopScope<void>(
      canPop: _selected == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackBlocked();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showAsk = context.watch<AssistantService>().showsTab;
    final tabs = [
      for (final tab in AppTab.values)
        if (tab != AppTab.ask || showAsk) tab,
    ];
    // The Ask tab left the bar while it was open (the app's language changed
    // to one the model doesn't speak, say).
    if (!tabs.contains(_selected)) _selected = AppTab.home;

    NavigationDestination destination(AppTab tab) => switch (tab) {
          AppTab.home => NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
          AppTab.map => NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: l10n.navMap,
            ),
          AppTab.ask => NavigationDestination(
              icon: const Icon(Icons.forum_outlined),
              selectedIcon: const Icon(Icons.forum),
              label: l10n.navAsk,
            ),
          AppTab.profile => NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          AppTab.settings => NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
        };

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _selected.index,
          children: _pages,
        ),
      ),
      // Colors, the indicator pill, and label styles come from
      // navigationBarTheme. Each tab pairs an outlined icon with a filled
      // one, so the active tab differs in shape as well as color.
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: tabs.indexOf(_selected),
          onDestinationSelected: (index) {
            setState(() => _selected = tabs[index]);
            // Opening Ask is the moment to ask the phone again whether its
            // model has finished getting ready.
            if (tabs[index] == AppTab.ask) {
              unawaited(AssistantService().refresh());
            }
          },
          destinations: [for (final tab in tabs) destination(tab)],
        ),
      ),
    );
  }
}

class _MapPageWrapper extends StatefulWidget {
  const _MapPageWrapper({super.key});

  @override
  State<_MapPageWrapper> createState() => _MapPageWrapperState();
}

class _MapPageWrapperState extends State<_MapPageWrapper> {
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

  void showFacility(Facility facility) {
    // Pass the full object so the map can center even on out-of-region
    // favorites (it no longer holds the whole dataset in memory).
    _mapPageKey.currentState?.showFacility(facility);
  }

  void filterByCategory(String category) {
    _mapPageKey.currentState?.filterByCategory(category);
  }

  void recenterOnUserLocation() {
    _mapPageKey.currentState?.recenterOnUserLocation();
  }

  void applyFilters(AskFilters filters) {
    _mapPageKey.currentState?.applyFilters(
      categories: filters.categories,
      openNow: filters.openNow,
      preferences: filters.preferences,
      searchText: filters.keyword,
    );
  }

  /// See [MapPageState.handleBack].
  bool handleBack() => _mapPageKey.currentState?.handleBack() ?? false;

  @override
  Widget build(BuildContext context) {
    return MapPage(key: _mapPageKey);
  }
}
