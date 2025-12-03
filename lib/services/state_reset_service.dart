import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/navigation_model.dart';

/// Service to reset all in-memory app state
class StateResetService {
  static final StateResetService instance = StateResetService._init();

  StateResetService._init();

  /// Clear all in-memory state from all providers
  /// This resets all providers to their initial state
  Future<void> clearInMemoryState(BuildContext context) async {
    try {
      // Reset SubscriptionProvider
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.clearState();

      // Reset AppointmentProvider
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      appointmentProvider.clearState();

      // Reset TaskProvider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.clearState();

      // Reset UserProfileProvider
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      userProfileProvider.clearProfile();

      // Reset NavigationModel (pop to root)
      final navigationModel = Provider.of<NavigationModel>(context, listen: false);
      navigationModel.popToRoot();
    } catch (e) {
      throw Exception('Failed to clear in-memory state: $e');
    }
  }
}

