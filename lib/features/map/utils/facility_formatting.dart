import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Utility class for building category icons based on 211 taxonomy.
class FacilityCategoryIcons {
  /// Builds a category icon widget for the given category string.
  ///
  /// [category] should be a `category_broad` value like "Medical Care".
  static Widget buildCategoryIcon(String? category) =>
      CategoryIcon(category: category);

  /// The name of one of the six groups (`FacilityCategories.quickActionGroups`)
  /// as Home's tiles and the filter sheet show it. The group constant stays
  /// canonical English — it's the filter value and the icon/color key — so
  /// only this label is translated.
  static String groupLabel(AppLocalizations l10n, String group) =>
      switch (group) {
        FacilityCategories.groupHealthCare => l10n.homeCategoryHealthCare,
        FacilityCategories.groupMentalHealth => l10n.homeCategoryMentalHealth,
        FacilityCategories.groupHousingShelter => l10n.homeCategoryHousing,
        FacilityCategories.groupBasicNeeds => l10n.homeCategoryBasicNeeds,
        FacilityCategories.groupFamilyCommunity =>
          l10n.homeCategoryFamilyCommunity,
        FacilityCategories.groupMoneyJobsLegal =>
          l10n.homeCategoryMoneyJobsLegal,
        _ => group,
      };

  /// A subcategory chip's label (`FacilityCategories.serviceTagGroups` key)
  /// in the reader's language. Anything else is shown through
  /// [getCategoryDisplayName].
  static String tagLabel(AppLocalizations l10n, String key) => switch (key) {
        'medical_clinic' => l10n.categoryChipMedicalClinic,
        'hospital' => l10n.categoryChipHospital,
        'dental_vision' => l10n.categoryChipDentalVision,
        'home_care' => l10n.categoryChipHomeCare,
        'mental_health_care' => l10n.categoryChipMentalHealthCare,
        'crisis' => l10n.categoryChipCrisis,
        'addiction' => l10n.categoryChipAddiction,
        'recovery' => l10n.categoryChipRecovery,
        'emergency_shelter' => l10n.categoryChipEmergencyShelter,
        'abuse_shelter' => l10n.categoryChipAbuseShelter,
        'transitional_housing' => l10n.categoryChipTransitionalHousing,
        'affordable_housing' => l10n.categoryChipAffordableHousing,
        'food_pantry' => l10n.categoryChipFoodPantry,
        'meals' => l10n.categoryChipMeals,
        'essentials' => l10n.categoryChipEssentials,
        'baby_supplies' => l10n.categoryChipBabySupplies,
        'legal' => l10n.categoryChipLegal,
        'jobs_education' => l10n.categoryChipJobsEducation,
        'financial_support' => l10n.categoryChipFinancialSupport,
        'transportation' => l10n.categoryChipTransportation,
        'children_families' => l10n.categoryChipChildrenFamilies,
        'disability' => l10n.categoryChipDisability,
        'seniors' => l10n.categoryChipSeniors,
        'veterans' => l10n.categoryChipVeterans,
        _ => getCategoryDisplayName(key),
      };

  /// Returns a display-friendly name for a category.
  static String getCategoryDisplayName(String? category) {
    if (category == null || category.isEmpty) return 'Community Resource';

    return category;
  }
}

/// A category's icon on a tinted tile, in the tone that reads in the current
/// mode. Decorative: the facility's name beside it says what it is.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final color = MarkerUtils.getColorForCategory(
      category,
      brightness: Theme.of(context).brightness,
    );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.tintStrong,
          borderRadius: AppRadii.smAll,
        ),
        child: Icon(
          MarkerUtils.getIconForCategory(category),
          color: color,
          size: AppIconSize.lg,
        ),
      ),
    );
  }
}
