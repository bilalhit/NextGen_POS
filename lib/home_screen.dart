import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'profile_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentPromoIndex = 0;
  final PageController _pageController = PageController();
  late Timer _promoTimer;
  bool _showPromotions = true;
  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0;

  // --- DISCOUNT DATA ---
  List<Map<String, dynamic>> _activeDiscounts = [];
  StreamSubscription<QuerySnapshot>? _discountsSub;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final direction = offset - _lastOffset;

      if (direction > 0 && _showPromotions) {
        setState(() => _showPromotions = false);
      } else if (direction < 0 && !_showPromotions) {
        setState(() => _showPromotions = true);
      }

      _lastOffset = offset;
    });

    _promoTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentPromoIndex++;
        });
      }
    });

    // start listening to discounts collection
    _listenToDiscounts();
  }

  void _listenToDiscounts() {
    // Listen to discounts collection and keep only active discounts
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

        // support Timestamp or string date (dd/MM/yyyy)
        final startRaw = data['startDate'];
        final endRaw = data['endDate'];

        try {
          if (startRaw is Timestamp) {
            start = startRaw.toDate();
          } else if (startRaw is String) {
            start = DateFormat('dd/MM/yyyy').parse(startRaw);
          }
        } catch (e) {
          start = null;
        }

        try {
          if (endRaw is Timestamp) {
            end = endRaw.toDate();
          } else if (endRaw is String) {
            end = DateFormat('dd/MM/yyyy').parse(endRaw);
          }
        } catch (e) {
          end = null;
        }

        // If start or end missing, skip (you can change behavior)
        if (start == null || end == null) continue;

        // check active: inclusive of start and end dates
        if (!(now.isBefore(start) || now.isAfter(end))) {
          // active discount
          // add doc data but also keep doc id (optional)
          final Map<String, dynamic> saved = Map<String, dynamic>.from(data);
          saved['_docId'] = doc.id;
          active.add(saved);
        }
      }

      setState(() {
        _activeDiscounts = active;
      });
    }, onError: (err) {
      // If error, just clear discounts
      setState(() => _activeDiscounts = []);
      // print optional
      // print('Discount listener error: $err');
    });
  }

  @override
  void dispose() {
    _promoTimer.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _discountsSub?.cancel();
    super.dispose();
  }

  // ---------------------------
  // Helpers: choose best discount
  // ---------------------------
  /// Returns best (highest) discount percent applicable for given category.
  /// If none, returns 0.
  double _getBestDiscountPercentForCategory(String category) {
    double best = 0.0;
    for (var disc in _activeDiscounts) {
      try {
        final catsRaw = disc['categories'];
        // normalize categories into List<String>
        List<String> cats = [];
        if (catsRaw is List) {
          cats = catsRaw.map((e) => e.toString()).toList();
        } else if (catsRaw is String) {
          cats = [catsRaw];
        }

        final contains = cats.contains('All') || cats.contains(category);
        if (contains) {
          // percentage field could be 'percentage' or 'discountPercentage' etc.
          dynamic pRaw = disc['percentage'] ?? disc['discountPercentage'] ?? disc['discount'] ?? disc['discountPercent'];
          double p = 0.0;
          if (pRaw != null) {
            if (pRaw is num) p = pRaw.toDouble();
            else p = double.tryParse(pRaw.toString()) ?? 0.0;
          }
          if (p > best) best = p;
        }
      } catch (e) {
        // ignore malformed discount doc
        continue;
      }
    }
    return best;
  }

  double _getDiscountedPriceFromProductData(Map<String, dynamic> productData) {
    double price = 0.0;
    try {
      final p = productData['price'];
      if (p is num) price = p.toDouble();
      else price = double.tryParse(p.toString()) ?? 0.0;
    } catch (e) {
      price = 0.0;
    }

    final category = (productData['category'] ?? '').toString();

    final percent = _getBestDiscountPercentForCategory(category);
    if (percent <= 0) return price;

    final discounted = price - (price * (percent / 100));
    return discounted.roundToDouble();
  }

  // ---------------------------
  // addToCart (updated to use discounted price)
  // ---------------------------
  Future<void> addToCart(BuildContext context, Map<String, dynamic> product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add to cart')),
        );
        return;
      }

      final productCode = product['productCode'];

      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('productCode', isEqualTo: productCode)
          .get();

      if (productsQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
        return;
      }

      final productDoc = productsQuery.docs.first;
      final productRef = productDoc.reference;
      final productData = productDoc.data() as Map<String, dynamic>;

      int currentStock = 0;
      try {
        final q = productData['quantity'];
        if (q is int) currentStock = q;
        else if (q is num) currentStock = q.toInt();
        else currentStock = int.tryParse(q.toString()) ?? 0;
      } catch (e) {
        currentStock = 0;
      }

      if (currentStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product out of stock')),
        );
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final cartQuery = await cartRef
          .where('productCode', isEqualTo: productCode)
          .get();

      // compute final price (with discount if applicable)
      final double finalPrice = _getDiscountedPriceFromProductData(productData).roundToDouble();
      final double originalPrice;
      {
        final p = productData['price'];
        if (p is num) originalPrice = p.toDouble();
        else originalPrice = double.tryParse(p.toString()) ?? finalPrice;
      }

      if (cartQuery.docs.isEmpty) {
        await cartRef.add({
          'productCode': productCode,
          'name': productData['name'] ?? '',
          'price': finalPrice,
          'originalPrice': originalPrice,
          'imageUrl': productData['imageUrl'] ?? '',
          'quantity': 1,
          'category': productData['category'] ?? '',
        });
      } else {
        final cartDoc = cartQuery.docs.first;
        await cartDoc.reference.update({
          'quantity': FieldValue.increment(1),
        });
      }

      await productRef.update({
        'quantity': FieldValue.increment(-1),
      });

      // optional snack
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Added to cart')),
      // );
    } catch (e) {
      // print or show error
      // print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildPromotionCarousel(List<String> images) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (index) {
          setState(() {
            _currentPromoIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------
  // Product card updated to show discount UI
  // ---------------------------
  Widget _buildProductCard(Map<String, dynamic> product) {
    // calculate price and discounted price (use product's price & category)
    double price = 0.0;
    try {
      final p = product['price'];
      if (p is num) price = p.toDouble();
      else price = double.tryParse(p.toString()) ?? 0.0;
    } catch (e) {
      price = 0.0;
    }

    final category = (product['category'] ?? '').toString();

    final double discountedPrice = _getDiscountedPriceFromProductData(product).roundToDouble();
    final bool hasDiscount = discountedPrice < price && discountedPrice > 0;

    return Card(
      color: Colors.orangeAccent, // Card color changed
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(product['imageUrl'], fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white, // Text color changed
                  ),
                ),
                const SizedBox(height: 6),
                // PRICE DISPLAY: original (line-through) + discounted
                hasDiscount
                    ? Column(
                  children: [
                    Text(
                      "Rs. ${price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Rs. ${discountedPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
                    : Text(
                  "Rs. ${price.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white), // Text color changed
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green), // Icon color changed
                  onPressed: () {
                    addToCart(context, product);
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showPromotions
              ? StreamBuilder<QuerySnapshot>(
            key: const ValueKey(true),
            stream: FirebaseFirestore.instance.collection('promotions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                    height: 180, child: Center(child: CircularProgressIndicator()));
              }

              final docs = snapshot.data!.docs;
              final imageUrls = docs.map((doc) => doc['imageUrl'] as String).toList();

              if (imageUrls.isEmpty) {
                return const SizedBox(
                    height: 180, child: Center(child: Text('No promotions')));
              }

              return _buildPromotionCarousel(imageUrls);
            },
          )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((product) => product['quantity'] != null && product['quantity'] > 0)
                  .toList();

              if (products.isEmpty) {
                return const Center(
                  child: Text(
                    'No products available right now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) => _buildProductCard(products[index]),
              );
            },
          ),
        )
      ],
    );
  }

  late List<Widget> _screens;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screens = <Widget>[
      _buildHomePage(),
      const SearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openQRScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
  }

  void _openDrawer(BuildContext context) => Scaffold.of(context).openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Home', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.green),
            onPressed: () => _openDrawer(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner, color: Colors.green),
            onPressed: _openQRScreen,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        type: BottomNavigationBarType.fixed,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Categories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.local_florist, color: Colors.orange),
              title: const Text('Fruits'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.grass, color: Colors.orange),
              title: const Text('Vegetables'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.electrical_services, color: Colors.orange),
              title: const Text('Electronics'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.orange),
              title: const Text('Grocery'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cake, color: Colors.orange),
              title: const Text('Bakery'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.local_drink, color: Colors.orange),
              title: const Text('Beverages'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.icecream, color: Colors.orange),
              title: const Text('Dairy Products'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.ac_unit, color: Colors.orange),
              title: const Text('Frozen Foods'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fastfood, color: Colors.orange),
              title: const Text('Snacks'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.orange),
              title: const Text('Household Supplies'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Stationery'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.checkroom, color: Colors.orange),
              title: const Text('Clothing'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.orange),
              title: const Text('Footwear'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.toys, color: Colors.orange),
              title: const Text('Toys'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.face, color: Colors.orange),
              title: const Text('Cosmetics'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.spa, color: Colors.orange),
              title: const Text('Personal Care'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.baby_changing_station, color: Colors.orange),
              title: const Text('Baby Products'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.orange),
              title: const Text('Pet Supplies'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.orange),
              title: const Text('Home Decor'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.weekend, color: Colors.orange),
              title: const Text('Furniture'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.kitchen, color: Colors.orange),
              title: const Text('Kitchenware'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.handyman, color: Colors.orange),
              title: const Text('Hardware Tools'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.orange),
              title: const Text('Automotive'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.orange),
              title: const Text('Books'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.orange),
              title: const Text('Sports & Fitness'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.grass_outlined, color: Colors.orange),
              title: const Text('Gardening'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.phone_iphone, color: Colors.orange),
              title: const Text('Mobile Accessories'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.computer, color: Colors.orange),
              title: const Text('Computers & Laptops'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.diamond, color: Colors.orange),
              title: const Text('Jewelry'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.watch, color: Colors.orange),
              title: const Text('Watches'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
