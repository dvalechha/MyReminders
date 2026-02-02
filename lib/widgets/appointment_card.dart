import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';

/// Appointment card with "Ghost Card" UI for pending completion
/// Maintains the status bar and time display from the original design
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isSelected;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isSelected,
    required this.statusColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        final isPending = provider.isAppointmentPendingCompletion(appointment.id);

        if (isPending) {
          return _buildGhostCard(context, provider);
        } else {
          return _buildNormalCard(context, provider);
        }
      },
    );
  }

  Widget _buildGhostCard(BuildContext context, AppointmentProvider provider) {
    final duration = provider.getCompletionTimerDuration(appointment.id) ?? 10;
    final totalSeconds = duration.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: totalSeconds, end: 0.0),
      duration: Duration(seconds: duration),
      builder: (context, value, child) {
        final remainingSeconds = value.ceil();
        final progress = value / totalSeconds;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.green.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 12),
              // Appointment title
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Undo button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Marking as complete...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.undoAppointmentCompletion(appointment.id),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text('Undo (${remainingSeconds}s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalCard(BuildContext context, AppointmentProvider provider) {
    const brandBlue = Color(0xFF2D62ED);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              border: isSelected ? Border.all(color: brandBlue, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              DateFormat('a').format(appointment.dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
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

                      // Trailing icon (chevron or check if selected)
                      if (isSelected)
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: brandBlue,
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      else if (!provider.isSelectionMode)
                        Platform.isIOS
                            ? const Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: Colors.grey,
                              )
                            : const Icon(
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
        ),
      ),
    );
  }
}
