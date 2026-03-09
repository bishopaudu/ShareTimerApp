import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shared_alarm_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../utils/constants.dart';
import 'shared_alarm_details_screen.dart';

class JoinSharedAlarmScreen extends StatefulWidget {
  const JoinSharedAlarmScreen({super.key});

  @override
  State<JoinSharedAlarmScreen> createState() => _JoinSharedAlarmScreenState();
}

class _JoinSharedAlarmScreenState extends State<JoinSharedAlarmScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinAlarm() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<SharedAlarmViewModel>(
        context,
        listen: false,
      );
      final participantVM = Provider.of<ParticipantViewModel>(
        context,
        listen: false,
      );

      final userProfile = participantVM.userProfile;
      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please update your profile first.')),
        );
        return;
      }

      final alarmId = await viewModel.joinAlarmWithCode(
        _codeController.text.trim().toUpperCase(),
        userProfile,
      );

      if (mounted) {
        if (alarmId != null) {
          // Success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SharedAlarmDetailsScreen(alarmId: alarmId),
            ),
          );
        } else if (viewModel.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error!),
              backgroundColor: Colors.red,
            ),
          );
          viewModel.clearError();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<SharedAlarmViewModel>().isLoading;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(title: const Text('Join Shared Alarm')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Icon(
                      Icons.alarm_add,
                      size: 100,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: AppConstants.shareCodeLength,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit Code',
                        counterText: '',
                        alignLabelWithHint: true,
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) {
                        if (val == null ||
                            val.length != AppConstants.shareCodeLength) {
                          return 'Code must be exactly ${AppConstants.shareCodeLength} characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),

                    // Join Button
                    ElevatedButton(
                      onPressed: _joinAlarm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('JOIN ALARM'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
