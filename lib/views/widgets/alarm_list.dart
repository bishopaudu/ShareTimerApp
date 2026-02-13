import 'package:flutter/material.dart';
import '../../models/alarm_model.dart';
import '../../models/timer_model.dart';
import '../../services/timer_calculation_service.dart';

/// Widget displaying the list of alarms for a timer
///
/// Shows all alarms with their trigger times and allows deletion.
class AlarmList extends StatelessWidget {
  final List<AlarmModel> alarms;
  final TimerModel timer;
  final Function(AlarmModel) onDelete;

  const AlarmList({
    super.key,
    required this.alarms,
    required this.timer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'No active alerts',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alarms.length,
        padding: const EdgeInsets.all(8),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.grey[100],
        ),
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          final hasTriggered = alarm.hasTriggered(timer.startTime);
          final triggerTime = alarm.getTriggerTime(timer.startTime);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildAlarmIcon(context, hasTriggered),
            title: Text(
              alarm.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: hasTriggered ? TextDecoration.lineThrough : null,
                color: hasTriggered ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: hasTriggered ? Colors.grey : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${TimerCalculationService.formatTime(triggerTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasTriggered ? Colors.grey : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!hasTriggered) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Triggers at ${TimerCalculationService.formatDurationHumanReadable(alarm.triggerSeconds)} mark',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300]),
              onPressed: () => _confirmDelete(context, alarm),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlarmIcon(BuildContext context, bool hasTriggered) {
    if (hasTriggered) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.alarm_off_rounded,
          color: Colors.grey,
          size: 20,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.notifications_active_rounded,
        color: Theme.of(context).colorScheme.secondary,
        size: 20,
      ),
    );
  }

  void _confirmDelete(BuildContext context, AlarmModel alarm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text('Are you sure you want to delete "${alarm.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(alarm);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
