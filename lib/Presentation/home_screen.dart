import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

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

    setState(() {
      _isAnalyzing = true;
      _roastResult = "Hmm, examining the specimen...";
    });

    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path);

      final objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: false,
        ),
      );

      final List<DetectedObject> objects = await objectDetector.processImage(inputImage);
      objectDetector.close();

      if (objects.isEmpty) {
        _roastResult = _getRoastForFailure();
      } else {
        final mainObject = objects.first;
        _roastResult = _generateRoast(mainObject);
      }
    } catch (e) {
      _roastResult = "An error occurred during analysis. Is this vada cursed?";
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  String _generateRoast(DetectedObject obj) {
    final boundingBox = obj.boundingBox;
    final double aspectRatio = boundingBox.width / boundingBox.height;

    final hasFoodLabel = obj.labels.any((label) =>
        label.text.toLowerCase().contains('food') ||
        label.text.toLowerCase().contains('cake') ||
        label.text.toLowerCase().contains('doughnut'));

    if (aspectRatio > 1.5 || aspectRatio < 0.65) {
      return "That's not a vada, that's a continental drift. Did you drop it from space?";
    }

    if (hasFoodLabel) {
      return "Okay, it MIGHT be a vada... but its shape is giving me an identity crisis. Did it have a rough day?";
    }

    final List<String> roasts = [
      "Is this a vada or an asteroid belt? The hole is... ambitious.",
      "NASA called, they want their satellite image back. The crater in the middle is of particular interest.",
      "This vada looks like it gave up halfway through being a circle. A for effort, C- for geometry.",
      "Perfectly symmetrical... if you squint. From another room. In the dark.",
      "I've seen rounder things. My cat, for example. When she's sleeping.",
      "This vada has character. And by character, I mean a complete disregard for the laws of physics and circles."
    ];

    return roasts[Random().nextInt(roasts.length)];
  }

  String _getRoastForFailure() {
    final List<String> failureRoasts = [
      "My AI is confused. Are you sure that's a vada? It looks more like a modern art installation.",
      "Analysis failed. The object in the photo is beyond my comprehension. Is it... abstract?",
      "I can't detect a vada here. I see a blurry shape and a lot of hope. Better luck next time!",
      "Either that's not a vada, or it's so powerful it broke my algorithm."
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
