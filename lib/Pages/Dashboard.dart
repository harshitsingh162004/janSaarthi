import 'package:flutter/material.dart';
import 'user_documents_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jan_saarthi/Authentication/Authentication.dart';
import 'package:jan_saarthi/Pages/AI%20Schems.dart';
import 'package:jan_saarthi/Pages/Calendar.dart';
import 'package:jan_saarthi/Pages/Contact%20Us.dart';
import 'package:jan_saarthi/Pages/Eligible%20Schemes.dart';
import 'package:jan_saarthi/Pages/Eligible Schemes.dart';
import 'package:jan_saarthi/Pages/GeminiVoiceChatPage.dart';
import 'package:jan_saarthi/Pages/user%20profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../main.dart';
import 'SchemeNotificationScreen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String selectedLanguage = 'English';
  int _currentIndex = 0;
  String _userName = 'Loading...';
  String _citizenId = 'Loading...';
  String _userEmail = 'Loading...';
  String _userPhone = 'Loading...';
  int _selectedIndex = 0;

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
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(user!.uid)
          .get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['username'] ?? 'Not available';
          _citizenId = data['id'] ?? 'Not available';
          _userEmail = user.email ?? 'Not available';
          _userPhone = data['phone'] ?? 'Not available';
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logged out successfully!',
            style: TextStyle(color: Colors.white), // White text
          ),
          backgroundColor: Colors.green, // Green background
          behavior: SnackBarBehavior.floating, // Optional: Makes it float
          elevation: 6.0,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Optional: Adds margin
          duration: Duration(seconds: 3), // Optional: Duration of the SnackBar
        ),      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }


  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent duplicate navigation

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EligibleSchemesScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CalendarScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProfilePage()),
        );
        break;
      default:
        setState(() {
          _selectedIndex = index;
        });
    }
  }

  final List<Map<String, dynamic>> schemes = [
    {
      'title': 'PM Kisan Samman Nidhi',
      'description': 'Income support scheme for farmers',
      'icon': Icons.monetization_on,
      'color': Colors.blueAccent,
    },
    {
      'title': 'Soil Health Card Scheme',
      'description': 'Get your soil health report',
      'icon': Icons.eco,
      'color': Colors.green,
    },
    {
      'title': 'Fasal Bima Yojana',
      'description': 'Crop insurance protection',
      'icon': Icons.security,
      'color': Colors.orange,
    },
  ];

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
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue[50],
                backgroundImage: const NetworkImage(
                  "https://cdn.iconscout.com/icon/free/png-256/free-farmer-icon-download-in-svg-png-gif-file-formats--farming-rural-man-farm-worker-agriculture-axe-indian-local-businesses-pack-icons-1838555.png",
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              otherAccountsPictures: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserProfilePage()));
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.blue),
              title: Text(l10n.helpFromAI),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SahaayakVoiceChatPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user, color: Colors.blue),
              title: Text(l10n.aiEligibleSchemes),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EligibleSchemesOnlyScreen()),
                );


              },
            ),
            ListTile(
              leading: const Icon(Icons.policy, color: Colors.blue),
              title: Text(l10n.all),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EligibleSchemesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page, color: Colors.blue),
              title: Text(l10n.contactUs),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text(l10n.profileTitle),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: Text(l10n.settings),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l10n.logout),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "JanSaarthi",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // In the Dashboard's AppBar, replace the logout button with:
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner, color: Colors.white),
            tooltip: 'Documents',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  UserDocumentsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3366FF), Color(0xFF00CCFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: const NetworkImage(
                                "https://cdn.iconscout.com/icon/free/png-256/free-farmer-icon-download-in-svg-png-gif-file-formats--farming-rural-man-farm-worker-agriculture-axe-indian-local-businesses-pack-icons-1838555.png",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${l10n.hello} $_userName",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${l10n.citizenId}: $_citizenId",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.language,
                                      size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  DropdownButton<String>(
                                    value: selectedLanguage,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down,
                                        size: 20, color: Colors.blue),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                    items: _languages
                                        .map((lang) => DropdownMenuItem(
                                      value: lang,
                                      child: Text(lang),
                                    ))
                                        .toList(),
                                    onChanged: _changeLanguage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(l10n.schemes, "20",
                            Icons.assignment, const Color(0xFF3366FF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(l10n.benefits, "₹100,600",
                            Icons.attach_money, Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>  SchemeNotificationScreen(),
                              ),
                            );
                          },
                          child: _buildStatCard(
                            l10n.alerts,
                            "Updates",
                            Icons.notifications,
                            Colors.orange,
                          ),
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.services, // Multilingual title
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3, // You can switch between 3 or 4 for better spacing
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        _buildServiceItem(
                          Icons.mic,
                          l10n.helpFromAI,
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SahaayakVoiceChatPage()),
                            );
                          },
                        ),
                        _buildServiceItem(
                          Icons.verified_user,
                          l10n.aiEligibleSchemes,
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EligibleSchemesOnlyScreen()),
                            );
                          },
                        ),
                        _buildServiceItem(
                          Icons.contact_page,
                          l10n.contactUs,
                          Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ContactMePage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recommendedSchemes,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>EligibleSchemesScreen()));
                        },
                        child: Text(
                          l10n.viewAll,
                          style: const TextStyle(color: Color(0xFF3366FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...schemes.map((scheme) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  scheme['icon'],
                                  color: scheme['color'],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scheme['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      scheme['description'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF3366FF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.assignment), label: l10n.schemes),
          BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today), label: l10n.calendar),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.profileTitle),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildServiceItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  }
