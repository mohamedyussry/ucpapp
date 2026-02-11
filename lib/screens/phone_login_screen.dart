import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import 'package:myapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/language_toggle.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String _phoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getAppSignature();
  }

  Future<void> _getAppSignature() async {
    // For sms_autofill to work, the SMS must contain this signature at the end.
    // Example SMS: <#> Your code is: 1234 7yX+Y5z6A8B
    try {
      final signature = await SmsAutoFill().getAppSignature;
      developer.log("SMS App Signature: $signature");
    } catch (e) {
      developer.log("Error getting signature: $e");
    }
  }

  void _showPhoneHint() async {
    try {
      final phone = await SmsAutoFill().hint;
      if (phone != null && mounted) {
        // Remove country code if present (assuming +966)
        String cleaned = phone;
        if (cleaned.startsWith('+966')) {
          cleaned = cleaned.replaceFirst('+966', '');
        } else if (cleaned.startsWith('966')) {
          cleaned = cleaned.replaceFirst('966', '');
        }

        setState(() {
          _phoneController.text = cleaned;
        });
      }
    } catch (e) {
      developer.log("Error getting phone hint: $e");
    }
  }

  void _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Format phone number: The user now inputs ONLY the mobile number (e.g. 5XXXXXXX)
      String input = _phoneNumber.trim();

      // Remove leading zero if the user typed it (e.g., 05XXXXX -> 5XXXXX)
      if (input.startsWith('0')) {
        input = input.substring(1);
      }

      // The final number should be 966 + the cleaned input
      final String formattedPhone = '966$input';

      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      developer.log('Sending OTP to: $formattedPhone'); // DEBUG
      final success = await authProvider.sendOtp(formattedPhone);

      developer.log('SendOtp Result: $success'); // DEBUG LOG

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          developer.log(
            'Attempting navigation to /otp_verification',
          ); // DEBUG LOG

          // Ensure UI setstate is done
          await Future.delayed(Duration.zero);
          if (!mounted) return;

          // Success: Navigate immediately without delay to test
          Navigator.pushNamed(
            context,
            '/otp_verification',
            arguments: formattedPhone,
          );
        } else {
          // Failure: Show detailed error dialog so user can read it
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.connection_failed),
              content: Text(
                authProvider.loginErrorMessage ?? l10n.unknown_error,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                SizedBox(
                  height: 150,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.phone_login,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.enter_phone_subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phone_number,
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+966 ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: l10n.enter_phone_hint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.err_enter_phone;
                    }
                    // Basic validation for Saudi number length after removing leading 0
                    String cleaned = value.trim();
                    if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
                    if (cleaned.length != 9) {
                      return l10n.err_invalid_phone;
                    }
                    return null;
                  },
                  onSaved: (value) => _phoneNumber = value!,
                  controller: _phoneController,
                  onTap: () {
                    if (_phoneController.text.isEmpty) {
                      _showPhoneHint();
                    }
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.send_code,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/email_login');
                  },
                  child: Text(
                    l10n.login_email,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                // Guest Login Button
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to Home as Guest
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon: const Icon(
                    Icons.person_3_outlined,
                    color: Colors.black87,
                  ),
                  label: Text(
                    l10n.login_guest,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
