import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class FarmerAddMilletScreen extends StatefulWidget {
  const FarmerAddMilletScreen({super.key});

  @override
  State<FarmerAddMilletScreen> createState() => _FarmerAddMilletScreenState();
}

class _FarmerAddMilletScreenState extends State<FarmerAddMilletScreen> {
  final _formKey = GlobalKey<FormState>();

  final milletController = TextEditingController();
  final quantityController = TextEditingController();
  final moistureController = TextEditingController();
  final priceController = TextEditingController();

  String? selectedQuality;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> images = [];

  bool isSubmitting = false;

  // 🔑 Cloudinary
  static const String cloudName = "dwhoiz9wt";
  static const String uploadPreset = "millet_unsigned";

  /// 📸 Capture image
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => images.add(image));
    }
  }

  /// ☁ Upload images
  Future<List<String>> uploadImages() async {
    final List<String> urls = [];

    for (final image in images) {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final data = json.decode(await response.stream.bytesToString());
        urls.add(data['secure_url']);
      } else {
        throw Exception("Image upload failed");
      }
    }
    return urls;
  }

  /// 📦 Submit product
  Future<void> submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 photos')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final imageUrls = await uploadImages();

      await FirebaseFirestore.instance.collection('products').add({
        'milletType': milletController.text.trim(),
        'quality': selectedQuality,
        'quantityKg': int.parse(quantityController.text),
        'moisture': moistureController.text.trim(),
        'pricePerKg': int.parse(priceController.text),
        'imageUrls': imageUrls,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Millet listed successfully ✅')),
      );

      _formKey.currentState!.reset();
      setState(() {
        images.clear();
        selectedQuality = null;
        isSubmitting = false;
      });
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Add Millet'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 IMAGE SECTION
              const Text(
                'Millet Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.green, size: 40),
                      ),
                    ),
                    ...images.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(img.path),
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => images.remove(img));
                                },
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Text(
                '${images.length} photo(s) added (min 2 required)',
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // 📋 FORM CARD
              _card(
                child: Column(
                  children: [
                    _field(
                      controller: milletController,
                      label: 'Millet Type',
                      icon: Icons.grass,
                    ),
                    _dropdownQuality(),
                    _field(
                      controller: quantityController,
                      label: 'Quantity (kg)',
                      icon: Icons.scale,
                      isNumber: true,
                    ),
                    _field(
                      controller: moistureController,
                      label: 'Moisture (%)',
                      icon: Icons.water_drop,
                    ),
                    _field(
                      controller: priceController,
                      label: 'Price per kg',
                      icon: Icons.currency_rupee,
                      isNumber: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🚀 SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'List Millet',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 FORM FIELD
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // 🔹 QUALITY DROPDOWN
  Widget _dropdownQuality() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: selectedQuality,
        items: ['A', 'B', 'C']
            .map(
              (q) => DropdownMenuItem(
                value: q,
                child: Text('Quality $q'),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => selectedQuality = v),
        validator: (v) => v == null ? 'Select quality' : null,
        decoration: InputDecoration(
          labelText: 'Quality',
          prefixIcon: const Icon(Icons.grade),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // 🔹 CARD
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}
