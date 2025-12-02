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
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Container(
            width: double.infinity,
            height: double.infinity,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final isCompact = height < 120;
                
                return hasInput
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: isCompact ? 32 : 48,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              SizedBox(height: isCompact ? 8 : 16),
                              Text(
                                widget.inputText!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: isCompact ? 14 : 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: null,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: isCompact ? 48 : 64,
                          color: Colors.white.withValues(alpha: _animation.value),
                        ),
                      );
              },
            ),
          ),
        );
      },
    );
  }
}

