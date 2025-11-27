import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/intent_type.dart';

class Omnibox extends StatefulWidget {
  final void Function(String query) onSearch;
  final void Function(String query) onCreate;
  final void Function()? onClear;
  final List<String> existingItems;
  final TextEditingController? controller;

  const Omnibox({
    super.key,
    required this.onSearch,
    required this.onCreate,
    this.onClear,
    this.existingItems = const [],
    this.controller,
  });

  @override
  State<Omnibox> createState() => _OmniboxState();
}

class _OmniboxState extends State<Omnibox> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  IntentType _currentIntent = IntentType.search;
  bool _isFocused = false;

  // Action verbs that indicate create intent
  static const List<String> _createVerbs = [
    'add',
    'create',
    'new',
    'start',
    'make',
    'begin',
    'setup',
    'schedule',
  ];

  @override
  void initState() {
    super.initState();
    // Use provided controller or create a new one
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
    
    // Setup keyboard shortcuts
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    // Cmd/Ctrl+K to focus (handled via FocusNode)
    // This will be handled by the parent widget or via keyboard listener
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    final input = _controller.text.trim();
    final newIntent = _detectIntent(input);
    
    if (newIntent != _currentIntent) {
      setState(() {
        _currentIntent = newIntent;
      });
    }
  }

  IntentType _detectIntent(String input) {
    if (input.isEmpty) {
      return IntentType.search;
    }

    final lowerInput = input.toLowerCase().trim();

    // Check if input starts with any create verb
    for (final verb in _createVerbs) {
      if (lowerInput.startsWith(verb)) {
        return IntentType.create;
      }
    }

    // Check if input matches or partially matches existing items
    if (widget.existingItems.isNotEmpty) {
      final lowerItems = widget.existingItems.map((item) => item.toLowerCase()).toList();
      for (final item in lowerItems) {
        if (item.contains(lowerInput) || lowerInput.contains(item)) {
          return IntentType.search;
        }
      }
    }

    // Default to search (unless it starts with a create verb, which is already handled above)
    return IntentType.search;
  }

  void _handleSubmit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (_currentIntent == IntentType.search) {
      widget.onSearch(query);
    } else {
      widget.onCreate(query);
    }
  }

  void _handleClear() {
    _controller.clear();
    _focusNode.unfocus();
    // Notify parent that text was cleared
    widget.onClear?.call();
  }

  void _handleTab() {
    // Cycle through fields - for now, just toggle focus
    // In future iterations, this can cycle through detected chips
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Handle Cmd/Ctrl+K to focus
          // Check for meta (Cmd on Mac) or control (Ctrl) modifiers
          final isMetaOrControl = HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed;
          if ((event.logicalKey == LogicalKeyboardKey.keyK) && isMetaOrControl) {
            _focusNode.requestFocus();
          }
          // Handle Esc to clear
          else if (event.logicalKey == LogicalKeyboardKey.escape) {
            _handleClear();
          }
          // Handle Tab to cycle
          else if (event.logicalKey == LogicalKeyboardKey.tab) {
            _handleTab();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Ask, schedule, or search…',
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _currentIntent == IntentType.search
                    ? Icons.search
                    : Icons.add,
                key: ValueKey(_currentIntent),
                color: _isFocused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _handleClear,
                    tooltip: 'Clear (Esc)',
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onSubmitted: (_) => _handleSubmit(),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Only dispose controller if we created it (not provided from parent)
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }
}
