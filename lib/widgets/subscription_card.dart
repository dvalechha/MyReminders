import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../utils/subscription_status_helper.dart';

class SubscriptionCard extends StatefulWidget {
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
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  bool _isPaid = false;

  @override
  void didUpdateWidget(SubscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subscription.renewalDate != oldWidget.subscription.renewalDate) {
      _isPaid = false;
    }
  }

  void _handleRenew() {
    setState(() {
      _isPaid = true;
    });
    
    // Trigger success logic
    // We delay the actual update slightly to let the user see the "Paid!" state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final nextRenewal = calculateNextRenewal(
        widget.subscription.renewalDate,
        widget.subscription.billingCycle,
      );
      final updatedSub = widget.subscription.copyWith(
        renewalDate: nextRenewal,
      );
      
      // We don't want to break the visual state immediately, but the list update might rebuild us.
      // For now, we just perform the update.
      provider.updateSubscription(updatedSub);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renewed ${widget.subscription.serviceName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use centralized status logic with timestamp-level granularity
    final status = getSubscriptionStatus(widget.subscription.renewalDate);
    final isOverdue = status == SubscriptionStatus.overdue;
    final isDueToday = status == SubscriptionStatus.dueToday;
    final showRenewButton = isOverdue || isDueToday;

    final Color statusColor;
    final String statusText;
    
    // Status text from helper (handles "Overdue", "Due today", "Renews in X days")
    statusText = getRenewalText(
      widget.subscription.renewalDate, 
      billingCycle: widget.subscription.billingCycle,
    );

    if (isOverdue || isDueToday) {
      statusColor = Colors.red;
    } else {
      // Get status color from helper
      statusColor = getSubscriptionStatusColor(
        widget.subscription.renewalDate,
        billingCycle: widget.subscription.billingCycle,
      );
    }

    final firstLetter = widget.subscription.serviceName.isNotEmpty
        ? widget.subscription.serviceName[0].toUpperCase()
        : '?';
    final brandBlue = Colors.blue;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.isSelected
              ? Border.all(color: brandBlue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Status strip (Left most)
            if (!widget.isSelected)
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: isOverdue || isDueToday ? Colors.red : statusColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            
            if (!widget.isSelected) const SizedBox(width: 12),

            // Main Content Area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar / Checkbox
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isSelected
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
                              color: (isOverdue || isDueToday ? Colors.red : statusColor).withOpacity(0.2),
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
                  // Wrapped in Expanded as requested
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subscription.serviceName,
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

            // Right Side Stack: Price + Renew Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${widget.subscription.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (showRenewButton) ...[
                  const SizedBox(height: 4),
                  // Renew Button (Action Pill)
                  GestureDetector(
                    onTap: _isPaid ? null : () {
                      HapticFeedback.mediumImpact();
                      _handleRenew();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isPaid ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPaid ? Colors.green.shade100 : Colors.red.shade100,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPaid ? Icons.check_circle : Icons.check_circle_outline,
                            size: 14,
                            color: _isPaid ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPaid ? 'Paid!' : 'Renew',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isPaid ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
