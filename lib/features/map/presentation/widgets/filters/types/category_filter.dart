import 'package:flutter/material.dart';

import '../../../../utils/facility_display_utils.dart';
import '../components/filter_chip.dart';

class CategoryFilter extends StatelessWidget {
  final Set<String> selectedCategories;
  final VoidCallback onTap;

  const CategoryFilter({
    super.key,
    required this.selectedCategories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    if (selectedCategories.isEmpty) {
      label = 'Category';
    } else if (selectedCategories.length == 1) {
      label = FacilityCategoryIcons.getCategoryDisplayName(
          selectedCategories.first);
    } else {
      label = '${selectedCategories.length} selected';
    }

    return CustomFilterChip(
      label: label,
      isSelected: selectedCategories.isNotEmpty,
      hasDropdown: true,
      onTap: onTap,
    );
  }
}
