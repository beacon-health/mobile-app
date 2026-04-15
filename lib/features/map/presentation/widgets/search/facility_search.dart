import 'package:flutter/material.dart';

class FacilitySearch extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const FacilitySearch({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  State<FacilitySearch> createState() => _FacilitySearchState();
}

class _FacilitySearchState extends State<FacilitySearch> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.search, color: Colors.grey),
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
            style: const TextStyle(color: Colors.black),
            textAlignVertical: TextAlignVertical.center,
            onChanged: (_) => widget.onChanged(),
          ),
        ),
        if (widget.controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              widget.controller.clear();
              widget.onClear();
            },
          ),
      ],
    );
  }
}
