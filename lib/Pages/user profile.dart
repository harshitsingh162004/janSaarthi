import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jan_saarthi/main.dart'; // Import MyApp
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> profileData = {};
  bool isLoading = true;
  String selectedLanguage = 'English';

  // Controllers for all fields
  final idController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final stateController = TextEditingController();
  final incomeController = TextEditingController();

  // Dropdown values
  String? selectedSex;
  String? selectedEducation;
  String? selectedCaste;
  bool isDisabled = false;

  // Options for dropdowns
  final List<String> sexOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> educationOptions = [
    'Illiterate',
    'Primary School',
    'Secondary School',
    'High School',
    'Diploma',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate',
    'Other'
  ];
  final List<String> casteOptions = ['General', 'OBC', 'SC', 'ST', 'Other'];

  final Map<String, String> _languageToCode = {
    'English': 'en',
    'Hindi': 'hi',
    'Gujarati': 'gu',
  };

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final doc = await _firestore.collection('Posts').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          profileData = data;
          idController.text = data['id'] ?? '';
          usernameController.text = data['username'] ?? '';
          phoneController.text = data['phone'] ?? '';
          ageController.text = data['age']?.toString() ?? '';
          stateController.text = data['state'] ?? '';
          incomeController.text = data['income']?.toString() ?? '';
          selectedSex = data['sex'];
          selectedEducation = data['education'];
          selectedCaste = data['caste'];
          isDisabled = data['disabled'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveProfile() async {
    try {
      await _firestore.collection('Posts').doc(user.uid).set({
        'id': idController.text,
        'username': usernameController.text,
        'phone': phoneController.text,
        'email': user.email ?? '',
        'age': int.tryParse(ageController.text),
        'state': stateController.text,
        'income': int.tryParse(incomeController.text),
        'sex': selectedSex,
        'education': selectedEducation,
        'caste': selectedCaste,
        'disabled': isDisabled,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  void _changeLanguage(String? lang) {
    if (lang != null) {
      setState(() => selectedLanguage = lang);
      final localeCode = _languageToCode[lang];
      if (localeCode != null) {
        MyApp.setLocale(context, Locale(localeCode));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontSize: 22, color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // <- This changes the back arrow to white
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: selectedLanguage,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white),
              items: _languageToCode.keys
                  .map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang),
              ))
                  .toList(),
              onChanged: _changeLanguage,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                        'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usernameController.text.isNotEmpty
                              ? usernameController.text
                              : 'No username',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No email',
                          style: TextStyle(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.personalInformation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: idController,
              decoration: _buildInputDecoration(l10n.citizenId, Icons.credit_card).copyWith(
                filled: true,
                fillColor: Colors.grey[200],
              ),
              style: const TextStyle(fontSize: 16),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: usernameController,
              decoration: _buildInputDecoration(l10n.fullName, Icons.person),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: phoneController,
              decoration: _buildInputDecoration(l10n.phoneNumber, Icons.phone),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedSex,
              decoration: _buildInputDecoration(l10n.gender, Icons.person_outline),
              items: sexOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedSex = newValue;
                });
              },
              hint: Text(l10n.selectGender),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: ageController,
              decoration: _buildInputDecoration(l10n.age, Icons.cake),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.additionalInformation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: stateController,
              decoration: _buildInputDecoration(l10n.state, Icons.location_on),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedEducation,
              decoration: _buildInputDecoration(l10n.educationLevel, Icons.school),
              items: educationOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedEducation = newValue;
                });
              },
              hint: Text(l10n.selectEducationLevel),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: incomeController,
              decoration: _buildInputDecoration(l10n.annualIncome, Icons.attach_money),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCaste,
              decoration: _buildInputDecoration(l10n.casteCategory, Icons.category),
              items: casteOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedCaste = newValue;
                });
              },
              hint: Text(l10n.selectCasteCategory),
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: Text(l10n.physicallyDisabled),
              subtitle: Text(l10n.checkIfApplicable),
              value: isDisabled,
              onChanged: (bool value) {
                setState(() {
                  isDisabled = value;
                });
              },
              secondary: const Icon(Icons.accessible, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                child: Text(
                  l10n.saveProfile,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (profileData.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourProfileData,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDataRow(l10n.citizenId, idController.text),
                    _buildDataRow(l10n.fullName, usernameController.text),
                    _buildDataRow(l10n.phoneNumber, phoneController.text),
                    _buildDataRow(l10n.emailAddress, user.email ?? l10n.notProvided),
                    _buildDataRow(l10n.age, ageController.text),
                    _buildDataRow(l10n.gender, selectedSex ?? l10n.notProvided),
                    _buildDataRow(l10n.state, stateController.text),
                    _buildDataRow(l10n.educationLevel, selectedEducation ?? l10n.notProvided),
                    _buildDataRow(l10n.annualIncome, incomeController.text.isNotEmpty ? '₹${incomeController.text}' : l10n.notProvided),
                    _buildDataRow(l10n.casteCategory, selectedCaste ?? l10n.notProvided),
                    _buildDataRow(l10n.physicallyDisabled, isDisabled ? l10n.yes : l10n.no),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}