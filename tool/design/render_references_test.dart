// Renders the real Flutter widgets and screens to PNG for the Claude Design
// project's reference cards. Not part of `flutter test` (it lives outside
// test/); run it through tool/build_design_bundle.dart, or directly:
//
//   flutter test tool/design/render_references_test.dart
//
// Unlike the golden tests, this loads the real fonts (Inter, Material Icons,
// and the platform fonts the sign-in buttons use) and keeps real shadows, so
// the images look like the app on a device.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/coverage_notice.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/core/widgets/empty_state.dart';
import 'package:beacon_app/core/widgets/section_header.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/selection_chip_builder.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/pump_app.dart';
import '../../test/helpers/test_facility.dart';

const _outDir = 'build/design_references';

Future<void> _loadFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }

  // The sign-in buttons use the platform fonts on purpose (brand rules).
  Future<void> loadFile(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
    await loadFile(
        AppTypography.googleButtonFontFamily, '$dir/Roboto-Medium.ttf');
  }
  await loadFile(
    AppTypography.appleButtonFontFamily,
    '/System/Library/Fonts/SFNS.ttf',
  );
}

/// Pumps [build] at [size], renders it at 2x with real shadows, and writes
/// `<name>.png`. Screens fill the phone; components are cropped to their
/// content ([fullScreen] false).
Future<void> _render(
  WidgetTester tester,
  String name,
  Widget Function() build, {
  Brightness brightness = Brightness.light,
  Size size = phoneSize,
  bool fullScreen = true,
}) async {
  final key = GlobalKey();
  final content = RepaintBoundary(key: key, child: build());
  debugDisableShadows = false;
  EditableText.debugDeterministicCursor = true;
  try {
    await pumpThemed(
      tester,
      fullScreen
          ? content
          : Align(alignment: Alignment.topCenter, child: content),
      brightness: brightness,
      size: size,
    );
    await precacheImages(tester);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = true;
    EditableText.debugDeterministicCursor = false;
  }
}

void _writePng(String name, Uint8List bytes) {
  File('$_outDir/$name')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

/// The circle of a facility pin bitmap, without the (empty) name area.
Future<Uint8List> _cropPin(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  const side = MarkerUtils.facilityMarkerCircleSize;
  final left = (image.width - side) / 2;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(left, 0, side, side),
    const Rect.fromLTWH(0, 0, side, side),
    Paint(),
  );
  final cropped =
      await recorder.endRecording().toImage(side.toInt(), side.toInt());
  final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// The map's pin and cluster bitmaps, exactly as the app draws them, for the
/// Claude Design map kit.
const _pinCategories = <String, String?>{
  'health-care': FacilityCategories.groupHealthCare,
  'mental-health': FacilityCategories.groupMentalHealth,
  'basic-needs': FacilityCategories.groupBasicNeeds,
  'housing-shelter': FacilityCategories.groupHousingShelter,
  'community-resources': FacilityCategories.groupCommunity,
  'specialized-services': FacilityCategories.groupSpecialized,
  'fallback': null,
};

/// A component sample on the page background, padded like a screen and
/// shrink-wrapped to its content.
class _Sample extends StatelessWidget {
  const _Sample({required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.pageGutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

Widget _label(String text) => Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );

Widget _row(List<Widget> children) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

final _components = <String, Widget Function()>{
  'buttons': () => _Sample(
        children: [
          _label('PRIMARY — ElevatedButton / FilledButton'),
          ElevatedButton(onPressed: () {}, child: const Text('Apply filters')),
          _label('ONBOARDING CTA — secondaryFilledButton'),
          Builder(
            builder: (context) => FilledButton(
              onPressed: () {},
              style: AppTheme.secondaryFilledButton(context),
              child: const Text('Continue'),
            ),
          ),
          _label('SECONDARY — OutlinedButton'),
          OutlinedButton(onPressed: () {}, child: const Text('Clear all')),
          _label('TEXT AND DESTRUCTIVE — TextButton'),
          _row([
            TextButton(onPressed: () {}, child: const Text('Select language')),
            Builder(
              builder: (context) => TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
              ),
            ),
          ]),
          _label('DISABLED'),
          const ElevatedButton(onPressed: null, child: Text('Continue')),
        ],
      ),
  'chips': () => _Sample(
        children: [
          _label('TAGCHIP — category or role color, optional icon'),
          _row(const [
            TagChip(
              label: 'Walk-ins',
              color: AppColors.healthCare,
              icon: Icons.directions_walk,
            ),
            TagChip(
              label: 'Telehealth',
              color: AppColors.mentalHealth,
              icon: Icons.videocam,
            ),
            TagChip(label: 'Food pantry', color: AppColors.basicNeeds),
            TagChip(label: 'Shelter', color: AppColors.housingShelter),
            TagChip(label: 'Approved', color: AppColors.resedaGreen),
          ]),
          _label('FILTER BAR CHIPS — default, selected, dropdown, locked'),
          _row([
            CustomFilterChip(
              label: 'Open Now',
              isSelected: false,
              hasDropdown: false,
              onTap: () {},
            ),
            CustomFilterChip(
              label: 'Favorites',
              isSelected: true,
              hasDropdown: false,
              onTap: () {},
            ),
            CustomFilterChip(
              label: 'Category',
              isSelected: false,
              hasDropdown: true,
              onTap: () {},
            ),
            CustomFilterChip(
              label: 'Preferences',
              isSelected: false,
              hasDropdown: true,
              isLocked: true,
              onTap: () {},
            ),
          ]),
          _label('SELECTION TILES — filter options, Yes / No toggles'),
          _row(const [
            SelectionTile(
              label: 'Medical Care',
              selected: true,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            SelectionTile(
              label: 'Food',
              selected: false,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ]),
        ],
      ),
  'lists': () => _Sample(
        children: [
          const SectionHeader('Account'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  trailing: Text('English'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.my_location),
                  title: const Text('Use My Location'),
                  subtitle: const Text('Use GPS instead of ZIP code'),
                  value: true,
                  onChanged: (_) {},
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.directions_outlined),
                  title: Text('Directions app'),
                  trailing: Text('Ask each time'),
                ),
              ],
            ),
          ),
          _label('TEXT FIELD'),
          const TextField(
            decoration: InputDecoration(labelText: 'Facility name'),
          ),
          _label('DIALOG'),
          AlertDialog(
            title: const Text('Sign out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(onPressed: () {}, child: const Text('Cancel')),
              FilledButton(onPressed: () {}, child: const Text('Sign out')),
            ],
          ),
        ],
      ),
  'facility_card': () => _Sample(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          for (final expanded in [false, true])
            FacilityCard(
              facility: createTestFacility(
                name: 'Near North Health Service',
                description: 'Primary care, dental, and behavioral health '
                    'for all ages, regardless of ability to pay.',
                categoryBroad: 'Medical Care',
                services: const ['Primary Care', 'Dental', 'Vision'],
                website: 'https://example.org',
                eligibility: const FacilityEligibility(
                  acceptsWalkins: EligibilityValue.yes,
                  freeServicesAvailable: EligibilityValue.yes,
                  wheelchairAccessible: EligibilityValue.yes,
                ),
              ),
              isExpanded: expanded,
              onToggleExpand: () {},
              onToggleFavorite: () {},
              buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
              onLaunchUrl: (_) async {},
              onRate: () {},
              onSubmitCorrection: () {},
            ),
        ],
      ),
  'feedback': () => _Sample(
        children: [
          _label('EMPTY STATE'),
          EmptyState(
            icon: Icons.thumbs_up_down_outlined,
            title: 'No ratings yet',
            message: 'Rate a facility you visited to see it here.',
            action: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Request a facility'),
            ),
          ),
          _label('COVERAGE NOTICE'),
          const CoverageNotice(),
          _label('SHEET HANDLE'),
          const DragHandle(),
        ],
      ),
  'navigation': () => _Sample(
        padding: EdgeInsets.zero,
        children: [
          AppBar(title: const Text('Settings')),
          const SizedBox(height: AppSpacing.huge),
          BottomNavigationBar(
            currentIndex: 1,
            onTap: (_) {},
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
};

final _screens = <String, Widget Function()>{
  'login': () => const LoginPage(),
  'location_choice': () => const LocationChoicePage(),
  'zip_entry': () => const ZipEntryPage(),
  'eligibility_onboarding': () => const EligibilityOnboardingPage(),
  'settings': () => const SettingsPage(),
  'profile_guest': () => const ProfilePage(),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });
  setUp(mockPlatformServices);

  testWidgets('map kit pins and clusters', (tester) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: name, value: category)
          in _pinCategories.entries) {
        final pin = await MarkerUtils.facilityMarkerPng(category);
        _writePng('map/pins/pin_$name.png', await _cropPin(pin));
      }
      _writePng(
        'map/pins/pin_labeled_example.png',
        await MarkerUtils.facilityMarkerPng(
          FacilityCategories.groupHealthCare,
          name: 'Near North Health Service',
        ),
      );
      for (final count in const [7, 42, 180]) {
        _writePng(
          'map/pins/cluster_$count.png',
          await MarkerUtils.clusterMarkerPng(count),
        );
      }
    });
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    for (final MapEntry(key: name, value: build) in _components.entries) {
      testWidgets('component $name ($suffix)', (tester) async {
        await _render(
          tester,
          'component_${name}_$suffix',
          build,
          brightness: brightness,
          size: const Size(390, 1400),
          fullScreen: false,
        );
      });
    }

    for (final MapEntry(key: name, value: build) in _screens.entries) {
      testWidgets('screen $name ($suffix)', (tester) async {
        await _render(tester, 'screen_${name}_$suffix', build,
            brightness: brightness);
      });
    }

    // The one intentionally platform-specific surface: Apple on iOS.
    testWidgets(
      'screen login on iOS ($suffix)',
      (tester) async {
        await _render(
            tester, 'screen_login_ios_$suffix', () => const LoginPage(),
            brightness: brightness);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
