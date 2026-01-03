import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/photo_upload_card.dart';
import 'analysis_screen.dart';

class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});

  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  final List<String?> _imagePaths = List.filled(4, null);
  String? selectedPurpose;
  final _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> purposes = [
    {
      'title': 'Professional',
      'icon': Icons.business,
      'description': 'For LinkedIn, CV, or business profiles'
    },
    {
      'title': 'Social',
      'icon': Icons.people,
      'description': 'For social media and casual profiles'
    },
    {
      'title': 'Dating',
      'icon': Icons.favorite,
      'description': 'For dating apps and relationship profiles'
    },
    {
      'title': 'Creative',
      'icon': Icons.palette,
      'description': 'For artistic and creative portfolios'
    },
  ];

  Future<void> _pickImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePaths[index] = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Photos'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload 4 Photos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return PhotoUploadCard(
                  imagePath: _imagePaths[index],
                  onTap: () => _pickImage(index),
                  index: index + 1,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Purpose',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...purposes.map((purpose) => _buildPurposeCard(purpose)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canProceed() ? _proceedToAnalysis : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Analyze Photos',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeCard(Map<String, dynamic> purpose) {
    final bool isSelected = selectedPurpose == purpose['title'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPurpose = purpose['title'];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                purpose['icon'],
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purpose['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                      ),
                    ),
                    Text(
                      purpose['description'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    return _imagePaths.every((path) => path != null) && selectedPurpose != null;
  }

  void _proceedToAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          imagePaths: _imagePaths.whereType<String>().toList(),
          purpose: selectedPurpose!,
        ),
      ),
    );
  }
}