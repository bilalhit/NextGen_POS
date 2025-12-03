import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cart_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final Set<String> _scannedCodes = {}; // To avoid duplicates
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('QR Scanner'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
            child: const Text(
              "Done",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (!_isScanning) return;

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null && code.isNotEmpty && !_scannedCodes.contains(code)) {
                setState(() {
                  _isScanning = false;
                  _scannedCodes.add(code);
                });

                await _addProductToCart(context, code);

                // Delay to allow next scan
                await Future.delayed(const Duration(seconds: 2));
                setState(() {
                  _isScanning = true;
                });
              }
            },
          ),

          // Scanner box
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instruction text
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Place QR code inside the box",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProductToCart(BuildContext context, String productCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('productCode', isEqualTo: productCode)
          .get();

      if (productsQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
        return;
      }

      final productDoc = productsQuery.docs.first;
      final productRef = productDoc.reference;
      final product = productDoc.data();

      int currentStock = product['quantity'];

      if (currentStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product out of stock')),
        );
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final cartQuery = await cartRef
          .where('productCode', isEqualTo: productCode)
          .get();

      if (cartQuery.docs.isEmpty) {
        await cartRef.add({
          'productCode': productCode,
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'],
          'quantity': 1,
        });
      } else {
        final cartDoc = cartQuery.docs.first;
        await cartDoc.reference.update({
          'quantity': FieldValue.increment(1),
        });
      }

      // Reduce stock in products
      await productRef.update({
        'quantity': FieldValue.increment(-1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${product['name']} to cart')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
