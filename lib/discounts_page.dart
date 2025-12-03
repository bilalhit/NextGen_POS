import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_discount_page.dart';

const Color primaryGreen = Color(0xFF00A86B);
const Color accentOrange = Color(0xFFE68030);

class DiscountsPage extends StatelessWidget {
  const DiscountsPage({super.key});

  void _deleteDiscount(String id) {
    FirebaseFirestore.instance.collection('discounts').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discounts"),
        backgroundColor: primaryGreen,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDiscountPage()),
              );
            },
            icon: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('discounts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Discounts Available", style: TextStyle(fontSize: 18)),
            );
          }

          final discounts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final data = discounts[index].data() as Map<String, dynamic>;
              final id = discounts[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.percent, color: primaryGreen, size: 32),
                  title: Text(data['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Discount: ${data['percentage']}%"),
                      Text("From: ${data['startDate']}"),
                      Text("To: ${data['endDate']}"),
                      Text("Categories: ${data['categories'].join(', ')}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: accentOrange),
                    onPressed: () => _deleteDiscount(id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
