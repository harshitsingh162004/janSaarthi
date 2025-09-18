import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'user_documents_screen.dart';
void main() {
  runApp(const JanSarrthiApp());
}

class JanSarrthiApp extends StatelessWidget {
  const JanSarrthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jan Sarrthi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A11CB)),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6A11CB)),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const ContactMePage(),
    );
  }
}

class ContactMePage extends StatefulWidget {
  const ContactMePage({super.key});

  @override
  State<ContactMePage> createState() => _ContactMePageState();
}

class _ContactMePageState extends State<ContactMePage> {
  final _formKey = GlobalKey<FormState>();
  late Razorpay _razorpay;
  String _selectedReason = 'Select a reason';
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _schemeController = TextEditingController();
  final List<String> _reasons = [
    'Select a reason',
    'General Inquiry',
    'Scheme Application',
    'Grievance',
    'Feedback',
    'Other'
  ];
  String? _otherReason;
  bool _isSending = false;
  bool _showSchemeField = false;
  bool _showPaymentButton = false;
  String _citizenId = 'Loading...';
  String _userEmail = 'Loading...';
  DocumentReference? _currentApplicationRef;

  @override
  void initState() {
    super.initState();
    loadUserData();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _messageController.dispose();
    _schemeController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user is logged in");
      return;
    }

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(user.uid)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _citizenId = data['id'] ?? 'Not available';
          _userEmail = user.email ?? 'Not available';
        });
      } else {
        print("Document not found for UID: ${user.uid}");
        setState(() {
          _citizenId = 'Not available';
          _userEmail = user.email ?? 'Not available';
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _handleReasonChange(String? value) {
    setState(() {
      _selectedReason = value!;
      _showSchemeField = value == 'Scheme Application';
      _showPaymentButton = _showSchemeField;
      if (value != 'Other') _otherReason = null;
    });

    // Show document upload alert when Scheme Application is selected
    if (value == 'Scheme Application') {
      _showDocumentUploadAlert();
    }
  }
  Future<void> _showDocumentUploadAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A11CB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.upload,
                    color: Color(0xFF6A11CB),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Upload Documents?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A11CB),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'For scheme applications, we recommend uploading supporting documents for faster processing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6A11CB),
                          side: const BorderSide(color: Color(0xFF6A11CB)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Skip for Now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserDocumentsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Upload Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final applicationData = {
        'citizenId': _citizenId,
        'email': _userEmail,
        'reason': _selectedReason == 'Other' ? _otherReason : _selectedReason,
        'message': _messageController.text,
        'scheme': _showSchemeField ? _schemeController.text : null,
        'paymentStatus': _showPaymentButton ? 'Pending' : 'Not Applicable',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Submitted'
      };

      _currentApplicationRef = await FirebaseFirestore.instance
          .collection('messages')
          .add(applicationData);

      if (_showPaymentButton) {
        _openPaymentGateway();
      } else {
        _showSnackBar('Submission successful!');
        _resetForm();
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _openPaymentGateway() {
    var options = {
      'key': 'rzp_test_SDnm1ytL5m0dpS',
      'amount': 1500, // 100 rupees in paise
      'name': 'Jan Sarrthi',
      'description': 'Scheme Application Fee for ${_schemeController.text}',
      'prefill': {
        'contact': '9876543210',
        'email': _userEmail,
      },
      'theme': {'color': '#6A11CB'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await _currentApplicationRef?.update({
        'paymentStatus': 'Completed',
        'paymentId': response.paymentId,
        'paymentDate': FieldValue.serverTimestamp(),
        'status': 'Payment Completed'
      });

      _showPaymentSuccessDialog();
      _resetForm();
    } catch (e) {
      _showSnackBar('Error saving payment details: ${e.toString()}', isError: true);
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '₹100 paid for ${_schemeController.text}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnackBar('Payment Failed: ${response.message}', isError: true);
    _currentApplicationRef?.update({
      'paymentStatus': 'Failed',
      'status': 'Payment Failed'
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackBar('External Wallet: ${response.walletName}');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _messageController.clear();
    _schemeController.clear();
    _selectedReason = 'Select a reason';
    _otherReason = null;
    _showSchemeField = false;
    _showPaymentButton = false;
    _currentApplicationRef = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0EAFC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Support Header
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A11CB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Color(0xFF6A11CB),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEED HELP?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6A11CB),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contact our support team',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A11CB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF6A11CB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Your Profile',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Citizen ID', _citizenId),
                    const Divider(height: 24, thickness: 1),
                    _buildInfoRow('Email', _userEmail),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Reason Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedReason,
                        onChanged: _handleReasonChange,
                        items: _reasons.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Reason for Contact',
                          prefixIcon: const Icon(Icons.subject_outlined, color: Color(0xFF6A11CB)),
                        ),
                        validator: (value) =>
                        value == 'Select a reason' ? 'Please select a reason' : null,
                      ),

                      // Other Reason Field
                      if (_selectedReason == 'Other') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          onChanged: (value) => _otherReason = value,
                          decoration: const InputDecoration(
                            labelText: 'Please specify',
                            prefixIcon: Icon(Icons.edit_outlined, color: Color(0xFF6A11CB)),
                          ),
                          validator: (value) {
                            if (_selectedReason == 'Other' && value!.isEmpty) {
                              return 'Please specify your reason';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Scheme Name Field
                      if (_showSchemeField) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _schemeController,
                          decoration: const InputDecoration(
                            labelText: 'Scheme Name',
                            hintText: 'Enter the government scheme name',
                            prefixIcon: Icon(Icons.article_outlined, color: Color(0xFF6A11CB)),
                          ),
                          validator: (value) {
                            if (_showSchemeField && value!.isEmpty) {
                              return 'Please enter scheme name';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Message Field
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Your Message',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.message_outlined, color: Color(0xFF6A11CB)),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter your message' : null,
                      ),

                      // Payment Info
                      if (_showPaymentButton) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.payment, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'APPLICATION FEE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹100',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Submit Button
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A11CB),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSending
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_showPaymentButton)
                                const Icon(Icons.payment, color: Colors.white, size: 20),
                              if (_showPaymentButton)
                                const SizedBox(width: 8),
                              Text(
                                _showPaymentButton ? 'Proceed to Payment' : 'Submit Request',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}