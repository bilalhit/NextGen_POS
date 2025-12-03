import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF00A86B), // new primary green
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              "assets/images/sp.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Optional overlay gradient for better logo/text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  const Color(0xFF00A86B).withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Center logo or app name
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFFE68030), // accent orange
                  size: 90,
                ),
                SizedBox(height: 20),
                Text(
                  'NextGen POS',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
