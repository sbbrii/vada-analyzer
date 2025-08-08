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
        _roastResult = "Hold on! You need to add your Imagga API Key and Secret to the code first.";
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
          'POST', Uri.parse('https://api.imagga.com/v2/tags'));

      // 2. Attach the image file
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      
      // 3. Add the authorization header
      String basicAuth = 'Basic ${base64Encode(utf8.encode('$YOUR_IMAGGA_API_KEY:$YOUR_IMAGGA_API_SECRET'))}';
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
      _roastResult = "An error occurred during analysis. Is your internet okay?";
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
      var tag = tags.firstWhere((t) => t['tag']['en'] == tagName, orElse: () => null);
      return tag != null ? tag['confidence'] : 0.0;
    }

    bool isVada = hasTag('doughnut') || hasTag('bagel');
    bool isFood = hasTag('food') || hasTag('snack') || hasTag('pastry');
    double roundness = getConfidence('round');

    // --- Tiered Roasting Logic ---

    // Category 1: It's a vada, but the shape is questionable
    if (roundness >65 && isFood ) {
      final roasts = [
        "This vada looks like it tried to be a circle but gave up. A for effort, C- for geometry.",
        "I've seen rounder things. My cat, for example. When she's sleeping."
      ];
      return roasts[Random().nextInt(roasts.length)];
    }


    

    // Category 2: It's a pretty good vada! Give a backhanded compliment.
    if (isVada) {
      final roasts = [
        "Wow, a perfectly good vada. I'm almost disappointed I have nothing to roast. Almost.",
        "It's... acceptable. The hole is centered. The shape is round. Are you a professional?",
        "This is a textbook vada. So perfect it's almost boring. Good job, I guess."
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 3: It's food, but probably not a vada.
    if (isFood) {
      final roasts = [
        "Okay, it's food. But a vada? That's a stretch. Is that a cookie?",
        "I detect a snack, but the iconic hole is missing. This is an imposter!",
        "This looks more like a potato pancake that got lost. Good effort though."
      ];
      return roasts[Random().nextInt(roasts.length)];
    }

    // Category 4: This isn't food at all.
    return _getRoastForFailure(tags);
  }
  
  String _getRoastForFailure(List tags) {
     // Try to get the top tag to make the roast more specific
     String topTag = tags.isNotEmpty ? tags.first['tag']['en'] : 'a blurry shape';

     final List<String> failureRoasts = [
      "My AI is confused. It thinks this is a '$topTag'. Are you sure that's a vada?",
      "Analysis failed. The object in the photo is beyond my comprehension. Is it... modern art?",
      "I can't detect a vada here. I see $topTag and a lot of hope. Better luck next time!",
      "The cloud has spoken: 'What IS that thing?'. Try a different picture."
    ];
    return failureRoasts[Random().nextInt(failureRoasts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vada Roaster 3000', style: TextStyle(fontWeight: FontWeight.bold)),
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
                height: 300,
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
                    : const Center(
                        child: Icon(
                          Icons.photo_camera_back_outlined,
                          size: 80,
                          color: Colors.grey,
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
                label: const Text('ANALYZE VADA'),
                onPressed: (_imageFile != null && !_isAnalyzing) ? _analyzeVada : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        _roastResult,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required VoidCallback onPressed, required String label, required IconData icon}) {
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
