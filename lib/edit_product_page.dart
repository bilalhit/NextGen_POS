import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'QRDisplayPage.dart';
import 'ProductListPage.dart'; // Update this import path as needed

class EditProductPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  Color accentOrange = Color(0xFFE68030);

  String? selectedCategory;
  final List<String> categoryList = [
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

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.productData['name']);
    priceController = TextEditingController(text: widget.productData['price'].toString());
    quantityController = TextEditingController(text: widget.productData['quantity'].toString());

    String existingCategory = widget.productData['category'] ?? '';

    // ✅ Ensure product’s existing category is included in dropdown
    if (existingCategory.isNotEmpty && !categoryList.contains(existingCategory)) {
      categoryList.insert(0, existingCategory);
    }

    selectedCategory = existingCategory.isNotEmpty ? existingCategory : categoryList.first;
  }

  void _updateProduct() async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'name': nameController.text.trim(),
        'category': selectedCategory ?? '',
        'price': int.tryParse(priceController.text.trim()) ?? 0,
        'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Product updated successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProductListPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Update failed: $e')),
      );
    }
  }

  void _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final imageUrl = widget.productData['imageUrl'] ?? '';
        if (imageUrl.isNotEmpty) {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        }

        await FirebaseFirestore.instance.collection('products').doc(widget.productId).delete();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductListPage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Product deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting product: $e")),
        );
      }
    }
  }

  void _generateQRCode() {
    final productCode = widget.productData['productCode'];
    final productName = nameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRDisplayPage(
          productCode: productCode,
          productName: productName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _deleteProduct,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 10),

              // 🔽 Dropdown for category with existing value selected
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categoryList
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(backgroundColor: accentOrange),
                child: const Text('Update Product'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _generateQRCode,
                style: ElevatedButton.styleFrom(backgroundColor: accentOrange),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code, color: Colors.white),
                    SizedBox(width: 4),
                    Icon(Icons.line_weight, color: Colors.white),
                  ],
                ),
                label: const Text(
                  'Generate Code',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}