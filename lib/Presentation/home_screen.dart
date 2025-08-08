import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _picked;
  String _roast = '';
  ImageProvider? _annotated;

  final _picker = ImagePicker();
  final apiUrl = 'http://YOUR_SERVER_IP:5000/analyze'; // change for prod

  Future pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() { _picked = x; _roast = ''; _annotated = null; });
  }

  Future uploadImage() async {
    if (_picked == null) return;
    final uri = Uri.parse(apiUrl);
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', _picked!.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final j = json.decode(res.body);
      setState(() {
        _roast = j['roast'] ?? 'No roast';
        final b64 = j['annotated_image'] ?? '';
        if (b64.isNotEmpty) {
          _annotated = MemoryImage(base64Decode(b64));
        }
      });
    } else {
      setState(() { _roast = 'Server error: ${res.statusCode}'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vada Shape Analyzer')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            ElevatedButton(onPressed: pickImage, child: Text('Pick Image')),
            SizedBox(width: 12),
            ElevatedButton(onPressed: uploadImage, child: Text('Analyze')),
          ]),
          SizedBox(height: 12),
          if (_picked != null) Image.file(File(_picked!.path), height: 180),
          SizedBox(height: 12),
          if (_annotated != null) Column(children: [
             Text('Annotated result:'),
             SizedBox(height:8),
             Image(image: _annotated!, height: 200),
          ]),
          SizedBox(height: 12),
          Text(_roast, style: TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}
