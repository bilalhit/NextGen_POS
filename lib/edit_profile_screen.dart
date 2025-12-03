import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'splash_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? imageUrl;
  File? _pickedImage;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      imageUrl = data['profileImage'];
    }
    setState(() {});
  }

  Future<void> pickNewImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    String? newImageUrl = imageUrl;

    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}.jpg');
      await ref.putFile(_pickedImage!);
      newImageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'profileImage': newImageUrl,
    });

    if (user!.displayName != _nameController.text) {
      await user!.updateDisplayName(_nameController.text.trim());
    }

    if (newImageUrl != imageUrl) {
      await user!.updatePhotoURL(newImageUrl);
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Profile updated")));
    Navigator.pop(context);
  }

  Future<void> changePassword() async {
    String newPassword = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: TextFormField(
          obscureText: true,
          decoration: const InputDecoration(labelText: "New Password"),
          onChanged: (value) => newPassword = value,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                if (newPassword.length < 6) return;
                try {
                  await user!.updatePassword(newPassword);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Password updated successfully")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to update password")));
                }
              },
              child: const Text("Update")),
        ],
      ),
    );
  }

  Future<void> deleteProfile() async {
    final uid = user!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    await user!.delete();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile deleted successfully")));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Edit Profile"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (imageUrl != null
                          ? NetworkImage(imageUrl!)
                          : const AssetImage(
                          "assets/images/user_placeholder.png")) as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: pickNewImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  filled: true,
                  fillColor: Colors.green.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                value!.trim().isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  filled: true,
                  fillColor: Colors.green.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: updateProfile,
                child: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: changePassword,
                child: const Text("Change Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE68030),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: deleteProfile,
                child: const Text("Delete Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
