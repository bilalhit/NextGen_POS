import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login_screen.dart';
import 'add_product_page.dart';
import 'customers_page.dart';
import 'add_promotion_page.dart';
import 'promotions_page.dart';
import 'ProductListPage.dart';
import 'SalesGraphPage.dart';
import 'all_bills_page.dart';
import 'discounts_page.dart';
import 'add_discount_page.dart';
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _userCount = 0;
  int _billCount = 0;
  int _promotionCount = 0;
  int _productCount=0;
  int _discountCount = 0;
  double todaySales = 0.0;

  @override
  void initState() {
    super.initState();
    fetchProductCount();
    fetchUserCount();
    fetchPromotionCount();
    loadTodaySales();
    fetchbillCount();
    _fetchDiscountCount();
  }

  void loadTodaySales() async {
    final sales = await getTodaySales();
    setState(() {
      todaySales = sales;
    });
  }

  // function for today sale
  Future<double> getTodaySales() async {
    try {
      final now = DateTime.now();

      // Start and end of today in local time
      final startOfDayLocal = DateTime(now.year, now.month, now.day);
      final endOfDayLocal = startOfDayLocal.add(Duration(days: 1));

      // Convert local times to Firestore Timestamps directly (keeps same zone)
      final startTimestamp = Timestamp.fromDate(startOfDayLocal);
      final endTimestamp = Timestamp.fromDate(endOfDayLocal);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Bills')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThan: endTimestamp)
          .get();

      double totalSales = 0.0;

      for (var doc in querySnapshot.docs) {
        final total = (doc['total'] ?? 0) as num;
        totalSales += total.toDouble();
      }

      return totalSales;
    } catch (e) {
      print('Error fetching today sales: $e');
      return 0.0;
    }
  }
  //bill count
  Future<void> fetchbillCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Bills').get();
      print("Fetched ${snapshot.docs.length} bills");
      for (var doc in snapshot.docs) {
        print("Bill ID: ${doc.id}, Data: ${doc.data()}");
      }
      setState(() {
        _billCount = snapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching bills: $e");
    }
  }

  //sale
  Future<void> fetchUserCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _userCount = snapshot.docs.length;
    });
  }
  Future<void> fetchProductCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _productCount = snapshot.docs.length;
    });
  }
  Future<void> fetchPromotionCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('promotions').get();
    setState(() {
      _promotionCount = snapshot.docs.length;
    });
  }
  Future<void> _fetchDiscountCount() async {
      final snap = await FirebaseFirestore.instance.collection('discounts').get();
      setState(() {
        _discountCount = snap.docs.length;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Bills'),
              onTap: () {
                Navigator.push(
                context,
                  MaterialPageRoute(builder: (context) => const AllBillsPage()),
              );
                },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Promotions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PromotionsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Customers'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard('Sales Today', 'Rs.${todaySales.toStringAsFixed(0)}', Icons.analytics,onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SalesGraphPage()),
                  );
                }),
                // new ha
                _buildDashboardCard('Bills', '$_billCount', Icons.receipt_long,onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllBillsPage()),
                  );
                }),
                _buildDashboardCard('Products', '$_productCount', Icons.inventory, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductListPage()),
                  );
                }),
                _buildDashboardCard('Customers', '$_userCount', Icons.group, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomersPage()),
                  );
                }),
                _buildDashboardCard('Promotions', '$_promotionCount', Icons.campaign, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PromotionsPage()),
                  );
                }),
                _buildDashboardCard('Discount','$_discountCount', Icons.percent, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiscountsPage()),

                    );
                  },),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPromotionPage()),
                );
              },
              icon: const Icon(Icons.campaign),
              label: const Text('Add New Promotion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDiscountPage()),
                );
              },
              icon: const Icon(Icons.percent),
              label: const Text('Add New Discount'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.orange),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
