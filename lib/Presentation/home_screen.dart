import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const String YOUR_IMAGGA_API_KEY = 'acc_b6c4b2aff109ac7';
const String YOUR_IMAGGA_API_SECRET = '303b341046115911bbce5b2769e9d4b9';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  String _roastResult = "Let's see that vada!";
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _roastResult = "Ready when you are. Hit 'Analyze'!";
      });
    }
  }

  Future<void> _analyzeVada() async {
    if (_imageFile == null) return;
    if (YOUR_IMAGGA_API_KEY == 'PASTE_YOUR_IMAGGA_API_KEY_HERE' ||
        YOUR_IMAGGA_API_SECRET == 'PASTE_YOUR_IMAGGA_API_SECRET_HERE') {
      setState(() {
        _roastResult =
            "Hold on! You need to add your Imagga API Key and Secret to the code first.";
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _roastResult = "Hmm, sending to Imagga for expert roasting...";
    });

    try {
      // 1. Create the multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imagga.com/v2/tags'),
      );

      // 2. Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      // 3. Add the authorization header
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$YOUR_IMAGGA_API_KEY:$YOUR_IMAGGA_API_SECRET'))}';
      request.headers['Authorization'] = basicAuth;

      // 4. Send the request and get the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // 5. Parse the response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        final List tags = responseData['result']['tags'];

        if (tags.isEmpty) {
          _roastResult = _getRoastForFailure(tags);
        } else {
          _roastResult = _generateRoast(tags);
        }
      } else {
        // Handle API errors
        final errorData = jsonDecode(responseBody);
        _roastResult = "Imagga API Error: ${errorData['status']['text']}";
      }
    } catch (e) {
      _roastResult =
          "An error occurred during analysis. Is your internet okay?";
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  String _generateRoast(List tags) {
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
      final roasts = ["ഇതെന്തു കുഴിയില്ലാത്ത വടയോ 😂😂",
      "ഇതിൽ കുഴിയെവടെ മോനെ 🥹"
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 2: It's a pretty good vada! Give a backhanded compliment.
    if (isVada) {
      final roasts = [
        "കിടിലൻ വട മുത്തേ 🔥🙏🏻",
        "ഈ വട ഉണ്ടാക്കിയവൻ ഒരു കേമൻ തന്നെ 🔥",
        "വട കണ്ടപ്പോ തന്നെ charge ആയി 💥",
        "ഇതൊക്കെയാണ് വട 🫡",
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 3: It's food, but probably not a vada.
    if (isFood) {
      final roasts = [
        "",
        "ഇതാരാടാ നിന്നോട് വടയാന്നെന്ന് പറഞ്ഞെ 😭🙏🏻",
        "പറ്റിക്കാൻ നോക്കുന്നോടാ 😡",
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 4: This isn't food at all.
    return _getRoastForFailure(tags);
  }

  String _getRoastForFailure(List tags) {
    String topTag = tags.isNotEmpty
        ? tags.first['tag']['ml'] ?? tags.first['tag']['en']
        : 'ഒരു മങ്ങൽ ആകൃതി';

    final List<String> failureRoasts = [
      "$topTag'ഇന്റെ photo അയച്ചു പറ്റിക്കാൻ നോക്കുന്നോ",
      "ഇതൊക്കെയാണ് വട 🫡",
      "ഇതാരാടാ നിന്നോട് വടയാന്നെന്ന് പറഞ്ഞെ 😭🙏🏻",
      "അഹ് ബെസ്റ്റ്....",
      "എന്തുവാ മോനെ ഇത് 😭",
      "വട കണ്ടെത്താനായില്ല. $topTag മാത്രം കാണുന്നു😭",
      "നിന്നക്ക് മാനസികമായി എന്തെങ്കിലും തകരാർ ഉണ്ടോ",
      "വെച്ചേച് വേറെ വെല്ലോ പണിക്കും പോടാ 😍"
    ];
    return failureRoasts[Random().nextInt(failureRoasts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'വട Roaster',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 2,
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
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
                            width: 200,
                            height: 200,
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
                  icon: const Icon(Icons.whatshot),
                  label: const Text('ANALYZE വട'),
                  onPressed: (_imageFile != null && !_isAnalyzing)
                      ? _analyzeVada
                      : null,
                  style: ElevatedButton.styleFrom(
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
                ),
                const SizedBox(height: 30),
                _isAnalyzing
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
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
