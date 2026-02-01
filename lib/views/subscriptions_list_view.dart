import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../widgets/subscription_filter_dialog.dart';
import '../widgets/subscription_card.dart';
import '../widgets/empty_state_view.dart';
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
  bool _hasLoaded = false;
  SubscriptionCategory? _filterCategory;
  bool _filterRenewingSoon = false;
  final Set<String> _selectedIds = {};
  
  bool get _isSelectionMode => _selectedIds.isNotEmpty;
  
  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }
  
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Use a PostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      // Only load if we haven't loaded yet or if the list is empty
      if (!_hasLoaded || provider.subscriptions.isEmpty) {
        provider.loadSubscriptions();
        _hasLoaded = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh when returning to this view (not on every rebuild)
    // Check if subscriptions are already loaded to avoid unnecessary reloads
    if (_hasLoaded) {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      // Only reload if subscriptions list is empty (might have been cleared)
      if (provider.subscriptions.isEmpty && !provider.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadSubscriptions();
        });
      }
    }
  }

  List<Subscription> _filterSubscriptions(
      List<Subscription> subscriptions, String searchText) {
    var filtered = subscriptions;

    // Apply search filter
    if (searchText.isNotEmpty) {
      final lowerSearchText = searchText.toLowerCase();
      filtered = filtered.where((subscription) {
        final serviceName = subscription.serviceName.toLowerCase();
        final category = subscription.category.value.toLowerCase();
        final notes = (subscription.notes ?? '').toLowerCase();
        return serviceName.contains(lowerSearchText) ||
            category.contains(lowerSearchText) ||
            notes.contains(lowerSearchText);
      }).toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      filtered = filtered.where((subscription) => subscription.category == _filterCategory).toList();
    }

    // Apply renewing soon filter
    if (_filterRenewingSoon) {
      final now = DateTime.now();
      filtered = filtered.where((subscription) {
        final daysUntilRenewal = subscription.renewalDate.difference(now).inDays;
        return daysUntilRenewal <= 7 && daysUntilRenewal >= 0;
      }).toList();
    }

    return filtered;
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
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Subscriptions'),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredSubscriptions =
            _filterSubscriptions(provider.subscriptions, _searchText);

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvoked: (didPop) {
            if (!didPop && _isSelectionMode) {
              _clearSelection();
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(context),
            backgroundColor: Colors.grey[100], // Light grey background
            body: provider.subscriptions.isEmpty
                ? _buildEmptyState(context)
                : _buildSubscriptionsList(context, provider, filteredSubscriptions),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        title: Text('${_selectedIds.length} Selected'),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew),
            onPressed: _renewSelectedItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelectedItems,
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Text('My Subscriptions'),
        elevation: 0,
        scrolledUnderElevation: 0,
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search subscriptions...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Filter icon
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.tune, size: 20),
                            if (_filterCategory != null || _filterRenewingSoon)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => SubscriptionFilterDialog(
                              initialCategory: _filterCategory,
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _filterCategory = result['category'] as SubscriptionCategory?;
                              _filterRenewingSoon = result['renewingSoon'] as bool? ?? false;
                            });
                          }
                        },
                      ),
                      // Clear icon
                      if (_searchText.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchText = '';
                            });
                          },
                        ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  
  void _renewSelectedItems() {
    if (_selectedIds.isEmpty) return;
    
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    provider.renewSelectedSubscriptions(_selectedIds);
    
    // Show a confirmation and clear selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Renewing selected items...'),
        duration: Duration(seconds: 2),
      ),
    );
    _clearSelection();
  }
  
  void _deleteSelectedItems() {
    if (_selectedIds.isEmpty) return;
    
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    // Delete all selected subscriptions
    for (final id in _selectedIds) {
      provider.deleteSubscription(id);
    }
    
    // Clear selection
    _clearSelection();
    
    // Show snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.credit_card_outlined,
      title: 'No Active Subscriptions',
      description: 'Track recurring expenses like Netflix, Spotify, or Gym memberships in one place.',
      buttonText: 'Add First Subscription',
      onPressed: () {
        MainNavigationKeys.homeNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const SubscriptionFormView(),
            settings: const RouteSettings(name: 'SubscriptionFormView'),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsList(
      BuildContext context, SubscriptionProvider provider, List<Subscription> filteredSubscriptions) {
    final monthlySpendData = _calculateMonthlySpend(provider.subscriptions);
    
    // Determine scroll physics based on platform
    final scrollPhysics = Platform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return ListView(
      physics: scrollPhysics,
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
                        child: _buildBarChart(monthlySpendData, provider.totalMonthlySpend),
                      ),
                      const Divider(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
        // Subscriptions List
        if (filteredSubscriptions.isEmpty)
          Padding(
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
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Column(
              children: List.generate(
                filteredSubscriptions.length,
                (index) {
                  final subscription = filteredSubscriptions[index];
                  final isSelected = _selectedIds.contains(subscription.id);

                  final card = SubscriptionCard(
                    subscription: subscription,
                    isSelected: isSelected,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(subscription.id);
                      } else {
                        MainNavigationKeys.homeNavigatorKey.currentState?.push(
                          MaterialPageRoute(
                            builder: (context) => SubscriptionFormView(
                              subscription: subscription,
                            ),
                            settings: const RouteSettings(name: 'SubscriptionFormView'),
                          ),
                        );
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        HapticFeedback.lightImpact();
                        _toggleSelection(subscription.id);
                      }
                    },
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: _isSelectionMode
                        ? card
                        : Dismissible(
                            key: Key(subscription.id),
                            direction: DismissDirection.startToEnd,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.autorenew, color: Colors.green),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                provider.startRenewSubscription(subscription.id);
                                return false; // Don't actually dismiss the card
                              }
                              return false;
                            },
                            child: card,
                          ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChart(List<MonthlySpend> monthlyData, double totalMonthlySpend) {
    // Calculate maxY based on totalMonthlySpend (not bar heights)
    // This ensures the axis is always tall enough to show the full monthly budget
    final maxY = totalMonthlySpend > 0 ? totalMonthlySpend * 1.2 : 100.0;
    
    // Calculate interval: adaptive based on maxY to handle small and large values
    // For small amounts (< 50), use interval of 10
    // For medium amounts (< 100), use interval of 20
    // For large amounts (>= 100), use existing rounding logic
    final double interval;
    if (maxY < 50) {
      interval = 10.0;
    } else if (maxY < 100) {
      interval = 20.0;
    } else {
      // For maxY >= 100: divide into 5 equal steps, then round to clean number (nearest 50)
      final rawInterval = maxY / 5;
      interval = (rawInterval / 50).ceil() * 50.0;
    }

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
              interval: interval,
              getTitlesWidget: (value, meta) {
                // Hide labels that are too close to maxY to prevent overlap
                // Only show labels that are multiples of the interval
                final tolerance = interval * 0.1; // 10% tolerance for floating point comparison
                if ((value - maxY).abs() < tolerance) {
                  // Hide the maxY label to prevent collision with interval labels
                  return const Text('');
                }
                
                // Show 0 at the bottom
                if (value == 0) {
                  return Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  );
                }
                
                // Only show labels that are multiples of the interval
                // This ensures clean steps: 0, 300, 600, 900, 1200
                final remainder = (value % interval).abs();
                if (remainder < tolerance || (interval - remainder) < tolerance) {
                  return Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  );
                }
                
                // Hide other labels
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
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
          final isCurrentMonth = index == monthlyData.length - 1; // Last item is current month
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                // Current month bar uses totalMonthlySpend to sync with the header summary
                // Historical months use data.total (sum of subscriptions renewing in that month)
                toY: isCurrentMonth ? totalMonthlySpend : data.total,
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

