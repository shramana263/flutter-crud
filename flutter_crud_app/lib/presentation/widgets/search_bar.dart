import 'dart:async';
import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBar({super.key, required this.onSearch});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}