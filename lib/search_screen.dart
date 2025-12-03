import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedCategory = '';

  List<Map<String, dynamic>> _activeDiscounts = [];
  late final StreamSubscription _discountsSub;

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.local_florist, 'label': 'Fruits'},
    {'icon': Icons.grass, 'label': 'Vegetables'},
    {'icon': Icons.electrical_services, 'label': 'Electronics'},
    {'icon': Icons.shopping_cart, 'label': 'Grocery'},
    {'icon': Icons.cake, 'label': 'Bakery'},
    {'icon': Icons.local_drink, 'label': 'Beverages'},
    {'icon': Icons.icecream, 'label': 'Dairy Products'},
    {'icon': Icons.ac_unit, 'label': 'Frozen Foods'},
    {'icon': Icons.fastfood, 'label': 'Snacks'},
    {'icon': Icons.cleaning_services, 'label': 'Household Supplies'},
    {'icon': Icons.edit, 'label': 'Stationery'},
    {'icon': Icons.checkroom, 'label': 'Clothing'},
    {'icon': Icons.shopping_bag, 'label': 'Footwear'},
    {'icon': Icons.toys, 'label': 'Toys'},
    {'icon': Icons.face, 'label': 'Cosmetics'},
    {'icon': Icons.spa, 'label': 'Personal Care'},
    {'icon': Icons.baby_changing_station, 'label': 'Baby Products'},
    {'icon': Icons.pets, 'label': 'Pet Supplies'},
    {'icon': Icons.home, 'label': 'Home Decor'},
    {'icon': Icons.weekend, 'label': 'Furniture'},
    {'icon': Icons.kitchen, 'label': 'Kitchenware'},
    {'icon': Icons.handyman, 'label': 'Hardware Tools'},
    {'icon': Icons.directions_car, 'label': 'Automotive'},
    {'icon': Icons.menu_book, 'label': 'Books'},
    {'icon': Icons.fitness_center, 'label': 'Sports & Fitness'},
    {'icon': Icons.grass_outlined, 'label': 'Gardening'},
    {'icon': Icons.phone_iphone, 'label': 'Mobile Accessories'},
    {'icon': Icons.watch, 'label': 'Watches'},
    {'icon': Icons.diamond, 'label': 'Jewelry'},
    {'icon': Icons.computer, 'label': 'Computers & Laptops'},
  ];

  @override
  void initState() {
    super.initState();
    _listenToDiscounts();
  }

  @override
  void dispose() {
    _discountsSub.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenToDiscounts() {
    _discountsSub = FirebaseFirestore.instance
        .collection('discounts')
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      final List<Map<String, dynamic>> active = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime? start;
        DateTime? end;

        final startRaw = data['startDate'];
        final endRaw = data['endDate'];

        try {
          if (startRaw is Timestamp) start = startRaw.toDate();
          else if (startRaw is String) start = DateFormat('dd/MM/yyyy').parse(startRaw);
        } catch (_) {}
        try {
          if (endRaw is Timestamp) end = endRaw.toDate();
          else if (endRaw is String) end = DateFormat('dd/MM/yyyy').parse(endRaw);
        } catch (_) {}

        if (start == null || end == null) continue;
        if (!(now.isBefore(start) || now.isAfter(end))) {
          final saved = Map<String, dynamic>.from(data);
          saved['_docId'] = doc.id;
          active.add(saved);
        }
      }

      setState(() => _activeDiscounts = active);
    }, onError: (_) {
      setState(() => _activeDiscounts = []);
    });
  }

  double _getBestDiscountPercentForCategory(String category) {
    double best = 0.0;
    for (var disc in _activeDiscounts) {
      try {
        final catsRaw = disc['categories'];
        List<String> cats = [];
        if (catsRaw is List) cats = catsRaw.map((e) => e.toString()).toList();
        else if (catsRaw is String) cats = [catsRaw];

        if (cats.contains('All') || cats.contains(category)) {
          dynamic pRaw = disc['percentage'] ?? disc['discountPercentage'] ?? disc['discount'] ?? disc['discountPercent'];
          double p = 0.0;
          if (pRaw != null) {
            if (pRaw is num) p = pRaw.toDouble();
            else p = double.tryParse(pRaw.toString()) ?? 0.0;
          }
          if (p > best) best = p;
        }
      } catch (_) {}
    }
    return best;
  }

  double _getDiscountedPriceFromProductData(Map<String, dynamic> productData) {
    double price = 0.0;
    final p = productData['price'];
    if (p is num) price = p.toDouble();
    else price = double.tryParse(p.toString()) ?? 0.0;

    final category = (productData['category'] ?? '').toString();
    final percent = _getBestDiscountPercentForCategory(category);
    if (percent <= 0) return price;

    return price - (price * (percent / 100));
  }

  Future<void> addToCartSafe(DocumentSnapshot productDoc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add to cart")),
      );
      return;
    }

    final productRef = FirebaseFirestore.instance.collection('products').doc(productDoc.id);
    final cartRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('cart').doc(productDoc.id);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final prodSnap = await txn.get(productRef);
        if (!prodSnap.exists) throw Exception("Product not found");

        final currentQty = (prodSnap.data() as Map<String, dynamic>)['quantity'] ?? 0;
        if (currentQty <= 0) throw Exception("Out of stock");

        final cartSnap = await txn.get(cartRef);
        final productData = prodSnap.data() as Map<String, dynamic>;
       // final finalPrice = _getDiscountedPriceFromProductData(productData);
        final finalPrice = _getDiscountedPriceFromProductData(productData).roundToDouble();


        if (cartSnap.exists) {
          final existingQty = (cartSnap.data() as Map<String, dynamic>)['quantity'] ?? 0;
          txn.update(cartRef, {'quantity': existingQty + 1, 'price': finalPrice});
        } else {
          txn.set(cartRef, {
            'productCode': productData['productCode'] ?? '',
            'name': productData['name'] ?? '',
            'price': finalPrice,
            'originalPrice': productData['price'] ?? 0,
            'imageUrl': productData['imageUrl'] ?? '',
            'quantity': 1,
            'category': productData['category'] ?? '',
          });
        }

        txn.update(productRef, {'quantity': FieldValue.increment(-1)});
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $msg")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsRef = FirebaseFirestore.instance.collection('products');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for products...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      selectedCategory = '';
                    });
                  },
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toLowerCase();
                  if (searchQuery.isNotEmpty) selectedCategory = '';
                });
              },
            ),
          ),

          // Category scroller
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: categories.map((cat) {
                final label = cat['label'] as String;
                final isSelected = selectedCategory == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = (selectedCategory == label) ? '' : label;
                        _searchController.clear();
                        searchQuery = '';
                      });
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isSelected ? Colors.orange : Colors.green.shade200,
                          child: Icon(cat['icon'], color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 5),
                        Text(label, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Product list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();
                  final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);
                  final matchesCategory = selectedCategory.isEmpty || category == selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No products match your search.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    final data = doc.data() as Map<String, dynamic>;
                    final img = data['imageUrl'] ?? '';
                    final originalPrice = (data['price'] ?? 0).toDouble();
                    final discountedPrice = _getDiscountedPriceFromProductData(data).roundToDouble();
                    final discountPercent = _getBestDiscountPercentForCategory(data['category'] ?? '');

                    return Card(
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                img,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
                              ),
                            ),
                            if (discountPercent > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '-${discountPercent.toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Rs $discountedPrice',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                          onPressed: () => addToCartSafe(doc),
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
