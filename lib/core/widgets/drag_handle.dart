import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Grab handle for bottom sheets and draggable panels. Matches the handle
/// Material draws for `showModalBottomSheet(showDragHandle: true)` (sized and
/// colored by the theme's `bottomSheetTheme`), for sheets that build their
/// own chrome.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final sheetTheme = Theme.of(context).bottomSheetTheme;
    final size = sheetTheme.dragHandleSize ??
        const Size(AppSizes.handleWidth, AppSizes.handleHeight);
    return Center(
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: sheetTheme.dragHandleColor,
          borderRadius: AppRadii.pillAll,
        ),
      ),
    );
  }
}
