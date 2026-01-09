import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Reusable Smart Card component for unified list UI
/// 
/// Features:
/// - White card with rounded corners (16dp)
/// - Vertical color status strip on left edge (6dp width)
/// - Subtle elevation/shadow
/// - Platform-specific tap feedback (InkWell for Android, GestureDetector for iOS)
class SmartListTile extends StatelessWidget {
  final Widget child;
  final Color statusColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const SmartListTile({
    super.key,
    required this.child,
    required this.statusColor,
    this.onTap,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status strip (6dp width, rounded left corners)
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Main content
          Expanded(child: child),
        ],
      ),
    );

    // Platform-specific tap feedback
    if (onTap != null) {
      if (isIOS) {
        // iOS: GestureDetector with opacity feedback on tap
        return _IOSCard(
          onTap: onTap!,
          child: cardContent,
        );
      } else {
        // Android: InkWell with ripple effect
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: cardContent,
          ),
        );
      }
    }

    return cardContent;
  }
}

/// iOS-specific card with opacity feedback on tap
class _IOSCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _IOSCard({
    required this.onTap,
    required this.child,
  });

  @override
  State<_IOSCard> createState() => _IOSCardState();
}

class _IOSCardState extends State<_IOSCard> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _opacity = 0.6);
      },
      onTapUp: (_) {
        setState(() => _opacity = 1.0);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _opacity = 1.0);
      },
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
