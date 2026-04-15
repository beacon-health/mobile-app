import 'package:flutter/material.dart';

import 'package:beacon_app/core/models/demo_user.dart';
import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final bool isGuest;

  const ProfilePage({super.key, this.isGuest = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int _income = 0;
  String? _gender;
  String? _householdSize;
  String? _selectedLanguage;
  final List<String> _languages = [
    'English',
    'Spanish',
    'Chinese',
    'Tagalog',
    'Vietnamese'
  ];

  @override
  void initState() {
    super.initState();
    final isDemoMode = DemoModeService().isDemoMode;
    if (isDemoMode) {
      _nameController.text = DemoUser.name;
      _emailController.text = DemoUser.email;
      _zipController.text = DemoUser.zipCode;
      _selectedLanguage = DemoUser.language;
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _zipController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _monthController.text = '${picked.month}';
        _yearController.text = '${picked.year}';
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to login/signup page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create an Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedUI() {
    final isDemoMode = DemoModeService().isDemoMode;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              readOnly: isDemoMode,
              decoration: InputDecoration(
                labelText: l10n?.profileName ?? 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                suffixIcon: isDemoMode
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: isDemoMode,
              decoration: InputDecoration(
                labelText: l10n?.profileEmail ?? 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: isDemoMode
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: InputDecoration(
                labelText: l10n?.profileZipCode ?? 'ZIP Code',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your ZIP code';
                }
                if (value.length != 5 || int.tryParse(value) == null) {
                  return 'Please enter a valid 5-digit ZIP code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.profileDateOfBirth ?? 'Date of Birth',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _monthController,
                    decoration: InputDecoration(
                      labelText: l10n?.profileMonth ?? 'Month',
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: l10n?.profileYear ?? 'Year',
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n?.profileLanguage ?? 'Preferred Language',
                prefixIcon: const Icon(Icons.language),
                border: const OutlineInputBorder(),
              ),
              initialValue: _selectedLanguage,
              items: _languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a language';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.profileOptionalInfo ?? 'Optional Information',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n?.profileGender ?? 'Gender',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              initialValue: _gender,
              items: ['Male', 'Female', 'Non-binary', 'Prefer not to say']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _gender = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n?.profileHouseholdSize ?? 'Household Size',
                prefixIcon: const Icon(Icons.people_outline),
                border: const OutlineInputBorder(),
              ),
              initialValue: _householdSize,
              items: List.generate(10, (index) => '${index + 1}')
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _householdSize = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.profileAnnualIncome ?? 'Annual Income',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _income.toDouble(),
                  min: 0,
                  max: 200000,
                  divisions: 20,
                  label: '\$$_income',
                  onChanged: (double value) {
                    setState(() {
                      _income = value.round();
                    });
                  },
                ),
                Text(
                  '\$$_income/year',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n?.profileSaveChanges ?? 'Save Changes',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: Text(l10n?.profileChangePassword ?? 'Change Password'),
            ),
            TextButton(
              onPressed: () {},
              child: Text(l10n?.profilePrivacyPolicy ?? 'Privacy Policy'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.profileTitle ?? 'Profile'),
        actions: widget.isGuest
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _showLogoutDialog,
                ),
              ],
      ),
      body: widget.isGuest ? _buildGuestUI() : _buildAuthenticatedUI(),
    );
  }
}
