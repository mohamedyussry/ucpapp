import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/screens/edit_profile_screen.dart';
import 'package:myapp/my_orders_screen.dart';
import 'package:myapp/screens/my_points_screen.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import 'package:myapp/screens/phone_login_screen.dart';

import '../l10n/generated/app_localizations.dart';
import 'package:myapp/providers/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Use state variable instead of Dialog for loading to avoid context issues
  bool _isDeleting = false;

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.delete_account_confirm,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.delete_account_warning,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel_btn,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation dialog

              setState(() {
                _isDeleting = true;
              });

              bool success = false;
              try {
                // Attempt to delete with a UI-level timeout for safety
                success = await authProvider
                    .deleteAccount(autoLogout: false)
                    .timeout(const Duration(seconds: 15));
              } catch (e) {
                debugPrint('Delete account error: $e');
                success = false;
              }

              if (mounted) {
                setState(() {
                  _isDeleting = false;
                });

                if (success) {
                  // Manually logout to clear state and trigger UI switch
                  await authProvider.logout();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Navigate to home and clear stack
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to delete account. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              l10n.delete_btn,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.select_language,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('English', style: GoogleFonts.poppins()),
                trailing: languageProvider.appLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.orange)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('العربية', style: GoogleFonts.poppins()),
                trailing: languageProvider.appLocale.languageCode == 'ar'
                    ? const Icon(Icons.check, color: Colors.orange)
                    : null,
                onTap: () {
                  languageProvider.changeLanguage(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.grey[100],
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    tooltip: l10n.go_back,
                  ),
                ),
              ),
            ),
            title: Text(
              l10n.profile,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              if (authProvider.status == AuthStatus.authenticated)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () => authProvider.logout(),
                        tooltip: l10n.logout,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, authProvider, languageProvider, l10n),
          bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 4),
        ),
        if (_isDeleting)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthProvider authProvider,
    LanguageProvider languageProvider,
    AppLocalizations l10n,
  ) {
    switch (authProvider.status) {
      case AuthStatus.uninitialized:
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        );
      case AuthStatus.authenticated:
        if (authProvider.customer != null) {
          return _buildProfileView(
            context,
            authProvider.customer!,
            authProvider,
            languageProvider,
            l10n,
          );
        } else {
          // This should ideally not happen if status is authenticated
          return _buildLoginView(context);
        }
      case AuthStatus.unauthenticated:
        return _buildLoginView(context);
    }
  }

  Widget _buildLoginView(BuildContext context) {
    return const PhoneLoginScreen();
  }

  Widget _buildProfileView(
    BuildContext context,
    Customer customer,
    AuthProvider authProvider,
    LanguageProvider languageProvider,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(customer.avatarUrl),
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text(
          '${customer.firstName} ${customer.lastName}',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          customer.username,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfileScreen(customer: customer),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    l10n.edit_profile,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showDeleteAccountDialog(context, authProvider, l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    l10n.delete_account,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection(l10n.my_account, [
                    _buildProfileOption(
                      icon: FontAwesomeIcons.user,
                      title: l10n.personal_info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: FontAwesomeIcons.box,
                      title: l10n.my_orders,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: FontAwesomeIcons.coins,
                      title: l10n.my_points,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyPointsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: FontAwesomeIcons.globe,
                      title: l10n.language,
                      trailing: Text(
                        languageProvider.appLocale.languageCode == 'ar'
                            ? 'العربية'
                            : 'English',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                      onTap: () => _showLanguageSelector(context),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection(l10n.notification, [
                    _buildNotificationOption(
                      title: l10n.push_notification,
                      value: true,
                    ),
                    _buildProfileOption(
                      icon: FontAwesomeIcons.arrowsRotate,
                      title: authProvider.isSyncingFcm
                          ? l10n.syncing
                          : l10n.sync_notifications,
                      trailing: authProvider.isSyncingFcm
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: () async {
                        bool success = await authProvider.syncFcmToken();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? l10n.sync_success : l10n.sync_failed,
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10, top: 10),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: iconColor ?? Colors.black87, size: 20),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required bool value,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      value: value,
      onChanged: (bool newValue) {},
      activeTrackColor: Colors.orange[200],
      activeThumbColor: Colors.orange,
    );
  }
}
