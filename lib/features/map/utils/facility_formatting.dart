import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:flutter/material.dart';

/// Utility class for building category icons based on 211 taxonomy.
class FacilityCategoryIcons {
  /// Builds a category icon widget for the given category string.
  ///
  /// [category] should be a `category_broad` value like "Medical Care".
  static Widget buildCategoryIcon(String? category) =>
      CategoryIcon(category: category);

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
