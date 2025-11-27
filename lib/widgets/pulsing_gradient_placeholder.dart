import 'package:flutter/material.dart';

class PulsingGradientPlaceholder extends StatefulWidget {
  final String? inputText;

  const PulsingGradientPlaceholder({
    super.key,
    this.inputText,
  });

  @override
  State<PulsingGradientPlaceholder> createState() =>
      _PulsingGradientPlaceholderState();
}

class _PulsingGradientPlaceholderState
    extends State<PulsingGradientPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = widget.inputText != null && widget.inputText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: _animation.value),
                Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: _animation.value * 0.6),
                Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: _animation.value * 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: hasInput
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Processing: "${widget.inputText}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: _animation.value),
                  ),
          ),
        );
      },
    );
  }
}

