import 'package:flutter/material.dart';
import '../models/parsed_intent.dart';
import 'package:intl/intl.dart';

/// Success view displayed when the IntentParserService returns a ParsedIntent
/// where isSuccess is true, showing a confirmation card with parsed information
class SuccessIntentView extends StatelessWidget {
  final ParsedIntent parsedIntent;

  const SuccessIntentView({
    super.key,
    required this.parsedIntent,
  });

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not specified';
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  String _formatCategory(String? category) {
    if (category == null) return 'Unknown';
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatAction(String? action) {
    if (action == null) return 'Unknown';
    return action[0].toUpperCase() + action.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'I understood!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                context,
                'Action',
                _formatAction(parsedIntent.action),
                Icons.play_arrow,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Category',
                _formatCategory(parsedIntent.category),
                Icons.category,
              ),
              if (parsedIntent.dateTime != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  'When',
                  _formatDateTime(parsedIntent.dateTime),
                  Icons.access_time,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

