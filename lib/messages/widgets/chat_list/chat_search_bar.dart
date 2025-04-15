import 'package:flutter/material.dart';
import 'package:campus_conn/config/theme.dart';

/// A beautiful, animated search bar for the chat list screen
class ChatSearchBar extends StatefulWidget {
  /// Callback for when the search text changes
  final Function(String) onChanged;

  /// Hint text to display when empty
  final String hintText;

  /// Initial search value
  final String initialValue;

  /// Animation duration
  final Duration animationDuration;

  /// Constructor
  const ChatSearchBar({
    Key? key,
    required this.onChanged,
    this.hintText = 'Search conversations...',
    this.initialValue = '',
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _curvedAnimation;

  // Whether the search bar is focused
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller with initial value
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Set up focus listener
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Handle focus changes
  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // Animate elevation based on focus
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimatedBuilder(
        animation: _curvedAnimation,
        builder: (context, child) {
          return Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05 + 0.05 * _curvedAnimation.value),
                  blurRadius: 8.0 + 8.0 * _curvedAnimation.value,
                  spreadRadius: 0.0 + 1.0 * _curvedAnimation.value,
                  offset: Offset(0, 2.0 + 2.0 * _curvedAnimation.value),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: AnimatedOpacity(
                opacity: _isFocused ? 1.0 : 0.7,
                duration: widget.animationDuration,
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused ? AppTheme.primaryColor : Colors.grey[600],
                  size: 22,
                ),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: Colors.grey[600],
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
      ),
    );
  }
}
