import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_model.dart';
import '../models/participant_model.dart';
import '../models/alarm_model.dart';
import '../viewmodels/timer_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../viewmodels/alarm_viewmodel.dart';
import '../services/timer_calculation_service.dart';
import 'widgets/custom_loader.dart';
import '../utils/constants.dart';
import 'widgets/countdown_display.dart';
import 'widgets/participant_list.dart';
import 'widgets/alarm_list.dart';

/// Timer Detail Screen
///
/// Displays a live countdown timer with real-time updates.
/// Shows participants, alarms, and provides sharing functionality.
class TimerDetailScreen extends StatefulWidget {
  final String timerId;

  const TimerDetailScreen({super.key, required this.timerId});

  @override
  State<TimerDetailScreen> createState() => _TimerDetailScreenState();
}

class _TimerDetailScreenState extends State<TimerDetailScreen> {
  late final ParticipantViewModel _participantViewModel;

  @override
  void initState() {
    super.initState();
    _participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinAsParticipant();
    });
  }

  @override
  void dispose() {
    _leaveAsParticipant();
    super.dispose();
  }

  /// Join this timer as a participant
  Future<void> _joinAsParticipant() async {
    await _participantViewModel.joinTimer(timerId: widget.timerId);
  }

  /// Leave this timer when screen is disposed
  Future<void> _leaveAsParticipant() async {
    await _participantViewModel.leaveTimer(widget.timerId);
  }

  @override
  Widget build(BuildContext context) {
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);
    final participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );
    final alarmViewModel = Provider.of<AlarmViewModel>(context, listen: false);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'TIMER DETAILS',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
        actions: [
          // Delete timer button (only for creator)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400]),
            tooltip: 'Delete Timer',
            onPressed: () => _confirmDeleteTimer(context),
          ),
        ],
      ),
      body: StreamBuilder<TimerModel?>(
        stream: timerViewModel.getTimerStream(widget.timerId),
        builder: (context, timerSnapshot) {
          // Loading state
          if (timerSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: CustomLoader(label: 'Loading Timer...'),
            );
          }

          // Error state
          if (timerSnapshot.hasError || !timerSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.errorTimerNotFound,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('GO BACK'),
                  ),
                ],
              ),
            );
          }

          final timer = timerSnapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled by the stream
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Countdown display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CountdownDisplay(timer: timer),
                  ),
                  const SizedBox(height: 32),

                  // Share code card
                  _buildShareCodeCard(context, timer),
                  const SizedBox(height: 24),

                  // Participants list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'PARTICIPANTS',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ParticipantModel>>(
                    stream: participantViewModel.getParticipantsStream(
                      widget.timerId,
                    ),
                    builder: (context, participantSnapshot) {
                      final participants = participantSnapshot.data ?? [];
                      return ParticipantList(participants: participants);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Alarms list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALARMS',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<AlarmModel>>(
                    stream: alarmViewModel.getAlarmsStream(widget.timerId),
                    builder: (context, alarmSnapshot) {
                      final alarms = alarmSnapshot.data ?? [];
                      return AlarmList(
                        alarms: alarms,
                        timer: timer,
                        onDelete: (alarm) => _deleteAlarm(alarm),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Add alarm button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddAlarmDialog(context, timer),
                      icon: const Icon(Icons.add_alarm_rounded),
                      label: const Text('ADD ALARM'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: colorScheme.secondary,
                          width: 2,
                        ),
                        foregroundColor: colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareCodeCard(BuildContext context, TimerModel timer) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHARE CODE',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timer.shareCode,
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.vpn_key_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyShareCode(timer.shareCode),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('COPY'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareTimer(timer),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('INVITE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyShareCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareTimer(TimerModel timer) {
    Share.share(
      'Join my timer "${timer.title}"!\n\n'
      'Use code: ${timer.shareCode}\n\n'
      'Duration: ${TimerCalculationService.formatDurationHumanReadable(timer.durationSeconds)}',
      subject: 'Join my shared timer',
    );
  }

  void _showAddAlarmDialog(BuildContext context, TimerModel timer) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int hours = 0;
    int minutes = 1;
    int seconds = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Alarm'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Title',
                    hintText: 'e.g., 5 minutes left',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Trigger after:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallTimePicker(
                      label: 'H',
                      value: hours,
                      max: 23,
                      onChanged: (value) => setState(() => hours = value),
                    ),
                    _buildSmallTimePicker(
                      label: 'M',
                      value: minutes,
                      max: 59,
                      onChanged: (value) => setState(() => minutes = value),
                    ),
                    _buildSmallTimePicker(
                      label: 'S',
                      value: seconds,
                      max: 59,
                      onChanged: (value) => setState(() => seconds = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            Consumer<AlarmViewModel>(
              builder: (context, alarmViewModel, child) => TextButton(
                onPressed: alarmViewModel.isLoading
                    ? null
                    : () => _addAlarm(
                        dialogContext,
                        formKey,
                        titleController.text,
                        hours,
                        minutes,
                        seconds,
                        timer,
                      ),
                child: alarmViewModel.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTimePicker({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up, size: 20),
          onPressed: () {
            if (value < max) onChanged(value + 1);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          onPressed: () {
            if (value > 0) onChanged(value - 1);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _addAlarm(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    String title,
    int hours,
    int minutes,
    int seconds,
    TimerModel timer,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final triggerSeconds = TimerCalculationService.toSeconds(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );

    final alarmViewModel = Provider.of<AlarmViewModel>(context, listen: false);
    final participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );

    final success = await alarmViewModel.addAlarm(
      timerId: widget.timerId,
      timer: timer,
      title: title,
      triggerSeconds: triggerSeconds,
      createdBy: participantViewModel.getUserId(),
    );

    if (success && mounted) {
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successAlarmAdded),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && alarmViewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alarmViewModel.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlarm(AlarmModel alarm) async {
    final alarmViewModel = Provider.of<AlarmViewModel>(context, listen: false);

    final success = await alarmViewModel.removeAlarm(
      timerId: widget.timerId,
      alarmId: alarm.id,
      notificationId: alarm.notificationId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDeleteTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timer'),
        content: const Text(
          'Are you sure you want to delete this timer? '
          'This action cannot be undone and will remove it for all participants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTimer();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimer() async {
    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);

    final success = await timerViewModel.deleteTimer(widget.timerId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer deleted'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
