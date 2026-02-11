import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/customer_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final Customer customer;

  const EditProfileScreen({super.key, required this.customer});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _companyController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final billing = widget.customer.billing;
    _firstNameController = TextEditingController(
      text: widget.customer.firstName,
    );
    _lastNameController = TextEditingController(text: widget.customer.lastName);
    _companyController = TextEditingController(text: billing?.company ?? '');
    _address1Controller = TextEditingController(text: billing?.address1 ?? '');
    _address2Controller = TextEditingController(text: billing?.address2 ?? '');
    _cityController = TextEditingController(text: billing?.city ?? '');
    _postcodeController = TextEditingController(text: billing?.postcode ?? '');
    _countryController = TextEditingController(text: billing?.country ?? '');
    _stateController = TextEditingController(text: billing?.state ?? '');
    _phoneController = TextEditingController(text: billing?.phone ?? '');
    _emailController = TextEditingController(text: widget.customer.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _saveChanges() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateCustomerDetails(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      company: _companyController.text.trim(),
      address1: _address1Controller.text.trim(),
      address2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      postcode: _postcodeController.text.trim(),
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_updated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_update_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: authProvider.isUpdatingCustomer
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                children: [_buildProfilePhotoSection(), _buildFormSection()],
              ),
            ),
      bottomNavigationBar: authProvider.isUpdatingCustomer
          ? null
          : _buildBottomButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: Text(
        l10n.edit_profile,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfilePhotoSection() {
    final l10n = AppLocalizations.of(context)!;
    ImageProvider backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!);
    } else {
      backgroundImage = NetworkImage(widget.customer.avatarUrl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundImage: backgroundImage),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.edit_photo),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _removeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.remove_btn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.personal_details),
          _buildPersonalInfoCard(),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.billing_address),
          _buildBillingInfoCard(),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.contact_details),
          _buildContactInfoCard(),
          const SizedBox(height: 100), // Space for bottom buttons
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 5),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: l10n.first_name,
            controller: _firstNameController,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: l10n.last_name,
            controller: _lastNameController,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: l10n.company_label,
            controller: _companyController,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: l10n.address1_label,
            controller: _address1Controller,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: l10n.address2_label,
            controller: _address2Controller,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: l10n.city_label,
                  controller: _cityController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  label: l10n.postcode_label,
                  controller: _postcodeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: l10n.country_label,
                  controller: _countryController,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  label: l10n.state_label,
                  controller: _stateController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTextField(
            label: l10n.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: l10n.phone_number,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            isDense: true,
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.discard_btn,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.save_changes_btn,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
