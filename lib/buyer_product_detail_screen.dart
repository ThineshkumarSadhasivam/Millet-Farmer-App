import 'package:flutter/material.dart';

class BuyerProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> productData;

  const BuyerProductDetailScreen({
    super.key,
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ SAFE IMAGE URL LIST
    final List<String> imageUrls =
        (productData['imageUrls'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Millet Details'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 IMAGE PREVIEW
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[index],
                          width: 280,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 280,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 280,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.broken_image,
                                size: 60,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_not_supported,
                  size: 80,
                ),
              ),

            const SizedBox(height: 24),

            // 🌾 MILLET NAME
            Text(
              productData['milletType'] ?? 'Millet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 📋 DETAILS
            detailRow('Quality', productData['quality'] ?? '-'),
            detailRow(
              'Quantity',
              '${productData['quantityKg'] ?? 0} kg',
            ),
            detailRow(
              'Moisture',
              '${productData['moisture'] ?? 0} %',
            ),
            detailRow(
              'Price',
              '₹${productData['pricePerKg'] ?? 0} / kg',
            ),
            detailRow(
              'Photos',
              imageUrls.length.toString(),
            ),

            const SizedBox(height: 30),

            // 🔒 CONTACT BUTTON (FUTURE)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contact will be enabled after confirmation',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.call),
                label: const Text('Contact Farmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 REUSABLE ROW
  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
