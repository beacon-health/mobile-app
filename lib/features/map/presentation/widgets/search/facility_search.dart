import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:flutter/material.dart';

class FacilitySearch extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const FacilitySearch({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
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
            decoration: const InputDecoration(
              hintText: 'Search for resources...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
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
            icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurfaceFaded),
            onPressed: () {
              widget.controller.clear();
              widget.onClear();
            },
          ),
      ],
    );
  }
}
