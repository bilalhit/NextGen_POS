import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'splash_screen.dart';
import 'edit_profile_screen.dart';
import 'register_screen.dart';
import 'ShoppingHistoryScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? imageUrl;
  String userName = "Loading...";
  String? userEmail;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      setState(() {
        isGuest = true;
        userName = "Guest";
        userEmail = null;
        imageUrl = null;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      userName = data?['name'] ?? "User";
      userEmail = data?['email'];
      imageUrl = data?['profileImage']; // ✅ load from Firestore
    });
  }

  Future<void> pickImageAndUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');

    // Upload the image
    await storageRef.putFile(file);

    // Get the URL
    final newUrl = await storageRef.getDownloadURL();

    // Update FirebaseAuth photo URL (optional)
    await user.updatePhotoURL(newUrl);

    // ✅ Update Firestore with new image URL
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImage': newUrl,
    });

    setState(() {
      imageUrl = newUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile picture updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl!)
                        : const AssetImage("assets/images/user_placeholder.png") as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: pickImageAndUpload,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 20, color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                userName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (!isGuest) ...[
                const SizedBox(height: 8),
                Text(
                  userEmail ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              //shoping history
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  if (isGuest) {
                    // Guest → send to Register screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  } else {
                    // Logged‑in user → send to Edit Profile screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShoppingHistoryScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text("Shopping History", style: TextStyle(fontSize: 16)),
              ),

              //history ha
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (isGuest) {
                    // Guest → send to Register screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  } else {
                    // Logged‑in user → send to Edit Profile screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Edit Profile", style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
