import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import 'subscription_form_view.dart';

class SubscriptionsListView extends StatelessWidget {
  const SubscriptionsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionFormView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.subscriptions.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildSubscriptionsList(context, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Subscription Tracker 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Start by adding your first subscription to see your total monthly spend here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionFormView(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Subscription'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(
      BuildContext context, SubscriptionProvider provider) {
    return ListView(
      children: [
        // Total Monthly Spend Section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Monthly Spend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${provider.totalMonthlySpend.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.subscriptions.length} subscription${provider.subscriptions.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Subscriptions List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = provider.subscriptions[index];
            return _buildSubscriptionRow(context, subscription, provider);
          },
        ),
      ],
    );
  }

  Widget _buildSubscriptionRow(
    BuildContext context,
    Subscription subscription,
    SubscriptionProvider provider,
  ) {
    // Date formatter
    final dateFormatter = DateFormat('MMM d, yyyy');

    // Calculate reminder date
    DateTime? reminderDate;
    if (subscription.reminderType != 'none' &&
        subscription.reminderDaysBefore > 0) {
      reminderDate = subscription.renewalDate
          .subtract(Duration(days: subscription.reminderDaysBefore));
    }

    return Dismissible(
      key: Key(subscription.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Subscription'),
            content: Text(
                'Are you sure you want to delete ${subscription.serviceName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteSubscription(subscription.id);
        // Haptic feedback
        // Note: You may need to add haptic_feedback package for better feedback
      },
      child: ListTile(
        title: Text(
          subscription.serviceName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subscription.category.value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '\$${subscription.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Renews ${DateFormat('MMM d, yyyy').format(subscription.renewalDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (subscription.reminderType != 'none' && reminderDate != null)
              Text(
                subscription.reminderDaysBefore == 0
                    ? 'Reminder on renewal day @ 7 PM'
                    : 'Reminder on ${dateFormatter.format(reminderDate)} @ 7 PM',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionFormView(
                subscription: subscription,
              ),
            ),
          );
        },
      ),
    );
  }
}

