import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shared_alarm_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../utils/constants.dart';
import 'shared_alarm_details_screen.dart';

class CreateSharedAlarmScreen extends StatefulWidget {
  const CreateSharedAlarmScreen({super.key});

  @override
  State<CreateSharedAlarmScreen> createState() =>
      _CreateSharedAlarmScreenState();
}

class _CreateSharedAlarmScreenState extends State<CreateSharedAlarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _limitController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _enableLimit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _createAlarm() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
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

      final triggerTimeLocal = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      int? maxParticipants;
      if (_enableLimit && _limitController.text.isNotEmpty) {
        maxParticipants = int.tryParse(_limitController.text);
      }

      final alarmId = await viewModel.createAlarm(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        triggerTime: triggerTimeLocal, // We pass Local, VM converts to UTC
        maxParticipants: maxParticipants,
        userProfile: userProfile,
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
    } else if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trigger date & time.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = context.watch<SharedAlarmViewModel>().isLoading;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(title: const Text('New Shared Alarm')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Alarm Title *',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // DateTime Picker
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text(
                          _selectedDate == null
                              ? 'Select Date & Time *'
                              : 'Trigger Time',
                        ),
                        subtitle: _selectedDate != null
                            ? Text(
                                '${_selectedDate.toString().split(' ')[0]} ${_selectedTime!.format(context)}',
                              )
                            : null,
                        trailing: const Icon(Icons.calendar_month),
                        onTap: _selectDateTime,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Participant Limit
                    SwitchListTile(
                      title: const Text('Limit Participants'),
                      value: _enableLimit,
                      onChanged: (val) {
                        setState(() => _enableLimit = val);
                      },
                    ),
                    if (_enableLimit) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Participants',
                        ),
                        validator: (val) {
                          if (_enableLimit && (val == null || val.isEmpty))
                            return 'Limit required';
                          if (_enableLimit && int.tryParse(val!) == null)
                            return 'Must be a number';
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 48),

                    // Create Button
                    ElevatedButton(
                      onPressed: _createAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme.tertiary, // Use amber accent
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('CREATE SHARED ALARM'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
