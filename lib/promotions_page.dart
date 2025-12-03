import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key});

  void _deletePromotion(BuildContext context, String promoId) async {
    try {
      await FirebaseFirestore.instance.collection('promotions').doc(promoId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    const Color accentOrange = Color(0xFFE68030);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Promotions'),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No promotions added yet.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final promotions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              final data = promo.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: primaryGreen.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        data['imageUrl'] ?? '',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        data['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delete Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconButton(
                        icon: Icon(Icons.delete, color: accentOrange, size: 28),
                        onPressed: () => _deletePromotion(context, promo.id),
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
