import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../viewmodels/shared_alarm_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../models/shared_alarm_model.dart';
import 'widgets/custom_loader.dart';

class SharedAlarmDetailsScreen extends StatefulWidget {
  final String alarmId;
  const SharedAlarmDetailsScreen({super.key, required this.alarmId});

  @override
  State<SharedAlarmDetailsScreen> createState() =>
      _SharedAlarmDetailsScreenState();
}

class _SharedAlarmDetailsScreenState extends State<SharedAlarmDetailsScreen> {
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SharedAlarmViewModel>(
        context,
        listen: false,
      ).loadAlarm(widget.alarmId);
    });

    // Start tick to update UI countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeLeft();
      }
    });
  }

  void _updateTimeLeft() {
    final vm = Provider.of<SharedAlarmViewModel>(context, listen: false);
    final alarm = vm.currentAlarm;
    if (alarm != null && alarm.status == SharedAlarmStatus.active) {
      final now = DateTime.now().toUtc();
      final left = alarm.triggerTime.difference(now);
      setState(() {
        _timeLeft = left.isNegative ? Duration.zero : left;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _shareCode(String code) {
    Share.share('Join my Shared Alarm on ShareTime! Code: $code');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SharedAlarmViewModel>();
    final participantVM = context.watch<ParticipantViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (viewModel.isLoading && viewModel.currentAlarm == null) {
      return const Scaffold(body: CustomLoader(label: 'Loading Alarm...'));
    }

    if (viewModel.error != null && viewModel.currentAlarm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(viewModel.error!)),
      );
    }

    final alarm = viewModel.currentAlarm;
    if (alarm == null)
      return const Scaffold(body: Center(child: Text('Alarm not found')));

    final isCreator = alarm.creatorId == participantVM.getUserId();
    final isParticipating = viewModel.participants.any(
      (p) => p.userId == participantVM.getUserId(),
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Shared Alarm Details'),
        actions: [
          if (isCreator && alarm.status == SharedAlarmStatus.active)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: 'Cancel Alarm',
              onPressed: () => _confirmCancel(context, viewModel, alarm.id),
            )
          else if (!isCreator && isParticipating)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
              tooltip: 'Leave Alarm',
              onPressed: () => _confirmLeave(
                context,
                viewModel,
                alarm.id,
                participantVM.getUserId(),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 8,
              shadowColor: colorScheme.tertiary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      alarm.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (alarm.description != null &&
                        alarm.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        alarm.description!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Status or Countdown
                    _buildStatusDisplay(alarm, colorScheme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Share Code Section
            if (alarm.status == SharedAlarmStatus.active)
              Card(
                child: ListTile(
                  title: Text(
                    'Share Code: ${alarm.shareCode}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyCode(alarm.shareCode),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareCode(alarm.shareCode),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Participant List
            Text(
              'Participants (${viewModel.participants.length}${alarm.maxParticipants != null ? '/${alarm.maxParticipants}' : ''})',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.participants.length,
              itemBuilder: (context, idx) {
                final p = viewModel.participants[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  child: ListTile(
                    leading: Text(
                      p.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      p.displayName,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: p.userId == alarm.creatorId
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Host',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay(SharedAlarmModel alarm, ColorScheme color) {
    if (alarm.status == SharedAlarmStatus.cancelled) {
      return Text(
        'CANCELLED',
        style: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    } else if (alarm.status == SharedAlarmStatus.triggered ||
        _timeLeft.inSeconds <= 0 && alarm.status == SharedAlarmStatus.active) {
      // It might be physically past time but Firestore hasn't updated yet, just show Triggered visually
      return Text(
        'TRIGGERED',
        style: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: color.secondary,
        ),
      );
    } else {
      // Formatting time left
      int hours = _timeLeft.inHours;
      int mins = _timeLeft.inMinutes.remainder(60);
      int secs = _timeLeft.inSeconds.remainder(60);

      String timeString =
          '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      return Column(
        children: [
          Text(
            'Triggers in',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            timeString,
            style: GoogleFonts.montserrat(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: color.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Local Time: ${alarm.triggerTime.toLocal().toString().split('.')[0]}',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      );
    }
  }

  void _confirmCancel(
    BuildContext context,
    SharedAlarmViewModel vm,
    String alarmId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Alarm?'),
        content: const Text('This will cancel the alarm for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.cancelAlarm(alarmId).then((success) {
                if (success && mounted) Navigator.pop(context);
              });
            },
            child: const Text(
              'YES, CANCEL',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(
    BuildContext context,
    SharedAlarmViewModel vm,
    String alarmId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Alarm?'),
        content: const Text('You will no longer receive this alarm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.leaveAlarm(alarmId, userId).then((success) {
                if (success && mounted) Navigator.pop(context);
              });
            },
            child: const Text('LEAVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
