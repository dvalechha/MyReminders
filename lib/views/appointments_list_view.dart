import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/navigation_model.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../widgets/smart_list_tile.dart';
import '../widgets/appointment_filter_dialog.dart';
import '../utils/appointment_status_helper.dart';
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
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
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

        return Scaffold(
          appBar: AppBar(
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
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _filterStartDate = result['startDate'] as DateTime?;
                                _filterEndDate = result['endDate'] as DateTime?;
                                _filterTodayOnly = result['todayOnly'] as bool? ?? false;
                                _filterUpcomingOnly = result['upcomingOnly'] as bool? ?? false;
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
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      color: Colors.grey[100], // Light grey background
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Appointments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first appointment',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

    // Determine scroll physics based on platform
    final scrollPhysics = Platform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      physics: scrollPhysics,
      itemCount: sortedAppointments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = sortedAppointments[index];
        return _buildAppointmentCard(context, appointment, provider);
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    final statusColor = getAppointmentStatusColor(appointment.dateTime);

    final cardContent = SmartListTile(
      statusColor: statusColor,
      onTap: () {
        MainNavigationKeys.homeNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AppointmentFormView(
              appointment: appointment,
            ),
            settings: const RouteSettings(name: 'AppointmentFormView'),
          ),
        );
      },
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Leading: Time column (e.g., "3:00\nPM")
            Container(
              width: 60,
              child: Text(
                formatAppointmentTime(appointment.dateTime),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Center: Title and Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Appointment Title (Bold)
                  Text(
                    appointment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Row 2: Location with icon
                  if (appointment.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Trailing: Chevron right (adaptive icon)
            if (Platform.isIOS)
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
    );

    // Wrap in Dismissible for swipe-to-delete
    return Dismissible(
      key: Key(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
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

