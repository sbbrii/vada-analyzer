import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

const String yourImaggaApiKey = 'acc_b6c4b2aff109ac7';
const String yourImaggaApiSecret = '303b341046115911bbce5b2769e9d4b9';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  String _roastResult = "Let's see that വട!";
  bool _isAnalyzing = false;
  final AudioPlayer audioPlayer = AudioPlayer();
  String _currentAudioPath = '';

  // --- Audio Playback Logic ---
  Future<void> _playRoastAudio(String audioPath) async {
    try {
      // Stop any previous audio
      await audioPlayer.stop();
      // Play the new audio from assets
      await audioPlayer.play(AssetSource(audioPath));
      // Store the path to allow for replay
      _currentAudioPath = audioPath;
    } catch (e) {
      // Don't crash the app if audio fails to play
      // Could use a logging framework here in production
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _roastResult = "ഇതിൽ അമർത്തു 👆🏿";
      });
    }
  }

  Future<void> _analyzeVada() async {
    if (_imageFile == null) return;
    if (yourImaggaApiKey == 'PASTE_YOUR_IMAGGA_API_KEY_HERE' ||
        yourImaggaApiSecret == 'PASTE_YOUR_IMAGGA_API_SECRET_HERE') {
      setState(() {
        _roastResult =
            "Hold on! You need to add your Imagga API Key and Secret to the code first.";
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _roastResult = "Hmm, analyzing the specimen...";
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imagga.com/v2/tags'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$yourImaggaApiKey:$yourImaggaApiSecret'))}';
      request.headers['Authorization'] = basicAuth;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final List tags = responseData['result']['tags'];

        final roast = tags.isEmpty
            ? _getRoastForFailure(tags)
            : _generateRoast(tags);

        setState(() {
          _roastResult = roast['text']!;
        });
        _playRoastAudio(roast['audio']!);
      } else {
        final errorData = jsonDecode(responseBody);
        setState(() {
          _roastResult = "Imagga API Error: ${errorData['status']['text']}";
        });
      }
    } catch (e) {
      setState(() {
        _roastResult =
            "An error occurred during analysis. Is your internet okay?";
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Map<String, String> _generateRoast(List tags) {
    // Helper function to check for a tag's presence
    bool hasTag(String tagName) {
      return tags.any((tag) => tag['tag']['en'] == tagName);
    }

    // Helper function to get a tag's confidence
    double getConfidence(String tagName) {
      var tag = tags.firstWhere(
        (t) => t['tag']['en'] == tagName,
        orElse: () => null,
      );
      return tag != null ? tag['confidence'] : 0.0;
    }

    bool isVada = hasTag('doughnut') || hasTag('bagel');
    bool isFood = hasTag('food') || hasTag('snack') || hasTag('pastry');
    double roundness = getConfidence('round');

    // --- Tiered Roasting Logic ---

    // Category 1: It's a vada, but the shape is questionable
    if (roundness > 65 && isFood) {
      final roasts = [
        {"text": "ഇതെന്തു കുഴിയില്ലാത്ത വടയോ 😂😂", "audio": "audio/kuzhi.mp3"},
        {"text": "ഇതിൽ കുഴിയെവടെ മോനെ 🥹", "audio": "audio/kuzhi.mp3"},
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 2: It's a pretty good vada! Give a backhanded compliment.
    if (isVada) {
      final roasts = [
        {"text": "കിടിലൻ വട മുത്തേ 🔥🙏🏻", "audio": "audio/nice_vada.mp3"},
        {
          "text": "ഈ വട ഉണ്ടാക്കിയവൻ ഒരു കേമൻ തന്നെ 🔥",
          "audio": "audio/nice_vada.mp3",
        },
        {
          "text": "വട കണ്ടപ്പോ തന്നെ charge ആയി 💥",
          "audio": "audio/nice_vada.mp3",
        },
        {"text": "ഇതൊക്കെയാണ് വട 🫡", "audio": "audio/nice_vada.mp3"},
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 3: It's food, but probably not a vada.
    if (isFood) {
      final roasts = [
        {
          "text": "ഇതാരാടാ നിന്നോട് വടയാന്നെന്ന് പറഞ്ഞെ 😭🙏🏻",
          "audio": "audio/pattikkan.mp3",
        },
        {"text": "പറ്റിക്കാൻ നോക്കുന്നോടാ 😡", "audio": "audio/pattikkan.mp3"},
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 4: This isn't food at all.
    return _getRoastForFailure(tags);
  }

  Map<String, String> _getRoastForFailure(List tags) {
    String topTag = tags.isNotEmpty
        ? tags.first['tag']['ml'] ?? tags.first['tag']['en']
        : 'ഒരു മങ്ങൽ ആകൃതി';

    final List<Map<String, String>> failureRoasts = [
      {
        "text": "$topTag'ഇന്റെ photo അയച്ചു പറ്റിക്കാൻ നോക്കുന്നോ",
        "audio": "audio/entho_thakarar.mp3",
      },
      {"text": "ഇതൊക്കെയാണ് വട 🫡", "audio": "audio/entho_thakarar.mp3"},
      {
        "text": "ഇതാരാടാ നിന്നോട് വടയാന്നെന്ന് പറഞ്ഞെ 😭🙏🏻",
        "audio": "audio/entho_thakarar.mp3",
      },
      {"text": "അഹ് ബെസ്റ്റ്....", "audio": "audio/entho_thakarar.mp3"},
      {"text": "എന്തുവാ മോനെ ഇത് 😭", "audio": "audio/entho_thakarar.mp3"},
      {
        "text": "വട കണ്ടെത്താനായില്ല. $topTag മാത്രം കാണുന്നു😭",
        "audio": "audio/entho_thakarar.mp3",
      },
      {
        "text": "നിന്നക്ക് മാനസികമായി എന്തെങ്കിലും തകരാർ ഉണ്ടോ",
        "audio": "audio/entho_thakarar.mp3",
      },
      {
        "text": "വെച്ചേച് വേറെ വെല്ലോ പണിക്കും പോടാ 😍",
        "audio": "audio/entho_thakarar.mp3",
      },
    ];
    return failureRoasts[Random().nextInt(failureRoasts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'വട ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {
                if (_currentAudioPath.isNotEmpty && !_isAnalyzing) {
                  _playRoastAudio(_currentAudioPath);
                }
              },
              tooltip: 'Replay Roast',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Center(
                          child: Image.asset(
                            'assets/vada_placeholder.png',
                            fit: BoxFit.contain,
                            width: 400,
                            height: 400,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      label: 'Gallery',
                      icon: Icons.photo_library,
                    ),
                    _buildIconButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      label: 'Camera',
                      icon: Icons.camera_alt,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'ANALYZE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(width: 10),
                      const Text('വട', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  onPressed: (_imageFile != null && !_isAnalyzing)
                      ? _analyzeVada
                      : null,
                ),
                const SizedBox(height: 30),
                _isAnalyzing
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _roastResult,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
          ),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
