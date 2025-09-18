import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Dashboard.dart';
class SahaayakVoiceChatPage extends StatefulWidget {
  const SahaayakVoiceChatPage({super.key});

  @override
  State<SahaayakVoiceChatPage> createState() => _SahaayakVoiceChatPageState();
}

class _SahaayakVoiceChatPageState extends State<SahaayakVoiceChatPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _userInput = '';
  String _geminiResponse = '';
  bool _isListening = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  bool _languageSelected = false; // Track if language is selected
  String _errorMessage = '';
  String _status = 'Please select your language first';
  String _currentLanguage = 'en-US'; // Default language

  final String _apiKey = "AIzaSyDu8OkFOcnsMqLrn6g0RtHm8bcKeEx7IdY";

  // Supported languages with their codes and display names
  final Map<String, Map<String, String>> _supportedLanguages = {
    'English': {
      'code': 'en-US',
      'native': 'English',
      'tts': 'en-US',
    },
    'हिन्दी': {
      'code': 'hi-IN',
      'native': 'हिन्दी',
      'tts': 'hi-IN',
    },
    'ગુજરાતી': {
      'code': 'gu-IN',
      'native': 'ગુજરાતી',
      'tts': 'gu-IN',
    },
    'বাংলা': {
      'code': 'bn-IN',
      'native': 'বাংলা',
      'tts': 'bn-IN',
    },
    'தமிழ்': {
      'code': 'ta-IN',
      'native': 'தமிழ்',
      'tts': 'ta-IN',
    },
    'తెలుగు': {
      'code': 'te-IN',
      'native': 'తెలుగు',
      'tts': 'te-IN',
    },
    'मराठी': {
      'code': 'mr-IN',
      'native': 'मराठी',
      'tts': 'mr-IN',
    },
    'ಕನ್ನಡ': {
      'code': 'kn-IN',
      'native': 'ಕನ್ನಡ',
      'tts': 'kn-IN',
    },
    'മലയാളം': {
      'code': 'ml-IN',
      'native': 'മലയാളം',
      'tts': 'ml-IN',
    },
    'ਪੰਜਾਬੀ': {
      'code': 'pa-IN',
      'native': 'ਪੰਜਾਬੀ',
      'tts': 'pa-IN',
    },
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
        _errorMessage = 'TTS Error: $msg';
      });
    });
  }

  Future<void> _listen() async {
    if (!_languageSelected) {
      setState(() {
        _errorMessage = 'Please select a language first';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _status = 'Listening...';
    });

    bool available = await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _status = status;
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            if (_userInput.isNotEmpty) {
              _processUserInput(_userInput);
            }
          }
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Speech Error: ${error.errorMsg}';
          _status = 'Error occurred';
        });
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _userInput = '';
        _geminiResponse = '';
      });

      // Set the language for speech recognition
      final locale = _currentLanguage.replaceFirst('-', '_');
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _userInput = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: locale,
      );
    } else {
      setState(() {
        _errorMessage = 'Speech recognition not available';
        _status = 'Speech not available';
      });
    }
  }

  void _processUserInput(String prompt) {
    // Check if user is asking about the creator
    if (prompt.toLowerCase().contains('who designed you') ||
        prompt.toLowerCase().contains('who created you') ||
        prompt.toLowerCase().contains('who made you')) {
      _generateLocalizedResponse(prompt);
    } else {
      _sendToGemini(prompt);
    }
  }

  void _generateLocalizedResponse(String prompt) {
    String response;
    final languageCode = _currentLanguage.split('-').first;

    switch (languageCode) {
      case 'hi': // Hindi
        response = "मैं सहायक हूँ, जनसारथी ऐप का हिस्सा हूँ जिसे कोडवायोनिक्स टीम ने रिशांत कुमार के नेतृत्व में बनाया है। हमारा मिशन सभी उपयोगकर्ताओं को सरकारी योजनाओं के लाभ तक आसानी से पहुंचने में मदद करना है।";
        break;
      case 'gu': // Gujarati
        response = "હું સહાયક છું, જનસારથી એપ્લિકેશનનો ભાગ છું જે કોડવિયોનિક્સ ટીમ દ્વારા રિશાંત કુમારના નેતૃત્વમાં બનાવવામાં આવ્યું છે. અમારું ધ્યેય તમામ વપરાશકર્તાઓને સરકારી યોજનાઓના લાભો સુલભ બનાવવાનું છે.";
        break;
      case 'bn': // Bengali
        response = "আমি সহায়ক, জনসাথী অ্যাপের অংশ যা কোডভায়োনিক্স টিম দ্বারা রিশান্ত কুমারের নেতৃত্বে তৈরি করা হয়েছে। আমাদের লক্ষ্য是所有用户可以轻松获得政府计划福利。";
        break;
      case 'ta': // Tamil
        response = "நான் சஹாயக், ஜனசார்த்தி பயன்பாட்டின் ஒரு பகுதியாக இருக்கிறேன், இது ரிஷாந்த் குமார் தலைமையிலான கோட்வியோனிக்ஸ் குழுவால் வடிவமைக்கப்பட்டது. எங்கள் பணி அனைத்து பயனர்களும் அரசு திட்ட நன்மைகளை எளிதாக அணுக உதவுவதாகும்.";
        break;
      case 'te': // Telugu
        response = "నేను సహాయకుడిని, జనసారథి అనువర్తనంలో భాగమైన కోడ్వియోనిక్స్ జట్టు రిషాంత్ కుమార్ నేతృత్వంలో రూపొందించారు. ప్రభుత్వ పథకాల ప్రయోజనాలను అందరు వినియోగదారులు సులభంగా పొందడంలో సహాయపడటమే మా లక్ష్యం.";
        break;
      case 'mr': // Marathi
        response = "मी सहाय्यक आहे, जनसारथी अॅपचा भाग आहे जो कोडव्हायोनिक्स टीमने रिशांत कुमार यांच्या नेतृत्वाखाली तयार केला आहे. सर्व वापरकर्त्यांना सरकारी योजनांच्या लाभांपर्यंत सहजतेने पोहोचण्यास मदत करणे हे आमचे ध्येय आहे.";
        break;
      case 'kn': // Kannada
        response = "ನಾನು ಸಹಾಯಕ, ಜನಸಾರ್ಥಿ ಅಪ್ಲಿಕೇಶನ್‌ನ ಭಾಗವಾಗಿದ್ದು, ರಿಶಾಂತ್ ಕುಮಾರ್ ನೇತೃತ್ವದ ಕೋಡ್‌ವಿಯೋನಿಕ್ಸ್ ತಂಡವು ವಿನ್ಯಾಸಗೊಳಿಸಿದೆ. ಎಲ್ಲಾ ಬಳಕೆದಾರರಿಗೆ ಸರ್ಕಾರಿ ಯೋಜನೆಯ ಪ್ರಯೋಜನಗಳನ್ನು ಸುಲಭವಾಗಿ ಪಡೆಯಲು ಸಹಾಯ ಮಾಡುವುದು ನಮ್ಮ ಧ್ಯೇಯ.";
        break;
      case 'ml': // Malayalam
        response = "ഞാൻ സഹായകനാണ്, ജനസാരഥി ആപ്പിന്റെ ഭാഗമാണ്, ഋഷാന്ത് കുമാർ നേതൃത്വത്തിലുള്ള കോഡ്‌വിയോണിക്സ് ടീം രൂപകൽപ്പന ചെയ്തതാണ്. എല്ലാ ഉപയോക്താക്കൾക്കും സർക്കാർ പദ്ധതി നേട്ടങ്ങൾ എളുപ്പത്തിൽ ലഭ്യമാക്കാൻ സഹായിക്കുക എന്നതാണ് ഞങ്ങളുടെ ലക്ഷ്യം.";
        break;
      case 'pa': // Punjabi
        response = "ਮੈਂ ਸਹਾਇਕ ਹਾਂ, ਜਨਸਾਰਥੀ ਐਪ ਦਾ ਹਿੱਸਾ ਹਾਂ ਜੋ ਕਿ ਕੋਡਵਿਓਨਿਕਸ ਟੀਮ ਦੁਆਰਾ ਰਿਸ਼ਾਂਤ ਕੁਮਾਰ ਦੀ ਅਗਵਾਈ ਹੇਠ ਡਿਜ਼ਾਈਨ ਕੀਤਾ ਗਿਆ ਹੈ। ਸਾਡਾ ਟੀਚਾ ਸਾਰੇ ਉਪਭੋਗਤਾਵਾਂ ਨੂੰ ਸਰਕਾਰੀ ਯੋਜਨਾ ਦੇ ਲਾਭਾਂ ਤੱਕ ਆਸਾਨੀ ਨਾਲ ਪਹੁੰਚ ਕਰਨ ਵਿੱਚ ਮਦਦ ਕਰਨਾ ਹੈ।";
        break;
      default: // English and other languages
        response = "I'm Sahaayak, part of the JanSaarthi app designed by Codevision team led Prashant Kumar. Our mission is to help all users access government scheme benefits easily.";    }

    setState(() {
      _geminiResponse = response;
      _status = 'Response ready';
    });
    _speak(response);
    _scrollToBottom();
  }

  Future<void> _sendToGemini(String prompt) async {
    if (prompt.isEmpty) {
      setState(() => _errorMessage = 'No speech input recognized');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _status = 'Processing...';
    });

    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=$_apiKey");

      // Get the language code and native name
      final languageCode = _currentLanguage.split('-').first;
      final languageEntry = _supportedLanguages.values.firstWhere(
            (lang) => lang['code'] == _currentLanguage,
        orElse: () => {'native': 'English'},
      );
      final languageName = languageEntry['native'];

      // Enhanced prompt with explicit language instruction
      final enhancedPrompt = """
      $prompt 
      
      [Important Instructions]
      - Respond in $languageName ($languageCode)
      - Use simple, clear language
      - Keep responses concise but helpful
      - Maintain a friendly tone
      """;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': enhancedPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
            'stopSequences': []
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text != null && text.toString().trim().isNotEmpty) {
          setState(() {
            _geminiResponse = text;
            _status = 'Response ready';
          });
          await _speak(text);
          _scrollToBottom();
        } else {
          setState(() {
            _errorMessage = 'Empty response from Gemini';
            _status = 'No response';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
          _status = 'API Error occurred';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network Error: $e';
        _status = 'Connection failed';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _speak(String text) async {
    // Get the TTS language code for the current language
    final languageEntry = _supportedLanguages.values.firstWhere(
          (lang) => lang['code'] == _currentLanguage,
      orElse: () => {'tts': 'en-US'},
    );
    final ttsLanguage = languageEntry['tts']!;

    await _flutterTts.setLanguage(ttsLanguage);
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  void _submitText() {
    if (!_languageSelected) {
      setState(() {
        _errorMessage = 'Please select a language first';
      });
      return;
    }

    if (_textController.text.isNotEmpty) {
      _processUserInput(_textController.text);
      _textController.clear();
    }
  }

  void _changeLanguage(String? languageDisplayName) {
    if (languageDisplayName != null) {
      final languageEntry = _supportedLanguages[languageDisplayName];
      if (languageEntry != null) {
        setState(() {
          _currentLanguage = languageEntry['code']!;
          _languageSelected = true;
          _status = 'Language set to ${languageEntry['native']}. Tap the mic to speak.';
          _errorMessage = '';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => Dashboard()),
            );
          },
        ),
        title: const Text('Sahaayak', style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20
        )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[800],
        actions: [
          // Language dropdown
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _supportedLanguages.keys.firstWhere(
                    (key) => _supportedLanguages[key]!['code'] == _currentLanguage,
                orElse: () => 'English',
              ),
              dropdownColor: Colors.blue[800],
              icon: const Icon(Icons.translate, color: Colors.white),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.white),
              underline: Container(height: 0),
              onChanged: _changeLanguage,
              items: _supportedLanguages.keys.map<DropdownMenuItem<String>>((String displayName) {
                return DropdownMenuItem<String>(
                  value: displayName,
                  child: Text(
                    _supportedLanguages[displayName]!['native']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              onPressed: _stopSpeaking,
              tooltip: 'Stop speaking',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _errorMessage.isEmpty ? Colors.blue[50] : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  _errorMessage.isEmpty ? Icons.info_outline : Icons.warning_amber_outlined,
                  color: _errorMessage.isEmpty ? Colors.blue[800] : Colors.red[800],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage.isEmpty ? _status : _errorMessage,
                    style: TextStyle(
                      color: _errorMessage.isEmpty ? Colors.blue[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat area
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (!_languageSelected)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 60,
                            color: Color(0xFF64B5F6),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Unlock Sahaayak!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Choose your preferred language from the dropdown at the top right to begin your seamless interaction.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_userInput.isNotEmpty)
                  _buildMessageBubble(
                    text: _userInput,
                    isUser: true,
                    context: context,
                  ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),

                if (_geminiResponse.isNotEmpty)
                  _buildMessageBubble(
                    text: _geminiResponse,
                    isUser: false,
                    context: context,
                  ),
              ],
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 40.0), // Added margin at the bottom
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _languageSelected ? 'Type your message...' : 'Select language first',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _submitText,
                      ),
                    ),
                    onSubmitted: (_) => _submitText(),
                    enabled: _languageSelected,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isListening ? null : _listen,
                  backgroundColor: _isListening
                      ? Colors.red
                      : (_languageSelected ? Colors.blue[800] : Colors.grey),
                  elevation: 0,
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    required BuildContext context,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 64 : 0,
        right: isUser ? 0 : 64,
      ),
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[800] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (!isUser && _geminiResponse.isNotEmpty && !_isSpeaking)
            TextButton(
              onPressed: () => _speak(_geminiResponse),
              child: Text(
                'Read aloud',
                style: TextStyle(
                  color: Colors.blue[800],
                ),
              ),
            ),
        ],
      ),
    );
  }
}