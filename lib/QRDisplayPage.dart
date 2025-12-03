import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:barcode_widget/barcode_widget.dart';

class QRDisplayPage extends StatelessWidget {
  final String productCode;
  final String productName;

  const QRDisplayPage({
    Key? key,
    required this.productCode,
    required this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: productCode,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR & Barcode'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Section
            SizedBox(
              width: 200,
              height: 200,
              child: PrettyQrView(
                qrImage: QrImage(qrCode),
                decoration: const PrettyQrDecoration(),
              ),
            ),
            const SizedBox(height: 30),

            // Product name
            Text(
              productName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: <Color>[Colors.green, Colors.teal],
                  ).createShader(
                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                  ),
                shadows: [
                  const Shadow(
                    blurRadius: 4.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Barcode Section
            Text(
              'Barcode',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            BarcodeWidget(
              data: productCode,
              barcode: Barcode.code128(), // Most common barcode type
              width: 250,
              height: 100,
              drawText: true,
              style: const TextStyle(fontSize: 16, letterSpacing: 2),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
