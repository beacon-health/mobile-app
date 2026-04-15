import 'package:beacon_app/features/map/presentation/widgets/markers/marker_utils.dart';
import 'package:flutter/material.dart';

/// Utility class for building category icons based on 211 taxonomy.
class FacilityCategoryIcons {
  /// Builds a category icon widget for the given category string.
  ///
  /// [category] should be a categoryLevel1 value like "Health Care".
  static Widget buildCategoryIcon(String? category) {
    final icon = MarkerUtils.getIconForCategory(category);
    final color = MarkerUtils.getColorForCategory(category);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  /// Returns a display-friendly name for a category.
  static String getCategoryDisplayName(String? category) {
    if (category == null || category.isEmpty) return 'Community Resource';

    return category;
  }
}
