import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SchemeNotificationScreen extends StatefulWidget {
  const SchemeNotificationScreen({super.key});

  @override
  State<SchemeNotificationScreen> createState() => _SchemeNotificationScreenState();
}

class _SchemeNotificationScreenState extends State<SchemeNotificationScreen> {
  List<dynamic> todaySchemes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTodaySchemes();
  }

  Future<void> fetchTodaySchemes() async {
    try {
      final response = await http.get(Uri.parse('https://webadmin-panel-2.onrender.com/api/schemes'));
      if (response.statusCode == 200) {
        final List<dynamic> allSchemes = json.decode(response.body);

        final today = DateTime.now().toUtc();
        final filteredSchemes = allSchemes.where((scheme) {
          final lastUpdated = DateTime.tryParse(scheme['lastUpdated'] ?? '')?.toUtc();
          return lastUpdated != null &&
              lastUpdated.year == today.year &&
              lastUpdated.month == today.month &&
              lastUpdated.day == today.day;
        }).toList();

        setState(() {
          todaySchemes = filteredSchemes;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load schemes');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    final image = scheme['imageLink'] ?? '';
    final title = scheme['title'] ?? 'No Title';
    final lastUpdated = scheme['lastUpdated'] ?? '';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  height: 100,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Added on: ${lastUpdated.split('T').first} ${lastUpdated.split('T').last.split('.')[0]}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scheme Notifications',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : todaySchemes.isEmpty
          ? const Center(child: Text('No new schemes added today.'))
          : ListView.builder(
        itemCount: todaySchemes.length,
        itemBuilder: (context, index) =>
            _buildSchemeCard(todaySchemes[index]),
      ),
    );
  }
}
