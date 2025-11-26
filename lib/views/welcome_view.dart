import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/custom_reminder_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/logout_service.dart';
import '../utils/snackbar.dart';
import 'subscription_form_view.dart';
import 'subscriptions_list_view.dart';
import 'appointment_form_view.dart';
import 'appointments_list_view.dart';
import 'task_form_view.dart';
import 'tasks_list_view.dart';
import 'custom_reminder_form_view.dart';
import 'custom_reminders_list_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  void initState() {
    super.initState();
    // Load user profile when view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      profileProvider.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminder'),
        actions: [
          // Display name or email fallback
          Consumer<UserProfileProvider>(
            builder: (context, profileProvider, child) {
              final displayText = profileProvider.getDisplayNameOrEmail();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            },
          ),
          // Logout button with fade animation on tap
          _LogoutIconButton(
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose what you\'d like to set up first.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _buildCategoryList(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Call LogoutService directly as per prompt requirements
      // This handles: clear local state, clear caches, Supabase signOut, splash screen, and routing
      await LogoutService.instance.logout(context);
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, 'Failed to sign out: $e');
      }
    }
  }

  Widget _buildCategoryList(BuildContext context) {
    return Column(
      children: [
        Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Subscriptions',
              icon: Icons.credit_card,
              onTap: () {
                if (subscriptionProvider.subscriptions.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionsListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<AppointmentProvider>(
          builder: (context, appointmentProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Appointments',
              icon: Icons.calendar_today,
              onTap: () {
                if (appointmentProvider.appointments.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentsListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Tasks',
              icon: Icons.check_circle_outline,
              onTap: () {
                if (taskProvider.tasks.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<CustomReminderProvider>(
          builder: (context, customReminderProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Custom',
              icon: Icons.notifications_outlined,
              onTap: () {
                if (customReminderProvider.customReminders.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomRemindersListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomReminderFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCardRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Logout icon button with fade animation on tap
/// Ensures proper tap area (48x48 by default in IconButton) and accessibility
class _LogoutIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _LogoutIconButton({
    required this.onPressed,
  });

  @override
  State<_LogoutIconButton> createState() => _LogoutIconButtonState();
}

class _LogoutIconButtonState extends State<_LogoutIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: null, // Handled by GestureDetector
              // IconButton provides 48x48 tap area by default (exceeds 44x44 requirement)
            ),
          );
        },
      ),
    );
  }
}

