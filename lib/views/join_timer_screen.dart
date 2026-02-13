import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/timer_viewmodel.dart';
import '../utils/constants.dart';
import 'timer_detail_screen.dart';
import 'widgets/custom_loader.dart';

/// Join Timer Screen
///
/// Allows users to join an existing timer using a share code.
/// Validates the code and navigates to the timer detail screen.
class JoinTimerScreen extends StatefulWidget {
  const JoinTimerScreen({super.key});

  @override
  State<JoinTimerScreen> createState() => _JoinTimerScreenState();
}

class _JoinTimerScreenState extends State<JoinTimerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Join Timer',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
      ),
      body: Consumer<TimerViewModel>(
        builder: (context, timerViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Clean Icon Container
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_rounded,
                        size: 64,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Code input
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENTER SHARE CODE',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              hintText: 'ABC123',
                              hintStyle: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 32,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLength: AppConstants.shareCodeLength,
                            textCapitalization: TextCapitalization.characters,
                            style: GoogleFonts.montserrat(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                              letterSpacing: 8,
                            ),
                            textAlign: TextAlign.center,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a share code';
                              }
                              if (value.length !=
                                  AppConstants.shareCodeLength) {
                                return 'Code must be ${AppConstants.shareCodeLength} characters';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              // Auto-uppercase
                              if (value != value.toUpperCase()) {
                                _codeController.value = _codeController.value
                                    .copyWith(
                                      text: value.toUpperCase(),
                                      selection: TextSelection.collapsed(
                                        offset: value.length,
                                      ),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (timerViewModel.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              timerViewModel.error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: timerViewModel.isLoading ? null : _joinTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: colorScheme.secondary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: timerViewModel.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CustomLoader(
                                size: 24,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'JOIN TIMER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ask your friend for the 6-character code shown on their screen.',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _joinTimer() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final timerViewModel = Provider.of<TimerViewModel>(context, listen: false);

    // Join timer
    final timer = await timerViewModel.joinTimer(_codeController.text);

    if (timer != null && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successTimerJoined),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to timer detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TimerDetailScreen(timerId: timer.id),
        ),
      );
    }
  }
}
