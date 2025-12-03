import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';
import 'services/auth_service.dart';
import 'forgot_password_page.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void loginUser() async {
    final user = await AuthService.loginUser(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    const Color accentOrange = Color(0xFFE68030);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: primaryGreen),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // White overlay for readability
          Container(
            color: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Icon(Icons.store_rounded,
                        size: 90, color: accentOrange),
                    const SizedBox(height: 16),
                    const Text(
                      "NextGen POS",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: primaryGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                        const Icon(Icons.email, color: accentOrange),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: primaryGreen),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                        const Icon(Icons.lock, color: accentOrange),
                      ),
                    ),

                    // ========== FORGOT PASSWORD BUTTON ==========
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFFE68030),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // forget


                    const SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Continue as Guest
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                        );
                      },
                      child: const Text(
                        "Continue as Guest",
                        style: TextStyle(color: accentOrange),
                      ),
                    ),

                    // Admin login
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen()),
                        );
                      },
                      child: const Text(
                        "Login as Admin",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              color: accentOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
