import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Dashboard.dart';


class EligibleSchemesScreen extends StatefulWidget {
  const EligibleSchemesScreen({super.key});

  @override
  State createState() => _EligibleSchemesScreenState();
}

class _EligibleSchemesScreenState extends State {
  List<dynamic> _allSchemes = []; // Store all fetched schemes
  List<dynamic> _filteredSchemes = []; // Schemes after filtering
  Map<int, Map<String, String>> translatedText = {};
  bool isLoading = true;
  String selectedLang = 'en';
  int userAge = 0;
  String userGender = '';
  String userState = '';
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  Set<String> _allStates = {};
  Set<String> _allGenders = {};

  @override
  void initState() {
    super.initState();
    fetchUserDataAndSchemes();
  }

  Future<void> fetchUserDataAndSchemes() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance.collection('Posts').doc(currentUser.uid).get();
        if (doc.exists) {
          final data = doc.data();
          userAge = data?['age'] ?? 0;
          userGender = _sanitize(data?['sex']);
          userState = _sanitize(data?['state']);
          await fetchSchemes();
        } else {
          _showSnackBar('User data not found');
          setState(() => isLoading = false);
        }
      } else {
        _showSnackBar('User not logged in');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSchemes() async {
    try {
      final response = await http.get(Uri.parse('https://webadmin-panel-2.onrender.com/api/schemes'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _allSchemes = data;
        _filteredSchemes = List.from(_allSchemes); // Initialize filtered list
        _extractFilterOptions(_allSchemes);
        await _translateSchemes(); // Translate after fetching
        _applyFiltersAndSearch(); // Apply initial filters if any
      } else {
        _showSnackBar('Failed to load schemes');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error fetching schemes: $e');
      setState(() => isLoading = false);
    }
  }

  void _extractFilterOptions(List<dynamic> schemes) {
    _allStates.clear();
    _allGenders.clear();
    for (var scheme in schemes) {
      final state = _sanitize(scheme['state']);
      if (state != 'allstates') {
        _allStates.add(scheme['state'] as String);
      }
      final gender = _sanitize(scheme['gender']);
      if (gender != 'both') {
        _allGenders.add(scheme['gender'] as String);
      }
    }
  }

  Future<void> _translateSchemes() async {
    final apiKey = 'YOUR_GOOGLE_API_KEY'; // Replace this
    final url = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');
    List<Future<void>> futures = [];

    for (int i = 0; i < _allSchemes.length; i++) {
      futures.add(Future(() async {
        final scheme = _allSchemes[i];
        final title = scheme['title'] ?? '';
        final desc = scheme['description'] ?? '';

        final response = await http.post(url, body: {
          'q': '$title||$desc',
          'target': selectedLang,
        });

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);
          final translated = jsonBody['data']['translations'][0]['translatedText'];
          final parts = translated.split('||');

          setState(() {
            translatedText[i] = {
              'title': parts[0],
              'description': parts.length > 1 ? parts[1] : '',
            };
          });
        } else {
          setState(() {
            translatedText[i] = {'title': title, 'description': desc};
          });
        }
      }));
    }

    await Future.wait(futures);
    setState(() => isLoading = false);
    _applyFiltersAndSearch(); // Re-apply filters after translation
  }

  String _sanitize(String? value) {
    return (value ?? '').toLowerCase().trim().replaceAll(RegExp(r'[,\s]+'), '');
  }

  bool isEligible(Map<String, dynamic> scheme) {
    final minAge = scheme['minAge'] ?? 0;
    final maxAge = scheme['maxAge'] ?? 100;
    final gender = _sanitize(scheme['gender']);
    final state = _sanitize(scheme['state']);
    final ageMatch = userAge >= minAge && userAge <= maxAge;
    final genderMatch = gender == 'both' || gender == userGender;
    final stateMatch = state == 'allstates' || state == userState;
    return ageMatch && genderMatch && stateMatch;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.deepPurple),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not launch $url');
    }
  }

  Widget _buildImage(String link) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Image.network(
        link,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 60),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _filterSchemes(List<String> states, List<String> genders) {
    setState(() {
      _filteredSchemes = _allSchemes.where((scheme) {
        final stateMatch = states.isEmpty || states.contains(scheme['state']);
        final genderMatch = genders.isEmpty || genders.contains(scheme['gender']);
        return stateMatch && genderMatch;
      }).toList();
      _applySearch();
    });
  }

  void _applySearch() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _filteredSchemes = _filteredSchemes.where((scheme) {
          final translated = translatedText[_allSchemes.indexOf(scheme)] ??
              {'title': scheme['title'] ?? '', 'description': scheme['description'] ?? ''};
          final titleMatch = translated['title']!.toLowerCase().contains(_searchQuery.toLowerCase());
          final descriptionMatch = translated['description']!.toLowerCase().contains(_searchQuery.toLowerCase());
          return titleMatch || descriptionMatch;
        }).toList();
      });
    }
  }

  void _applyFiltersAndSearch() {
    _filterSchemes(_selectedFilters.where((filter) => _allStates.contains(filter)).toList(),
        _selectedFilters.where((filter) => _allGenders.contains(filter)).toList());
  }

  Future<void> _showFilterDialog() async {
    List<String> selectedStates = _selectedFilters.where((filter) => _allStates.contains(filter)).toList();
    List<String> selectedGenders = _selectedFilters.where((filter) => _allGenders.contains(filter)).toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Schemes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('States:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: _allStates.map((state) {
                    return FilterChip(
                      label: Text(state),
                      selected: selectedStates.contains(state),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedStates.add(state);
                          } else {
                            selectedStates.remove(state);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Gender:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: _allGenders.map((gender) {
                    return FilterChip(
                      label: Text(gender),
                      selected: selectedGenders.contains(gender),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedGenders.add(gender);
                          } else {
                            selectedGenders.remove(gender);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Clear Filters'),
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                });
                _applyFiltersAndSearch();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apply Filters'),
              onPressed: () {
                setState(() {
                  _selectedFilters = [...selectedStates, ...selectedGenders];
                });
                _applyFiltersAndSearch();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("All Schemes", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Dashboard())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: selectedLang,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.language, color: Colors.white),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                DropdownMenuItem(value: 'te', child: Text('Telugu')),
              ],
              onChanged: (lang) {
                setState(() {
                  selectedLang = lang!;
                  isLoading = true;
                });
                _translateSchemes();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applySearch();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search schemes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSchemes.isEmpty
          ? const Center(child: Text("No schemes found matching your criteria"))
          : ListView.builder(
        itemCount: _filteredSchemes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final scheme = _filteredSchemes[index];
          final eligible = isEligible(scheme);
          final trans = translatedText[_allSchemes.indexOf(scheme)] ??
              {'title': scheme['title'] ?? '', 'description': scheme['description'] ?? ''};

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(scheme['imageLink'] ?? ''),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trans['title']!,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2575FC)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: eligible ? Colors.green : Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(eligible ? Icons.verified : Icons.cancel, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(eligible ? 'Eligible' : 'Ineligible',
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(trans['description']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.cake, "Age Range", "${scheme['minAge']} - ${scheme['maxAge']}"),
                      _infoRow(Icons.person, "Gender", scheme['gender'] ?? "All"),
                      _infoRow(Icons.location_on, "State", scheme['state'] ?? "All India"),
                      const SizedBox(height: 12),
                      if (scheme['pdfLink'] != null)
                        ElevatedButton.icon(
                          onPressed: () => _launchURL(scheme['pdfLink']),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text("See Detailed Information Of Scheme", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        ),
                      // Inside your ListView.builder, after the existing buttons:

                      if (scheme['applyLink'] != null)
                        OutlinedButton.icon(
                          onPressed: () => _launchURL(scheme['applyLink']),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Apply Now"),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}