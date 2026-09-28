@Tags(['golden'])
library;

import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/core/widgets/section_header.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/selection_chip_builder.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_facility.dart';

/// Every themed building block on one screen. Both platform variants must
/// match the same image, so any iOS/Android divergence fails here.
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(List<Widget> children) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Components')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageGutter),
        children: [
          Text('Headline', style: text.headlineMedium),
          Text('Title large', style: text.titleLarge),
          Text('Title medium', style: text.titleMedium),
          Text('Body medium', style: text.bodyMedium),
          Text('Label small', style: text.labelSmall),
          const SizedBox(height: AppSpacing.lg),
          row([
            ElevatedButton(onPressed: () {}, child: const Text('Primary')),
            FilledButton(
              onPressed: () {},
              style: AppTheme.secondaryFilledButton(context),
              child: const Text('Secondary'),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
            const ElevatedButton(onPressed: null, child: Text('Disabled')),
          ]),
          const SizedBox(height: AppSpacing.lg),
          row(const [
            TagChip(label: 'Walk-ins', color: AppColors.healthCare),
            TagChip(
              label: 'Telehealth',
              color: AppColors.mentalHealth,
              icon: Icons.videocam,
            ),
            TagChip(label: 'Rejected', color: AppColors.bittersweet),
          ]),
          const SizedBox(height: AppSpacing.sm),
          row([
            CustomFilterChip(
              label: 'Open Now',
              isSelected: false,
              hasDropdown: false,
              onTap: () {},
            ),
            CustomFilterChip(
              label: 'Selected',
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
              label: 'Locked',
              isSelected: false,
              hasDropdown: true,
              isLocked: true,
              onTap: () {},
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          row(const [
            SelectionTile(
              label: 'Selected',
              selected: true,
              padding: EdgeInsets.all(AppSpacing.sm),
            ),
            SelectionTile(
              label: 'Unselected',
              selected: false,
              padding: EdgeInsets.all(AppSpacing.sm),
            ),
          ]),
          const SectionHeader('Section header'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('List tile'),
                  trailing: Text('Value'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.my_location),
                  title: const Text('Switch on'),
                  value: true,
                  onChanged: (_) {},
                ),
                SwitchListTile(
                  title: const Text('Switch off'),
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const TextField(
            decoration: InputDecoration(labelText: 'Text field'),
          ),
          const SizedBox(height: AppSpacing.md),
          const DragHandle(),
        ],
      ),
    );
  }
}

void main() {
  setUp(mockPlatformServices);

  for (final brightness in Brightness.values) {
    testWidgets(
      'component gallery (${brightness.name})',
      (tester) async {
        await pumpThemed(
          tester,
          const _Gallery(),
          brightness: brightness,
          size: const Size(390, 1100),
        );
        await expectLater(
          find.byType(_Gallery),
          matchesGoldenFile('images/components_${brightness.name}.png'),
        );
      },
      variant: shippingPlatforms,
    );

    testWidgets(
      'facility card, collapsed and expanded (${brightness.name})',
      (tester) async {
        final facility = createTestFacility(
          name: 'Near North Health Service',
          description: 'Primary care, dental, and behavioral health.',
          categoryBroad: 'Medical Care',
          services: const ['Primary Care', 'Dental', 'Vision'],
          website: 'https://example.org',
          eligibility: const FacilityEligibility(
            acceptsWalkins: EligibilityValue.yes,
            freeServicesAvailable: EligibilityValue.yes,
            wheelchairAccessible: EligibilityValue.yes,
          ),
        );
        await pumpThemed(
          tester,
          Scaffold(
            body: ListView(
              children: [
                for (final expanded in [false, true])
                  FacilityCard(
                    facility: facility,
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
          ),
          brightness: brightness,
        );
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('images/facility_card_${brightness.name}.png'),
        );
      },
      variant: shippingPlatforms,
    );
  }
}
