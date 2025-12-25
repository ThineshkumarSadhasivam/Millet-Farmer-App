import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_product_detail_screen.dart';

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

  void openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Millets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedMillet,
                hint: const Text('Millet Type'),
                items: milletTypes
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => selectedMillet = v),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedQuality,
                hint: const Text('Quality'),
                items: qualities
                    .map((q) =>
                        DropdownMenuItem(value: q, child: Text(q)))
                    .toList(),
                onChanged: (v) => setState(() => selectedQuality = v),
              ),

              const SizedBox(height: 20),

              Text(
                'Price Range: ₹${priceRange.start.toInt()} - ₹${priceRange.end.toInt()}',
              ),
              RangeSlider(
                min: 0,
                max: 200,
                divisions: 20,
                values: priceRange,
                onChanged: (v) => setState(() => priceRange = v),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'Millet Market',
           style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: openFilterSheet,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('status', isEqualTo: 'available')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No millets available'));
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return matchesFilter(data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrl =
                  (data['imageUrls'] as List).isNotEmpty
                      ? data['imageUrls'][0]
                      : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['milletType'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Chip(
                                label: Text('Quality ${data['quality']}'),
                                backgroundColor: Colors.green.shade100,
                              ),
                              const SizedBox(width: 10),
                              Text('${data['quantityKg']} kg'),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '₹${data['pricePerKg']} / kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BuyerProductDetailScreen(
                                                productData: data),
                                      ),
                                    );
                                  },
                                  child: const Text('View Details'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Buy clicked ✅ (Order flow coming soon)'),
                                      ),
                                    );
                                  },
                                  child: const Text('Buy Now'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
