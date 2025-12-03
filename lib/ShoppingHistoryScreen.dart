import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ShoppingHistoryScreen extends StatefulWidget {
  const ShoppingHistoryScreen({super.key});

  @override
  State<ShoppingHistoryScreen> createState() => _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends State<ShoppingHistoryScreen> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping History"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Bills')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading bills"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No purchase history found."));
          }

          final bills = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final products = List<Map<String, dynamic>>.from(bill['products']);
              final total = bill['total'];
              final timestamp = bill['createdAt'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : 'Unknown';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Card(
                  color: const Color(0xFFE68030), // theme color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    title: Text(
                      "Bill #${index + 1} - $date",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Total: Rs. $total",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    children: products
                        .map((product) => ListTile(
                      title: Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "Price: Rs. ${product['price']} x ${product['quantity']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ))
                        .toList(),
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
