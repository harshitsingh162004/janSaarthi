import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:jan_saarthi/Pages/user%20profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // 'pw' prefix avoids naming conflicts
import 'package:printing/printing.dart'; // For PDF sharing/printing
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jan_saarthi/Pages/Dashboard.dart';
import 'package:url_launcher/url_launcher.dart';

class EligibleSchemesOnlyScreen extends StatefulWidget {
  const EligibleSchemesOnlyScreen({super.key});

  @override
  State<EligibleSchemesOnlyScreen> createState() =>
      _EligibleSchemesOnlyScreenState();
}

class _EligibleSchemesOnlyScreenState extends State<EligibleSchemesOnlyScreen> {
  List<dynamic> allSchemes = [];
  List<dynamic> eligibleSchemes = [];
  bool isLoading = true;
  bool _showAlertShown = false;

  int userAge = 0;
  String userGender = '';
  String userState = '';

  @override
  void initState() {
    super.initState();
    fetchUserDataAndSchemes().then((_) {
      fetchSchemes();
    });
  }

  Future<void> fetchUserDataAndSchemes() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Posts')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          userAge = data?['age'] ?? 0;
          userGender = _sanitizeValue(data?['sex'] as String?);
          userState = _sanitizeValue(data?['state'] as String?);
          print(
              'Firebase User Data - Age: $userAge, Gender: $userGender, State: $userState');
        } else {
          _showSnackBar(context, 'Error: User data not found in Firebase');
        }
      } else {
        _showSnackBar(context, 'Error: User not logged in');
      }
    } catch (e) {
      _showSnackBar(context, 'Error fetching user data: $e');
    }
  }

  Future<void> fetchSchemes() async {
    try {
      final response = await http
          .get(Uri.parse('https://webadmin-panel-2.onrender.com/api/schemes'));
      if (response.statusCode == 200) {
        final List<dynamic> decodedSchemes = json.decode(response.body);
        setState(() {
          allSchemes = decodedSchemes;
          eligibleSchemes =
              allSchemes.where((scheme) => isUserEligible(scheme)).toList();
          isLoading = false;
        });
        print('API Schemes Data: $allSchemes');
        print('Eligible Schemes: $eligibleSchemes');

        if (eligibleSchemes.isEmpty && !_showAlertShown && mounted) {
          _showAlertShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showUpdateProfileAlert(context);
          });
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar(context,
            'Failed to load schemes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(context, 'Error fetching schemes: $e');
    }
  }

  String _sanitizeValue(String? value) {
    if (value == null) {
      return '';
    }
    return value.toLowerCase().trim().replaceAll(RegExp(r'[,\s]+'), '');
  }

  bool isUserEligible(Map<String, dynamic> scheme) {
    int minAge = scheme['minAge'] ?? 0;
    int maxAge = scheme['maxAge'] ?? 100;
    String gender = _sanitizeValue(scheme['gender'] as String?);
    String schemeState = _sanitizeValue(scheme['state'] as String?);

    bool ageMatch = userAge >= minAge && userAge <= maxAge;
    bool genderMatch = gender == 'both' || gender == userGender;
    bool stateMatch = schemeState == 'allstates' || schemeState == userState;

    print('Evaluating Scheme: ${scheme['title']}');
    print(
        '  Scheme Min Age: $minAge, Max Age: $maxAge, Gender: $gender, State: $schemeState');
    print('  User Age: $userAge, Gender: $userGender, State: $userState');
    print(
        '  Age Match: $ageMatch, Gender Match: $genderMatch, State Match: $stateMatch');

    return ageMatch && genderMatch && stateMatch;
  }

  void _showSnackBar(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar(context, 'Could not launch $url');
    }
  }

  Widget _buildImageWidget(String imageLink) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Image.network(
        imageLink,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 60, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showUpdateProfileAlert(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 60, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text(
                  'No Eligible Schemes Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'It seems there are no schemes currently available that match your profile information.',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please update your profile to find more relevant schemes.',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text('Update Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserProfilePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        child: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
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

  Future<void> _generateApplicationPDF(Map<String, dynamic> scheme) async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(user!.uid)
        .get();
    final userData = userDoc.data() as Map<String, dynamic>;

    final pdf = pw.Document();
    final currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with Logo (Placeholder - replace with your actual logo)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'JanSaarthi ',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
                pw.Text(
                  'Application Form',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Section Headers with improved styling
            _buildSectionTitle('Applicant Information'),
            pw.SizedBox(height: 10),
            _buildDetailRow('Full Name:', userData['username'] ?? 'N/A'),
            _buildDetailRow('Age:', '${userData['age'] ?? 'N/A'} years'),
            _buildDetailRow('Citizen ID:', userData['id'] ?? 'N/A'),
            _buildDetailRow('Income:', '₹${userData['income'] ?? 'N/A'}'),
            _buildDetailRow('State:', userData['state'] ?? 'N/A'),
            pw.Divider(thickness: 0.7),
            pw.SizedBox(height: 15),

            _buildSectionTitle('Scheme Information'),
            pw.SizedBox(height: 10),
            _buildDetailRow('Scheme Title:', scheme['title'] ?? 'N/A'),
            pw.Paragraph(
                text: 'Description: ${scheme['description'] ?? 'N/A'}'),
            pw.SizedBox(height: 5),
            _buildDetailRow('Eligibility Age:',
                '${scheme['minAge']}-${scheme['maxAge']} years'),
            _buildDetailRow('Eligible Gender:', scheme['gender'] ?? 'All'),
            pw.Divider(thickness: 0.7),
            pw.SizedBox(height: 15),

            _buildSectionTitle('Required Documents (Attach Copies)'),
            pw.SizedBox(height: 10),
            pw.Bullet(
                text: 'Aadhaar Card : as proof of identity and residence'),
            pw.Bullet(
                text: 'PAN Card : for income verification (if applicable)'),
            pw.Bullet(
                text:
                    'Bank Passbook (First Page) : to validate bank account details'),
            pw.Bullet(
                text: 'Income Certificate : issued by a competent authority'),
            pw.Bullet(
                text:
                    'Domicile Certificate : proving permanent residence in the state'),
            pw.Bullet(text: 'Recent Passport-sized Photographs (2 copies)'),
            pw.Bullet(
                text:
                    'Self-Declaration Form : declaring that all submitted information is true'),
            pw.Bullet(
                text:
                    'Caste Certificate : for reserved category applicants (if applicable)'),
            pw.Bullet(
                text:
                    'Educational Qualification Proof : last qualifying exam marksheet or certificate'),

            pw.SizedBox(height: 40),

            // Signature Area
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Applicant Signature:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide()),
                      ),
                      child: pw.Text(userData['username'] ?? ' ',
                          textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(currentDate),
                  ],
                ),
              ],
            ),

            pw.Spacer(),

            // Footer with a bit more style
            pw.Center(
              child: pw.Text(
                'Empowering Communities through Information',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save());
  }

// Reusable widget for section titles
  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
        decoration: pw.TextDecoration.underline,
      ),
    );
  }

// Reusable widget for detail rows
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Eligible Schemes",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eligibleSchemes.isEmpty
              ? const Center(child: Text("No eligible schemes found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eligibleSchemes.length,
                  itemBuilder: (context, index) {
                    final scheme = eligibleSchemes[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageWidget(scheme['imageLink'] ?? ''),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        scheme['title'] ?? 'No Title',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2575FC)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Eligible',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  scheme['description'] ??
                                      'No description available',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(Icons.cake_outlined, "Age Range",
                                    "${scheme['minAge']} - ${scheme['maxAge']}"),
                                _buildInfoRow(Icons.person_outline, "Gender",
                                    scheme['gender'] ?? "All"),
                                _buildInfoRow(Icons.location_on_outlined,
                                    "State", scheme['state'] ?? "All India"),
                                const SizedBox(height: 12),
                                if (scheme['pdfLink'] != null)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _launchURL(scheme['pdfLink']),
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "See Detailed Information Of Scheme",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple),
                                  ),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _generateApplicationPDF(scheme),
                                    icon: const Icon(Icons.picture_as_pdf,
                                        color: Colors.white),
                                    label: const Text("Generate Application",
                                        style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                                if (scheme['applyLink'] != null)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _launchURL(scheme['applyLink']),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text("Apply Now"),
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }),
    );
  }
}

// Assuming UserProfilePage is in the same directory or properly imported
