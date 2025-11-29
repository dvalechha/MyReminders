import 'package:flutter/material.dart';

/// Help/Suggestion view displayed when the parser returns a result where
/// isSuccess is false, showing user-friendly help with clickable examples
class HelpSuggestionView extends StatelessWidget {
  final void Function(String example) onExampleTap;

  const HelpSuggestionView({
    super.key,
    required this.onExampleTap,
  });

  static const List<String> _exampleCommands = [
    'Appointment with Dr. Smith tomorrow at 2pm',
    'Remind me to buy milk in 1 hour',
    "Add 'Finish report' to my tasks for Friday",
    'Create subscription for Netflix renewal next month',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not sure what you meant. Try one of these:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _exampleCommands.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final example = _exampleCommands[index];
                return _ExampleCard(
                  example: example,
                  onTap: () => onExampleTap(example),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual clickable example card
class _ExampleCard extends StatelessWidget {
  final String example;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.example,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                example,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

