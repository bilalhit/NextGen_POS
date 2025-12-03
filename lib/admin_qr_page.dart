import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_product_page.dart';

class AdminQRPage extends StatefulWidget {
  const AdminQRPage({super.key});

  @override
  State<AdminQRPage> createState() => _AdminQRPageState();
}

class _AdminQRPageState extends State<AdminQRPage> {
  final MobileScannerController _controller = MobileScannerController();
  Color accentOrange = Color(0xFFE68030);

  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR/BarCode Scanner"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (!_isScanning) return;

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null && code.isNotEmpty) {
                setState(() {
                  _isScanning = false;
                });

                _controller.stop();

                // 🔄 Fetch product data using the scanned product ID
                final querySnapshot = await FirebaseFirestore.instance
                    .collection('products')
                    .where('productCode', isEqualTo: code)
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final doc = querySnapshot.docs.first;
                  final productData = doc.data();
                  final productId = doc.id;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductPage(
                        productId: productId,
                        productData: productData,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Product not found')),
                  );
                  setState(() {
                    _isScanning = true;
                  });
                  _controller.start();
                }
              }
            },
          ),

          // Green border box in center
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: accentOrange, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Optional instruction
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Place codes inside the box",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
