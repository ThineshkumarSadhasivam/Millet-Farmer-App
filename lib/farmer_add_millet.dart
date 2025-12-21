import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FarmerAddMilletScreen extends StatefulWidget {
  const FarmerAddMilletScreen({super.key});

  @override
  State<FarmerAddMilletScreen> createState() => _FarmerAddMilletScreenState();
}

class _FarmerAddMilletScreenState extends State<FarmerAddMilletScreen> {
  final _formKey = GlobalKey<FormState>();

  final milletController = TextEditingController();
  final qualityController = TextEditingController();
  final quantityController = TextEditingController();
  final moistureController = TextEditingController();
  final priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> images = [];

  bool isSubmitting = false;

  /// 📸 Capture image from camera
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        images.add(image);
      });
    }
  }

  /// ☁ Upload all images to Firebase Storage
  Future<List<String>> uploadImages() async {
    final List<String> downloadUrls = [];

    for (final image in images) {
      final file = File(image.path);
      final fileName =
          'millets/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);

      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
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
        'quality': qualityController.text.trim(),
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
      appBar: AppBar(
        title: const Text('Add Millet'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Millet Photo'),
              ),

              const SizedBox(height: 8),
              Text('${images.length} photo(s) added'),

              const SizedBox(height: 16),

              TextFormField(
                controller: milletController,
                decoration: const InputDecoration(labelText: 'Millet Type'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: qualityController,
                decoration: const InputDecoration(labelText: 'Quality (A/B/C)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: moistureController,
                decoration: const InputDecoration(labelText: 'Moisture (%)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Price per kg'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isSubmitting ? null : submitProduct,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('List Millet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
