import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('My Cart'),
        actions: [
          IconButton(
            //bill maker
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              try {
                // get user details
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                if (!userDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User details not found!")),
                  );
                  return;
                }

                final userData = userDoc.data()!;
                final userName = userData['name'] ?? 'Unknown';
                final userEmail = userData['email'] ?? user.email;

                // get cart items
                final cartRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('cart');

                final cartSnap = await cartRef.get();

                if (cartSnap.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cart is empty!")),
                  );
                  return;
                }

                double total = 0.0;
                List<Map<String, dynamic>> products = [];

                for (var doc in cartSnap.docs) {
                  final data = doc.data();
                  final price = (data['price'] ?? 0) as num;
                  final qty = (data['quantity'] ?? 0) as num;
                  total += price * qty;

                  products.add({
                    'name': data['name'],
                    'price': price,
                    'quantity': qty,
                  });
                }

                // save bill
                await FirebaseFirestore.instance.collection('Bills').add({
                  'userId': user.uid,
                  'userName': userName,
                  'userEmail': userEmail,
                  'products': products,
                  'total': total,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // clear cart
                for (var doc in cartSnap.docs) {
                  await doc.reference.delete();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bill generated successfully!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            //bill action

            icon: const Icon(Icons.receipt_long),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final cartItems = snapshot.data!.docs;
          double totalBill = 0.0;

          for (var doc in cartItems) {
            final price = (doc['price'] ?? 0) as num;
            final quantity = (doc['quantity'] ?? 0) as num;
            totalBill += price * quantity;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Bill: Rs. ${totalBill.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cart = cartItems[index];
                    final productCode = cart.id;
                    final productName = cart['name'] ?? 'Product';
                    final productPrice = (cart['price'] ?? 0) as num;
                    final productQty = (cart['quantity'] ?? 0) as int;
                    final imageUrl = cart['imageUrl'] ?? '';

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                        )
                            : const Icon(Icons.image_not_supported, size: 50),
                        title: Text(productName),
                        subtitle:
                        Text("Rs. $productPrice x $productQty"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,color: Colors.orange,),
                              onPressed: () async {
                                if (productQty > 1) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .doc(productCode)
                                      .update({'quantity': productQty - 1});
                                  // work kar ra ho geting pro code
                                  final procode=await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .doc(productCode)
                                      .get();
                                  String pro = procode['productCode'];
                                  //////
                                  // Now update the quantity in the products collection
                                  final productSnapshot = await FirebaseFirestore.instance
                                      .collection('products')
                                      .where('productCode', isEqualTo: pro)
                                      .get();

                                  if (productSnapshot.docs.isNotEmpty) {
                                    final productDocId = productSnapshot.docs.first.id;

                                    await FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(productDocId)
                                        .update({
                                      'quantity': FieldValue.increment(1),
                                    });
                                  }
                                  /////
                                } else {
                                  final procode=await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .doc(productCode)
                                      .get();
                                  String pro = procode['productCode'];

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .doc(productCode)
                                      .delete();

                                  // work kar ra ho geting pro code
                                  //////
                                  // Now update the quantity in the products collection
                                  final productSnapshot = await FirebaseFirestore.instance
                                      .collection('products')
                                      .where('productCode', isEqualTo: pro)
                                      .get();

                                  if (productSnapshot.docs.isNotEmpty) {
                                    final productDocId = productSnapshot.docs.first.id;

                                    await FirebaseFirestore.instance
                                        .collection('products')
                                        .doc(productDocId)
                                        .update({
                                      'quantity': FieldValue.increment(1),
                                    });
                                  }
                                  /////
                                }
                              },
                            ),
                            Text('$productQty',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.orange,),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('cart')
                                    .doc(productCode)
                                    .update({
                                  'quantity': FieldValue.increment(1),
                                });

                                // work kar ra ho geting pro code
                                final procode=await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('cart')
                                    .doc(productCode)
                                    .get();
                                String pro = procode['productCode'];
                                //////
                                // Now update the quantity in the products collection
                                final productSnapshot = await FirebaseFirestore.instance
                                    .collection('products')
                                    .where('productCode', isEqualTo: pro)
                                    .get();

                                if (productSnapshot.docs.isNotEmpty) {
                                  final productDocId = productSnapshot.docs.first.id;

                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(productDocId)
                                      .update({
                                    'quantity': FieldValue.increment(-1),
                                  });
                                }
                                /////
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}