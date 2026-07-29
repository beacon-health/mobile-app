import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FacilitySearch extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  /// Jumps the map/query to the user's GPS position. Rendered as the blue
  /// my-location button on the right side of this bar (moved here from the
  /// location search bar).
  final VoidCallback? onUseMyLocation;

  /// Shows a spinner in place of the my-location button while GPS resolves.
  final bool isLocatingUser;

  const FacilitySearch({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.onUseMyLocation,
    this.isLocatingUser = false,
  });

  @override
  State<FacilitySearch> createState() => _FacilitySearchState();
}

class _FacilitySearchState extends State<FacilitySearch> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceFaded),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.mapSearchResourcesHint ??
                  'Search for resources...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              filled: false,
              fillColor: Colors.transparent,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            textAlignVertical: TextAlignVertical.center,
            onChanged: (_) => widget.onChanged(),
          ),
        ),
        if (widget.controller.text.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurfaceFaded,
            ),
            onPressed: () {
              widget.controller.clear();
              widget.onClear();
            },
          ),
        if (widget.onUseMyLocation != null)
          widget.isLocatingUser
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: widget.onUseMyLocation,
                  tooltip: AppLocalizations.of(context)
                          ?.locationUseMyLocationTooltip ??
                      'Use my location',
                ),
      ],
    );
  }
}
