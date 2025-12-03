import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> _categories = [
    'All',
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
    'Watches',
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00A86B);
    const Color accentOrange = Color(0xFFE39355);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        backgroundColor: primaryGreen,
      ),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: primaryGreen),
                hintText: 'Search by product name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🏷️ Category Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // 📦 Product List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data?.docs ?? [];

                // 🧠 Filter products
                final filteredProducts = products.where((product) {
                  final data = product.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category =
                  (data['category'] ?? '').toString().toLowerCase();

                  final matchesSearch = name.contains(searchQuery);
                  final matchesCategory = selectedCategory == 'All' ||
                      category == selectedCategory.toLowerCase();

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final data = product.data() as Map<String, dynamic>;
                    final quantity =
                        int.tryParse(data['quantity'].toString()) ?? 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductPage(
                              productId: product.id,
                              productData: data,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Card(
                          color: accentOrange, // ✅ updated card color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, size: 50),
                              ),
                            ),
                            title: Text(
                              data['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white, // contrast on orange
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price: Rs. ${data['price'] ?? '0'}',
                                    style: const TextStyle(color: Colors.white)),
                                Text(
                                  'Quantity: $quantity',
                                  style: TextStyle(
                                    color: quantity < 10 ? Colors.red : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (data['category'] != null)
                                  Text(
                                    'Category: ${data['category']}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
