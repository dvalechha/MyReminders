import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/navigation_model.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../widgets/app_navigation_drawer.dart';
import 'appointment_form_view.dart';
import 'main_navigation_view.dart';

class AppointmentsListView extends StatefulWidget {
  const AppointmentsListView({super.key});

  @override
  State<AppointmentsListView> createState() => _AppointmentsListViewState();
}

class _AppointmentsListViewState extends State<AppointmentsListView> {
  String _searchText = '';

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
    if (searchText.isEmpty) {
      return appointments;
    }

    final lowerSearchText = searchText.toLowerCase();
    return appointments.where((appointment) {
      final title = appointment.title.toLowerCase();
      final category = (appointment.category ?? '').toLowerCase();
      final notes = (appointment.notes ?? '').toLowerCase();

      return title.contains(lowerSearchText) ||
          category.contains(lowerSearchText) ||
          notes.contains(lowerSearchText);
    }).toList();
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

        final filteredAppointments =
            _filterAppointments(provider.appointments, _searchText);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Appointments'),
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
          body: provider.appointments.isEmpty
              ? _buildEmptyState(context)
              : _buildAppointmentsList(context, provider, filteredAppointments),
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
    );
  }

  Widget _buildAppointmentsList(
      BuildContext context, AppointmentProvider provider, List<Appointment> filteredAppointments) {
    return filteredAppointments.isEmpty
        ? Padding(
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
          )
        : ListView.builder(
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              final appointment = filteredAppointments[index];
              return _buildAppointmentRow(context, appointment, provider);
            },
          );
  }

  Widget _buildAppointmentRow(
    BuildContext context,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    return Dismissible(
      key: Key(appointment.id),
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
      child: ListTile(
        title: Text(
          appointment.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (appointment.category != null)
              Text(
                appointment.category!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MMM d, yyyy').format(appointment.dateTime)} at ${DateFormat('h:mm a').format(appointment.dateTime)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
            if (appointment.location != null)
              Text(
                'Location: ${appointment.location}',
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
              builder: (context) => AppointmentFormView(
                appointment: appointment,
              ),
              settings: const RouteSettings(name: 'AppointmentFormView'),
            ),
          );
        },
      ),
    );
  }
}

