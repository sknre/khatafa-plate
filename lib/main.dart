import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khtafa Dnem',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF454955),
        scaffoldBackgroundColor: const Color(0xFF272727),
      ),
      home: const CarLoggerPage(),
    );
  }
}

class Entry {
  final String plate;
  final String letter;
  final String cityCode;
  final String dateTime;
  final String? imagePath;

  Entry({
    required this.plate,
    required this.letter,
    required this.cityCode,
    required this.dateTime,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'plate': plate,
      'letter': letter,
      'cityCode': cityCode,
      'dateTime': dateTime,
      'imagePath': imagePath,
    };
  }

  static Entry fromJson(Map<String, dynamic> json) {
    return Entry(
      plate: json['plate'],
      letter: json['letter'],
      cityCode: json['cityCode'],
      dateTime: json['dateTime'],
      imagePath: json['imagePath'],
    );
  }
}

class CarLoggerPage extends StatefulWidget {
  const CarLoggerPage({Key? key}) : super(key: key);

  @override
  _CarLoggerPageState createState() => _CarLoggerPageState();
}

class _CarLoggerPageState extends State<CarLoggerPage> {
  final TextEditingController _plateController = TextEditingController();
  String _selectedCityCode = '1';
  String _selectedLetter = 'أ';
  final List<Entry> _entries = [];
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(now);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_plateController.text.isNotEmpty) {
      final currentTime = _getCurrentDateTime();
      final newEntry = Entry(
        plate: _plateController.text,
        letter: _selectedLetter,
        cityCode: _selectedCityCode,
        dateTime: currentTime,
        imagePath: _selectedImage?.path,
      );

      setState(() {
        _entries.add(newEntry);
        _plateController.clear();
        _selectedImage = null;
      });

      await _backupEntriesToICloud();
    }
  }

  Widget _buildImageWidget(String? path) {
    if (path == null) return const SizedBox.shrink();
    if (kIsWeb) {
      return const Text('Image display not supported on Web.');
    }
    return GestureDetector(
      onTap: () => _showImageFullScreen(File(path)),
      child: Container(
        height: 50,
        width: 50,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: FileImage(File(path)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future<void> _showImageFullScreen(File image) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Full Image'),
        ),
        body: Center(
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    ));
  }

  Future<void> _backupEntriesToICloud() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final entryList = _entries.map((entry) => entry.toJson()).toList();
    prefs.setString('entries', jsonEncode(entryList));
  }

  Future<void> _loadEntries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final entryListString = prefs.getString('entries');
    if (entryListString != null) {
      final List<dynamic> entryListJson = jsonDecode(entryListString);
      setState(() {
        _entries.clear();
        _entries.addAll(entryListJson.map((e) => Entry.fromJson(e)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khtafa Dnem'),
        backgroundColor: const Color(0xFF454955),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Car Plate Number:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF454955),
                hintText: 'e.g., 12345',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select City Code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedCityCode,
              items: List.generate(72, (index) {
                final code = (index + 1).toString();
                return DropdownMenuItem(value: code, child: Text('$code'));
              }),
              dropdownColor: const Color(0xFF454955),
              onChanged: (value) {
                setState(() {
                  _selectedCityCode = value!;
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Arabic Letter:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedLetter,
              items: const [
                DropdownMenuItem(value: 'أ', child: Text('أ')),
                DropdownMenuItem(value: 'ب', child: Text('ب')),
                DropdownMenuItem(value: 'د', child: Text('د')),
                DropdownMenuItem(value: 'ه', child: Text('ه')),
              ],
              dropdownColor: const Color(0xFF454955),
              onChanged: (value) {
                setState(() {
                  _selectedLetter = value!;
                });
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Image (Optional)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF454955),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _saveEntry,
              child: const Text('Save Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF454955),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Saved Entries:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF454955),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageWidget(entry.imagePath),
                        Expanded(
                          child: Text(
                            '${entry.plate} | ${entry.letter} | ${entry.cityCode} - ${entry.dateTime}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
