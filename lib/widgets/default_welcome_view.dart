import 'package:flutter/material.dart';

/// Default view shown when the app starts or the input field is empty.
/// Displays clickable example commands to guide the user.
class DefaultWelcomeView extends StatelessWidget {
  /// Callback when an example is tapped
  final void Function(String example)? onExampleTap;

  const DefaultWelcomeView({
    super.key,
    this.onExampleTap,
  });

  /// Example commands showcasing both 'create' and 'show' actions
  static const List<_ExampleCommand> _exampleCommands = [
    _ExampleCommand(
      text: 'Show me my subscriptions',
      icon: Icons.credit_card,
    ),
    _ExampleCommand(
      text: 'Do I have any appointments today?',
      icon: Icons.event,
    ),
    _ExampleCommand(
      text: 'Create an appointment for tomorrow at 5pm with Dr. Smith',
      icon: Icons.add_circle_outline,
    ),
    _ExampleCommand(
      text: 'List my tasks',
      icon: Icons.checklist,
    ),
    _ExampleCommand(
      text: 'Add a task to buy groceries',
      icon: Icons.add_task,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try these…',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _exampleCommands.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final example = _exampleCommands[index];
              return _ExampleCommandCard(
                command: example,
                onTap: onExampleTap != null 
                    ? () => onExampleTap!(example.text)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Data class for example commands
class _ExampleCommand {
  final String text;
  final IconData icon;

  const _ExampleCommand({
    required this.text,
    required this.icon,
  });
}

/// Clickable card for an example command
class _ExampleCommandCard extends StatelessWidget {
  final _ExampleCommand command;
  final VoidCallback? onTap;

  const _ExampleCommandCard({
    required this.command,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              command.icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                command.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}


