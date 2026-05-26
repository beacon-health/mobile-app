import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:flutter/material.dart';

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
        selectedCategories.first,
      );
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
