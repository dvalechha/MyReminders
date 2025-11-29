import 'package:flutter/material.dart';

/// Default view shown when the app starts or the input field is empty
class DefaultWelcomeView extends StatelessWidget {
  const DefaultWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask, schedule, or search…',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try creating an appointment, task, or subscription',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

