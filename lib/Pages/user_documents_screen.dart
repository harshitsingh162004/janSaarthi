import 'dart:developer';
import 'dart:math'; // Required for log() and pow()
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class UserDocumentsScreen extends StatefulWidget {
  const UserDocumentsScreen({super.key});

  @override
  State<UserDocumentsScreen> createState() => _UserDocumentsScreenState();
}

class _UserDocumentsScreenState extends State<UserDocumentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('user_documents')
          .where('userId', isEqualTo: _user?.uid)
          .get();

      setState(() {
        _documents = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading documents: $e');
    }
  }

  Future<void> _uploadDocuments() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        for (var pickedFile in pickedFiles) {
          final bytes = await File(pickedFile.path).readAsBytes();

          // For web, handle differently
          if (kIsWeb) {
            final webFile = await pickedFile.readAsBytes();
            await _saveToFirestore(webFile, pickedFile.path);
          } else {
            await _saveToFirestore(bytes, pickedFile.path);
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error uploading documents: $e');
      }
    }
  }

  Future<void> _saveToFirestore(Uint8List bytes, String path) async {
    final base64String = base64Encode(bytes);
    final fileType = path.split('.').last.toLowerCase();
    final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.$fileType';

    await _firestore.collection('user_documents').add({
      'userId': _user?.uid,
      'name': fileName,
      'data': base64String,
      'type': _getFileType(fileType),
      'uploadedAt': FieldValue.serverTimestamp(),
      'size': bytes.length,
    });

    await _loadDocuments(); // Refresh list
  }

  String _getFileType(String extension) {
    if (extension == 'pdf') return 'PDF';
    if (['jpg', 'jpeg', 'png'].contains(extension)) return 'Image';
    return 'File';
  }

  Future<void> _deleteDocument(String docId) async {
    try {
      setState(() => _isLoading = true);
      await _firestore.collection('user_documents').doc(docId).delete();
      await _loadDocuments();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error deleting document: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> doc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          doc['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.image,
          color: Colors.blue,
        ),
        title: Text(doc['name']),
        subtitle: Text(
          '${doc['type']} • ${_formatBytes(doc['size'] ?? 0)}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteDocument(doc['id']),
        ),
        onTap: () => _showDocumentPreview(doc),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 0) {
      return 'Invalid';
    }

    if (bytes == 0) {
      return '0 B';
    }

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double byteValue = bytes.toDouble();
    int i = 0;

    while (byteValue >= 1024 && i < suffixes.length - 1) {
      byteValue /= 1024;
      i++;
    }

    return '${byteValue.toStringAsFixed(2)} ${suffixes[i]}';
  }

  void _showDocumentPreview(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc['type'] == 'Image')
              Image.memory(
                base64Decode(doc['data']),
                height: 300,
                fit: BoxFit.contain,
              )
            else
              const Text('PDF preview not available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _uploadDocuments, // Upload multiple documents
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No documents uploaded yet'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _uploadDocuments,
              child: const Text('Upload Your First Document'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _documents.length,
        itemBuilder: (context, index) => _buildDocumentItem(_documents[index]),
      ),
    );
  }
}
