import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../utils/subscription_status_helper.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final isPendingRenewal = provider.pendingRenewals.contains(subscription.id);

        // Use centralized status logic with timestamp-level granularity
        final status = getSubscriptionStatus(subscription.renewalDate);
        final isOverdue = status == SubscriptionStatus.overdue;
        final isDueToday = status == SubscriptionStatus.dueToday;

        final Color statusColor;
        final String statusText;

        // Status text from helper (handles "Overdue", "Due today", "Renews in X days")
        statusText = getRenewalText(
          subscription.renewalDate,
          billingCycle: subscription.billingCycle,
        );

        if (isOverdue || isDueToday) {
          statusColor = Colors.red;
        } else {
          // Get status color from helper
          statusColor = getSubscriptionStatusColor(
            subscription.renewalDate,
            billingCycle: subscription.billingCycle,
          );
        }

        final firstLetter = subscription.serviceName.isNotEmpty
            ? subscription.serviceName[0].toUpperCase()
            : '?';
        final brandBlue = Colors.blue;

        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPendingRenewal
                  ? Colors.green.shade50
                  : (isSelected ? Colors.blue.shade50 : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: brandBlue, width: 2)
                  : (isPendingRenewal ? Border.all(color: Colors.green.shade200) : null),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isPendingRenewal
                ? _buildPendingRenewalView(context, provider)
                : _buildDefaultView(context, statusColor, statusText, firstLetter, brandBlue, isOverdue, isDueToday),
          ),
        );
      },
    );
  }

  Widget _buildDefaultView(
      BuildContext context, Color statusColor, String statusText, String firstLetter, Color brandBlue, bool isOverdue, bool isDueToday) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Main Content Area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar / Checkbox
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? CircleAvatar(
                        key: const ValueKey('check'),
                        radius: 24,
                        backgroundColor: brandBlue,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : Container(
                        key: const ValueKey('avatar'),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (isOverdue || isDueToday ? Colors.red : statusColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isOverdue || isDueToday ? Colors.red : statusColor,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Left Column: Name, Cycle, Due Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subscription.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey[700],
                        fontWeight: isOverdue || isDueToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right Side Stack: Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$${subscription.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingRenewalView(BuildContext context, SubscriptionProvider provider) {
    final duration = provider.pendingRenewalDurations[subscription.id] ?? const Duration(seconds: 10);
    final isEarly = duration.inSeconds == 30;
    final totalSeconds = duration.inSeconds.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: totalSeconds, end: 0.0),
      duration: duration,
      builder: (context, value, child) {
        final remainingSeconds = value.ceil();
        final progress = value / totalSeconds;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Renewing ${subscription.serviceName}...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEarly)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'Early Renewal',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    provider.undoRenewSubscription(subscription.id);
                  },
                  child: Text('Undo (${remainingSeconds}s)', style: const TextStyle(color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.green.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        );
      },
    );
  }
}
