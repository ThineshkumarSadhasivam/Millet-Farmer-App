import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'buyer_product_detail_screen.dart'; // ✅ IMPORTANT

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  String? selectedMillet;
  String? selectedQuality;
  RangeValues priceRange = const RangeValues(0, 200);

  final List<String> milletTypes = [
    'Ragi',
    'Jowar',
    'Bajra',
    'Foxtail',
    'Little'
  ];

  final List<String> qualities = ['A', 'B', 'C'];

  bool matchesFilter(Map<String, dynamic> data) {
    final price = (data['pricePerKg'] ?? 0).toDouble();

    if (selectedMillet != null &&
        data['milletType'] != selectedMillet) return false;

    if (selectedQuality != null &&
        data['quality'] != selectedQuality) return false;

    if (price < priceRange.start || price > priceRange.end) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Millets'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          // 🔍 FILTER UI
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMillet,
                        hint: const Text('Millet'),
                        items: milletTypes
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedMillet = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedQuality,
                        hint: const Text('Quality'),
                        items: qualities
                            .map((q) => DropdownMenuItem(
                                  value: q,
                                  child: Text(q),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedQuality = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Price Range: ₹${priceRange.start.toInt()} - ₹${priceRange.end.toInt()}'),
                    RangeSlider(
                      min: 0,
                      max: 200,
                      divisions: 20,
                      values: priceRange,
                      onChanged: (v) {
                        setState(() => priceRange = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // 📋 BUYER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('status', isEqualTo: 'available')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return matchesFilter(data);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching millets'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['milletType'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quality: ${data['quality']}'),
                            Text('Quantity: ${data['quantityKg']} kg'),
                            Text('Price: ₹${data['pricePerKg']} / kg'),
                          ],
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),

                        // ✅ THIS WAS MISSING
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyerProductDetailScreen(
                                productData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
