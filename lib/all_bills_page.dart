import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TodayBillsPage.dart';

class AllBillsPage extends StatelessWidget {
  const AllBillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    const Color accentOrange = Color(0xFFE68030);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bills'),
        backgroundColor: primaryGreen,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TodayBillsPage()),
              );
            },
            icon: const Icon(Icons.today, color: Colors.white),
            label: const Text(
              "Today",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Bills')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No bills found.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          // Group bills by user
          final bills = snapshot.data!.docs;
          final Map<String, List<QueryDocumentSnapshot>> groupedByUser = {};

          for (var bill in bills) {
            final userEmail = bill['userEmail'] ?? 'Unknown';
            groupedByUser.putIfAbsent(userEmail, () => []).add(bill);
          }

          return ListView(
            children: groupedByUser.entries.map((entry) {
              final userEmail = entry.key;
              final billsOfUser = entry.value;
              final userName = billsOfUser.first['userName'] ?? 'Unknown';

              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.grey.shade300,
                  colorScheme: const ColorScheme.light(primary: accentOrange),
                ),
                child: ExpansionTile(
                  title: Text(
                    "$userName ($userEmail)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: accentOrange),
                  ),
                  children: billsOfUser.map((bill) {
                    final createdAt = (bill['createdAt'] as Timestamp).toDate();
                    final total = bill['total'] ?? 0;
                    final products = bill['products'] as List<dynamic>? ?? [];

                    return ExpansionTile(
                      title: Text(
                        "Date: ${createdAt.toLocal()}  |  Rs. $total",
                        style:
                        const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      children: products.map((p) {
                        final name = p['name'] ?? 'Unknown';
                        final qty = p['quantity'] ?? 0;
                        final price = p['price'] ?? 0;
                        return ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            "Qty: $qty  |  Price: Rs. $price",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
