import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
Future<String> translateText(String text, String targetLanguage) async {
  final url = Uri.parse('https://libretranslate.de/translate'); // or use libretranslate.com or self-host

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'q': text,
      'source': 'en',
      'target': targetLanguage,
      'format': 'text',
    }),
  );

  if (response.statusCode == 200) {
    final responseBody = json.decode(response.body);
    return responseBody['translatedText'] ?? 'Translation error';
  } else {
    throw Exception('Failed to translate text using LibreTranslate');
  }
}
