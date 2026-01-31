import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../utils/appointment_status_helper.dart';
import '../widgets/appointment_filter_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/selection_app_bar.dart';
import 'appointment_form_view.dart';
import 'main_navigation_view.dart';

class AppointmentsListView extends StatefulWidget {
  const AppointmentsListView({super.key});

  @override
  State<AppointmentsListView> createState() => _AppointmentsListViewState();
}

class _AppointmentsListViewState extends State<AppointmentsListView> {
  String _searchText = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _filterTodayOnly = false;
  bool _filterUpcomingOnly = false;
  bool? _filterCompleted = false; // Default to Active only

  @override
  void initState() {
    super.initState();
    // Use a PostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time dependencies change (e.g., when returning to this view)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
    });
  }

  List<Appointment> _filterAppointments(
      List<Appointment> appointments, String searchText) {
    var filtered = appointments;
    
    // Filter by completion status
    // null = Show All
    // true = Show Completed Only
    // false = Show Active Only (Default)
    if (_filterCompleted != null) {
      filtered = filtered.where((a) => a.isCompleted == _filterCompleted).toList();
    }

    // Apply search filter
    if (searchText.isNotEmpty) {
      final lowerSearchText = searchText.toLowerCase();
      filtered = filtered.where((appointment) {
        final title = appointment.title.toLowerCase();
        final notes = (appointment.notes ?? '').toLowerCase();
        final location = (appointment.location ?? '').toLowerCase();
        return title.contains(lowerSearchText) ||
            notes.contains(lowerSearchText) ||
            location.contains(lowerSearchText);
      }).toList();
    }

    // Apply quick filters
    if (_filterTodayOnly) {
      final today = DateTime.now();
      filtered = filtered.where((appointment) {
        return isAppointmentSameDay(appointment.dateTime, today);
      }).toList();
    }

    if (_filterUpcomingOnly) {
      final now = DateTime.now();
      filtered = filtered.where((appointment) {
        return appointment.dateTime.isAfter(now);
      }).toList();
    }

    // Apply date range filter
    if (_filterStartDate != null || _filterEndDate != null) {
      filtered = filtered.where((appointment) {
        final appointmentDate = appointment.dateTime;
        if (_filterStartDate != null && appointmentDate.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && appointmentDate.isAfter(_filterEndDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Appointments'),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredAppointments =
            _filterAppointments(provider.appointments, _searchText);

        return PopScope(
          canPop: !provider.isSelectionMode,
          onPopInvoked: (didPop) {
            if (!didPop && provider.isSelectionMode) {
              provider.clearSelection();
            }
          },
          child: Scaffold(
            appBar: provider.isSelectionMode
                ? SelectionAppBar(
                    selectionCount: provider.selectedIds.length,
                    onClearSelection: provider.clearSelection,
                    onDeleteSelected: () => _handleDeleteSelected(context, provider),
                  )
                : AppBar(
                    title: const Text('My Appointments'),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          MainNavigationKeys.homeNavigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const AppointmentFormView(),
                              settings: const RouteSettings(name: 'AppointmentFormView'),
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
                            hintText: 'Search appointments...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Filter icon
                                IconButton(
                                  icon: Stack(
                                    children: [
                                      const Icon(Icons.tune, size: 20),
                                      if (_filterStartDate != null ||
                                          _filterEndDate != null ||
                                          _filterTodayOnly ||
                                          _filterUpcomingOnly)
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
                                                                    builder: (context) => AppointmentFilterDialog(
                                                                      initialStartDate: _filterStartDate,
                                                                      initialEndDate: _filterEndDate,
                                                                      initialCompleted: _filterCompleted,
                                                                    ),
                                                                  );
                                                                  if (result != null) {
                                                                    setState(() {
                                                                      _filterStartDate = result['startDate'] as DateTime?;
                                                                      _filterEndDate = result['endDate'] as DateTime?;
                                                                      _filterTodayOnly = result['todayOnly'] as bool? ?? false;
                                                                      _filterUpcomingOnly = result['upcomingOnly'] as bool? ?? false;
                                                                      _filterCompleted = result['completed'] as bool?;
                                                                    });
                                                                  }
                                                                },                                ),
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
            backgroundColor: Colors.grey[100], // Light grey background
            body: provider.appointments.isEmpty
                ? _buildEmptyState(context)
                : _buildAppointmentsList(context, provider, filteredAppointments),
          ),
        );
      },
    );
  }

  void _handleDeleteSelected(BuildContext context, AppointmentProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointments'),
        content: Text('Are you sure you want to delete ${provider.selectedIds.length} appointments?'),
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

    if (confirmed == true) {
      await provider.deleteSelected();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateView(
      icon: Icons.calendar_month_rounded,
      title: 'Your Schedule is Clear',
      description: 'Add upcoming dentist visits, meetings, or coffee dates so you never miss a beat.',
      buttonText: 'Schedule Appointment',
      onPressed: () {
        MainNavigationKeys.homeNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const AppointmentFormView(),
            settings: const RouteSettings(name: 'AppointmentFormView'),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsList(
      BuildContext context, AppointmentProvider provider, List<Appointment> filteredAppointments) {
    if (filteredAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // Sort appointments by date/time
    final sortedAppointments = List<Appointment>.from(filteredAppointments);
    sortedAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Group appointments by Date (Day/Month/Year)
    final groupedAppointments = <String, List<Appointment>>{};
    for (final appointment in sortedAppointments) {
      final dateKey = DateFormat('yyyy-MM-dd').format(appointment.dateTime);
      if (!groupedAppointments.containsKey(dateKey)) {
        groupedAppointments[dateKey] = [];
      }
      groupedAppointments[dateKey]!.add(appointment);
    }

    // Determine scroll physics based on platform
    final scrollPhysics = Platform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: scrollPhysics,
      itemCount: groupedAppointments.length,
      itemBuilder: (context, index) {
        final dateKey = groupedAppointments.keys.elementAt(index);
        final appointmentsForDay = groupedAppointments[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        // Header Text Logic
        String headerText;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final dateToCheck = DateTime(date.year, date.month, date.day);

        if (dateToCheck == today) {
          headerText = 'Today';
        } else if (dateToCheck == tomorrow) {
          headerText = 'Tomorrow';
        } else {
          headerText = DateFormat('EEE, MMM d').format(date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                headerText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Items for this day
            ...appointmentsForDay.map((appointment) => 
              _buildAppointmentCard(context, appointment, provider)
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    // Logic for color bar
    // If Date is Today: Orange (Urgency/Attention)
    // If Date is Future: Blue (Standard/Safe)
    // If Date is Past: Grey
    final isSelected = provider.selectedIds.contains(appointment.id);
    Color statusColor;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(appointment.dateTime.year, appointment.dateTime.month, appointment.dateTime.day);

    if (appointmentDate.isAtSameMomentAs(today)) {
      statusColor = Colors.orange;
    } else if (appointmentDate.isBefore(today)) {
      statusColor = Colors.grey;
    } else {
      statusColor = const Color(0xFF2D62ED); // Brand Blue
    }

    const brandBlue = Color(0xFF2D62ED);
    const selectedBg = Color(0xFFF0F4FF);

    final cardContent = InkWell(
      onTap: () {
        if (provider.isSelectionMode) {
          provider.toggleSelection(appointment.id);
        } else {
          MainNavigationKeys.homeNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => AppointmentFormView(
                appointment: appointment,
              ),
              settings: const RouteSettings(name: 'AppointmentFormView'),
            ),
          );
        }
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        provider.toggleSelection(appointment.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: brandBlue, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Visual Status Indicator (Color Bar)
              Container(
                width: 6,
                color: statusColor,
              ),
              
              // 2. Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Time Column
                      SizedBox(
                        width: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('h:mm').format(appointment.dateTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              DateFormat('a').format(appointment.dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider line
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.only(right: 16),
                      ),

                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                decoration: appointment.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (appointment.location != null && appointment.location!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      appointment.location!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Completion Button (only when not in selection mode)
                      if (!provider.isSelectionMode)
                        IconButton(
                          icon: Icon(
                            appointment.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                            color: appointment.isCompleted ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            provider.toggleCompletion(appointment.id, !appointment.isCompleted);
                          },
                        ),

                      // Chevron or Check
                      if (provider.isSelectionMode)
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: brandBlue,
                        )
                      else if (Platform.isIOS)
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap in Dismissible for swipe-to-delete
    return Dismissible(
      key: Key(appointment.id),
      direction: provider.isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Appointment'),
            content: Text('Are you sure you want to delete ${appointment.title}?'),
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
        provider.deleteAppointment(appointment.id);
      },
      child: cardContent,
    );
  }
}


