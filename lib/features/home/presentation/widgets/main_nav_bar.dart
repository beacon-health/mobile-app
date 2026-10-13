import 'package:beacon_app/features/home/presentation/pages/home_page.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/pages/map_page.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Index of each tab in the bottom bar.
abstract final class NavTab {
  static const int home = 0;
  static const int map = 1;
  static const int profile = 2;
  static const int settings = 3;
}

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  int _selectedIndex = 0;
  final PageStorageBucket _bucket = PageStorageBucket();
  final List<Widget> _pages = [];
  final GlobalKey<_MapPageWrapperState> _mapPageKey =
      GlobalKey<_MapPageWrapperState>();

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(
        key: const PageStorageKey('home_page'),
        onNavigateToMap: _handleNavigateToMap,
      ),
      _MapPageWrapper(key: _mapPageKey),
      const ProfilePage(),
      const SettingsPage(),
    ]);
  }

  void _handleNavigateToMap(
    int pageIndex,
    Facility? facility, {
    String? categoryFilter,
  }) {
    setState(() {
      _selectedIndex = pageIndex;
    });

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// A back press the system did not act on, because [PopScope] below said it
  /// couldn't. The tabs aren't routes, so going "back one step" is ours to
  /// define: first whatever is open on the map, then the Home tab.
  void _onBackBlocked() {
    if (_selectedIndex == NavTab.map &&
        (_mapPageKey.currentState?.handleBack() ?? false)) {
      return;
    }
    setState(() => _selectedIndex = NavTab.home);
  }

  @override
  Widget build(BuildContext context) {
    // Only Home lets a back press through, which is what leaves the app —
    // Android's convention for the start tab. Dialogs, sheets, and pushed
    // pages are routes above this one and pop before this is ever asked.
    return PopScope<void>(
      canPop: _selectedIndex == NavTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackBlocked();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          // Colors, type, and label styles come from bottomNavigationBarTheme.
          return BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: l10n?.navHome ?? 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map),
                label: l10n?.navMap ?? 'Map',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: l10n?.navProfile ?? 'Profile',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: l10n?.navSettings ?? 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          );
        },
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

  /// See [MapPageState.handleBack].
  bool handleBack() => _mapPageKey.currentState?.handleBack() ?? false;

  @override
  Widget build(BuildContext context) {
    return MapPage(key: _mapPageKey);
  }
}
