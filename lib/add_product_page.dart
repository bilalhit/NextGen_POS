import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'QRDisplayPage.dart';
import 'scan_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  Color accentOrange = Color(0xFFE68030);


  String? selectedCategory;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Electronics',
    'Grocery',
    'Bakery',
    'Beverages',
    'Dairy Products',
    'Frozen Foods',
    'Snacks',
    'Household Supplies',
    'Stationery',
    'Clothing',
    'Footwear',
    'Toys',
    'Cosmetics',
    'Personal Care',
    'Baby Products',
    'Pet Supplies',
    'Home Decor',
    'Furniture',
    'Kitchenware',
    'Hardware Tools',
    'Automotive',
    'Books',
    'Sports & Fitness',
    'Gardening',
    'Mobile Accessories',
    'Computers & Laptops',
    'Jewelry',
    'Watches'
  ];


  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final fileName = const Uuid().v4(); // Unique filename
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('$fileName.jpg');

      final uploadTask = await storageRef.putFile(_imageFile!);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      final productCode = codeController.text.trim();
      final productName = nameController.text.trim();

      await FirebaseFirestore.instance.collection('products').add({
        'name': productName,
        'price': int.tryParse(priceController.text.trim()) ?? 0,
        'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
        'category': selectedCategory,
        'productCode': productCode,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QRDisplayPage(
            productName: productName,
            productCode: productCode,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }
// enter bar code update

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product"), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (value) => value!.isEmpty ? "Enter product name" : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter price" : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter quantity" : null,
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: "Category"),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
                validator: (value) => value == null ? "Select a category" : null,
              ),

              const SizedBox(height: 10),

              // TextFormField(
              //   controller: codeController,
              //   decoration: const InputDecoration(labelText: "Product Code (Unique)"),
              //   validator: (value) => value!.isEmpty ? "Enter product code" : null,
              // ),
              //data enter
              TextFormField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: "Product Code (Unique)",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ScanPage()),
                      );

                      if (result != null) {
                        codeController.text = result;
                      }
                    },
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Enter product code" : null,
              ),
              // data delele
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: accentOrange),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Generate Codes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
