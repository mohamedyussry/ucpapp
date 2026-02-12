import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../l10n/generated/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  // Controllers for 4 digits
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;

  // Timer related state
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    listenForCode();
    _printSignature();
  }

  void _printSignature() async {
    final signature = await SmsAutoFill().getAppSignature;
    developer.log("OTP App Signature: $signature");
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      // Distribute code to controllers
      // Our code generates 4 digits.
      // Sometime code might include non-digits, let's filter just in case, though library is smart.
      String pin = code!;
      if (pin.length > 4) pin = pin.substring(0, 4); // Take first 4

      for (int i = 0; i < 4; i++) {
        if (i < pin.length) {
          _controllers[i].text = pin[i];
        }
      }

      if (pin.length == 4) {
        FocusScope.of(context).unfocus();
        _verifyOtp();
      }
    }
  }

  void startTimer() {
    _start = 60;
    _canResend = false;
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    cancel(); // Cancel auto-fill listener
    unregisterListener();
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentOtp {
    return _controllers.map((e) => e.text).join();
  }

  Future<void> _resendCode() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneNumber = ModalRoute.of(context)?.settings.arguments as String?;
    if (phoneNumber == null) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(phoneNumber);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.otp_resent),
            backgroundColor: Colors.green,
          ),
        );
        startTimer(); // Restart timer
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.loginErrorMessage ?? l10n.otp_failed_resend,
            ),
          ),
        );
      }
    }
  }

  void _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final otp = _currentOtp;
    if (otp.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.otp_enter_full)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyOtp(otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result == 1) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.loginErrorMessage ?? l10n.otp_invalid),
          ),
        );
        // Clear fields on error for UX
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Widget _buildOtpDigitField({required int index}) {
    return SizedBox(
      width: 60,
      height: 65,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        autofillHints: const [AutofillHints.oneTimeCode],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < 3) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else {
              // Reached the end, maybe auto-submit?
              FocusScope.of(context).unfocus();
              _verifyOtp();
            }
          } else {
            // Move to previous field on delete (optional, simpler logic here)
            if (index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phoneNumber = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.lock_person_outlined,
                size: 80,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 30),
              Text(
                l10n.otp_title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${l10n.otp_subtitle}\n${phoneNumber ?? l10n.otp_your_phone}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 50),

              // 4 Digit Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => _buildOtpDigitField(index: index),
                ),
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        l10n.verify,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              // Resend Timer
              Center(
                child: _canResend
                    ? TextButton.icon(
                        onPressed: _resendCode,
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: Text(
                          l10n.resend_code,
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          text: l10n.resend_in,
                          style: GoogleFonts.poppins(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: '00:${_start.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
