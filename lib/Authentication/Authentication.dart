import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jan_saarthi/Pages/Dashboard.dart';

import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Hindi',
    'Gujarati',
    'Tamil',
    'Telugu',
    'Marathi',
    'Bengali',
    'Punjabi'
  ];

  final Map<String, String> _languageToCode = {
    'English': 'en',
    'Hindi': 'hi',
    'Gujarati': 'gu',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Marathi': 'mr',
    'Bengali': 'bn',
    'Punjabi': 'pa',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    setState(() {
      _selectedLanguage = _languageToCode.entries
          .firstWhere((entry) => entry.value == languageCode,
          orElse: () => const MapEntry('English', 'en'))
          .key;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getTranslated(String Function(AppLocalizations) translator) {
    final l10n = AppLocalizations.of(context);
    return l10n != null ? translator(l10n) : '';
  }

  Future<void> _submitAuthForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final auth = FirebaseAuth.instance;
        if (isLogin) {
          await auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Dashboard()));

          _showSnackBar('Login successful ✅');
        } else {
          await auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          await uploadData();

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Dashboard()));
          _showSnackBar('Signup successful 🎉');
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar('Firebase Error: ${e.message}');
      } catch (e) {
        _showSnackBar('Something went wrong: ${e.toString()}');
      }
    }
  }

  Future<void> uploadData() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFields, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("Posts").doc(user!.uid).set({
        'id': generateRandomId(10),
        "username": _nameController.text,
        "phone": _phoneController.text,
        "email": _emailController.text,
      });

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dataUploaded, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xffea7c08), Color(0xFF0d84a2)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.2)),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        icon: const Icon(Icons.language, color: Color(0xFF1A4D8F)),
                        underline: Container(),
                        items: _languages.map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLanguage = val);
                            final localeCode = _languageToCode[val];
                            if (localeCode != null) {
                              MyApp.setLocale(context, Locale(localeCode));
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  Image.asset('assets/images/jan.png', height: 100),
                  const SizedBox(height: 10),
                  Text(l10n.appTitle, style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9))),
                  Text(l10n.appSubtitle, style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!isLogin)
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                  labelText: l10n.fullName,
                                  prefixIcon: const Icon(Icons.person_outline,
                                      color: Color(0xFF1A4D8F))),
                              validator: (val) =>
                              val == null || val.isEmpty
                                  ? l10n.nameValidation
                                  : null,
                            ),
                          if (!isLogin) const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                                labelText: l10n.emailAddress,
                                prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF1A4D8F))),
                            validator: (val) =>
                            val == null || val.isEmpty
                                ? l10n.emailValidation
                                : (!val.contains('@')
                                ? l10n.validEmailValidation
                                : null),
                          ),
                          const SizedBox(height: 16),
                          if (!isLogin)
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                  labelText: l10n.phoneNumber,
                                  prefixIcon: const Icon(Icons.phone_outlined,
                                      color: Color(0xFF1A4D8F))),
                              validator: (val) =>
                              val == null || val.isEmpty
                                  ? l10n.phoneValidation
                                  : (val.length < 10
                                  ? l10n.validPhoneValidation
                                  : null),
                            ),
                          if (!isLogin) const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                                labelText: l10n.password,
                                prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF1A4D8F))),
                            validator: (val) =>
                            val == null || val.isEmpty
                                ? l10n.passwordValidation
                                : (val.length < 6
                                ? l10n.passwordLengthValidation
                                : null),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A4D8F),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 5,
                                shadowColor: Colors.black.withOpacity(0.3),
                              ),
                              onPressed: _submitAuthForm,
                              child: Text(
                                  isLogin ? l10n.login : l10n.register,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  isLogin ? l10n.noAccount : l10n.haveAccount,
                                  style: const TextStyle(color: Colors.black54)),
                              GestureDetector(
                                onTap: () => setState(() => isLogin = !isLogin),
                                child: Text(
                                    isLogin ? l10n.signUp : l10n.loginText,
                                    style: const TextStyle(
                                        color: Color(0xFF1A4D8F),
                                        fontWeight: FontWeight.bold)),
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.digitalIndia,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xffea7c08).withOpacity(0.8),
                              Color(0xFF0d84a2).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  const SizedBox(height: 80),
                  const SizedBox(height: 80),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String generateRandomId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }
}