import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Compact search input used above the Courses / Editors / Students
/// tables. Debounces the [onChanged] callback so a typed query only
/// triggers one network refetch after the user pauses.
class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;
  final double width;
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
    this.width = 280,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(v.trim()));
  }

  void _clear() {
    _controller.clear();
    _timer?.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        style: const TextStyle(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: TextStyle(fontSize: 13, color: DashColors.w(0.35)),
          filled: true,
          fillColor: DashColors.w(0.04),
          prefixIcon: Icon(Icons.search,
              size: 16, color: DashColors.w(0.55)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(Icons.close,
                      size: 14, color: DashColors.w(0.55)),
                  onPressed: () => setState(_clear),
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: DashRadii.input,
            borderSide: BorderSide(color: DashColors.w(0.14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: DashRadii.input,
            borderSide: BorderSide(color: DashColors.w(0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: DashRadii.input,
            borderSide:
                BorderSide(color: DashColors.brand.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }
}
