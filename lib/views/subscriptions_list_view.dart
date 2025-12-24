import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/subscription_provider.dart';
import '../providers/navigation_model.dart';
import '../models/subscription.dart';
import '../widgets/app_navigation_drawer.dart';
import 'subscription_form_view.dart';
import 'main_navigation_view.dart';

class MonthlySpend {
  final String id;
  final String monthLabel;
  final double total;

  MonthlySpend({
    required this.id,
    required this.monthLabel,
    required this.total,
  });
}

class SubscriptionsListView extends StatefulWidget {
  const SubscriptionsListView({super.key});

  @override
  State<SubscriptionsListView> createState() => _SubscriptionsListViewState();
}

class _SubscriptionsListViewState extends State<SubscriptionsListView> {
  String _searchText = '';
  bool _isChartExpanded = true;

  @override
  void initState() {
    super.initState();
    // Use a PostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time dependencies change (e.g., when returning to this view)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).loadSubscriptions();
    });
  }

  List<Subscription> _filterSubscriptions(
      List<Subscription> subscriptions, String searchText) {
    if (searchText.isEmpty) {
      return subscriptions;
    }

    final lowerSearchText = searchText.toLowerCase();
    return subscriptions.where((subscription) {
      final serviceName = subscription.serviceName.toLowerCase();
      final category = subscription.category.value.toLowerCase();
      final notes = (subscription.notes ?? '').toLowerCase();

      return serviceName.contains(lowerSearchText) ||
          category.contains(lowerSearchText) ||
          notes.contains(lowerSearchText);
    }).toList();
  }

  List<MonthlySpend> _calculateMonthlySpend(List<Subscription> subscriptions) {
    final now = DateTime.now();
    final monthlyData = <String, double>{};

    // Initialize last 6 months with 0
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(month);
      monthlyData[monthKey] = 0.0;
    }

    // Sum subscription amounts by renewal month
    for (final subscription in subscriptions) {
      final renewalDate = subscription.renewalDate;
      final monthKey = DateFormat('yyyy-MM').format(
        DateTime(renewalDate.year, renewalDate.month, 1),
      );

      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + subscription.amount;
      }
    }

    // Convert to MonthlySpend list in chronological order
    final sortedKeys = monthlyData.keys.toList()..sort();
    return sortedKeys.map((key) {
      final date = DateFormat('yyyy-MM').parse(key);
      final monthLabel = DateFormat('MMM').format(date);
      return MonthlySpend(
        id: key,
        monthLabel: monthLabel,
        total: monthlyData[key] ?? 0.0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Subscriptions'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: const AppNavigationDrawer(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredSubscriptions =
            _filterSubscriptions(provider.subscriptions, _searchText);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Subscriptions'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  MainNavigationKeys.homeNavigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionFormView(),
                      settings: const RouteSettings(name: 'SubscriptionFormView'),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search subscriptions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          drawer: const AppNavigationDrawer(),
          body: provider.subscriptions.isEmpty
              ? _buildEmptyState(context)
              : _buildSubscriptionsList(context, provider, filteredSubscriptions),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Subscriptions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first subscription',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsList(
      BuildContext context, SubscriptionProvider provider, List<Subscription> filteredSubscriptions) {
    final monthlySpendData = _calculateMonthlySpend(provider.subscriptions);
    
    return ListView(
      children: [
        // Total Monthly Spend Section (Collapsible)
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isChartExpanded = !_isChartExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Monthly Spend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _isChartExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isChartExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                '${filteredSubscriptions.length} subscription${filteredSubscriptions.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        // 6-Month Bar Chart (Collapsible)
        if (monthlySpendData.isNotEmpty) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isChartExpanded
                ? Column(
                    children: [
                      Container(
                        height: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildBarChart(monthlySpendData),
                      ),
                      const Divider(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
        // Subscriptions List
        filteredSubscriptions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No subscriptions found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSubscriptions.length,
                itemBuilder: (context, index) {
                  final subscription = filteredSubscriptions[index];
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w400,
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
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
            if (subscription.reminderType != 'none' && reminderDate != null)
              Text(
                subscription.reminderDaysBefore == 0
                    ? 'Reminder on renewal day @ 7 PM'
                    : 'Reminder on ${dateFormatter.format(reminderDate)} @ 7 PM',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        onTap: () {
          MainNavigationKeys.homeNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => SubscriptionFormView(
                subscription: subscription,
              ),
              settings: const RouteSettings(name: 'SubscriptionFormView'),
            ),
          );
        },
      ),
    );
  }

  /// Calculates a nice rounded maximum Y value for the chart
  /// Returns increments like 10, 15, 20, 25, 50, 100, etc.
  double _calculateNiceMaxY(double maxValue) {
    if (maxValue <= 0) return 100.0;
    
    // Add 20% padding, then round to nice increments
    final paddedValue = maxValue * 1.2;
    
    // Define nice increments based on value ranges
    if (paddedValue <= 10) {
      // For values up to 10, round to 5 or 10
      return paddedValue <= 5 ? 5.0 : 10.0;
    } else if (paddedValue <= 50) {
      // For values 10-50, round to 15, 20, 25, 30, 40, 50
      if (paddedValue <= 15) return 15.0;
      if (paddedValue <= 20) return 20.0;
      if (paddedValue <= 25) return 25.0;
      if (paddedValue <= 30) return 30.0;
      if (paddedValue <= 40) return 40.0;
      return 50.0;
    } else if (paddedValue <= 100) {
      // For values 50-100, round to 60, 70, 80, 90, 100
      if (paddedValue <= 60) return 60.0;
      if (paddedValue <= 70) return 70.0;
      if (paddedValue <= 80) return 80.0;
      if (paddedValue <= 90) return 90.0;
      return 100.0;
    } else if (paddedValue <= 500) {
      // For values 100-500, round to 125, 150, 200, 250, 300, 400, 500
      if (paddedValue <= 125) return 125.0;
      if (paddedValue <= 150) return 150.0;
      if (paddedValue <= 200) return 200.0;
      if (paddedValue <= 250) return 250.0;
      if (paddedValue <= 300) return 300.0;
      if (paddedValue <= 400) return 400.0;
      return 500.0;
    } else {
      // For larger values, round to 50, 100, 500, 1000 increments
      final magnitude = math.pow(10, (math.log(paddedValue) / math.ln10).floor()).toDouble();
      if (paddedValue <= magnitude * 2) return magnitude * 2;
      if (paddedValue <= magnitude * 5) return magnitude * 5;
      return magnitude * 10;
    }
  }

  Widget _buildBarChart(List<MonthlySpend> monthlyData) {
    final maxValue = monthlyData.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final maxY = _calculateNiceMaxY(maxValue);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.grey[800]!,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\${rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthlyData[value.toInt()].monthLabel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const Text('');
                }
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        barGroups: monthlyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.total,
                color: Colors.blue,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

