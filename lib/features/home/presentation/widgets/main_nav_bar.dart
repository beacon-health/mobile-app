import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/home/presentation/pages/home_page.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/pages/map_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapPageKey.currentState?.showFacility(facility);
      });
    } else if (categoryFilter != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapPageKey.currentState?.filterByCategory(categoryFilter);
      });
    } else {
      // Plain "open the map" (e.g. the Home map cutout) — re-center on the
      // user's saved location.
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapPageKey.currentState?.recenterOnUserLocation();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark
                ? Theme.of(context).bottomNavigationBarTheme.backgroundColor
                : AppTheme.honeydew,
            selectedItemColor: AppTheme.bittersweet,
            unselectedItemColor: isDark ? Colors.grey : Colors.black,
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

  @override
  Widget build(BuildContext context) {
    return MapPage(key: _mapPageKey);
  }
}
