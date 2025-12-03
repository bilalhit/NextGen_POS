import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryGreen = Color(0xFF00A86B);
const Color accentOrange = Color(0xFFE68030);

class AddDiscountPage extends StatefulWidget {
  const AddDiscountPage({super.key});

  @override
  State<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends State<AddDiscountPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  List<String> categories = [
    'All', 'Fruits', 'Vegetables', 'Electronics', 'Grocery', 'Bakery',
    'Beverages', 'Dairy Products', 'Frozen Foods', 'Snacks',
    'Household Supplies', 'Stationery', 'Clothing', 'Footwear',
    'Toys', 'Cosmetics', 'Personal Care', 'Baby Products', 'Pet Supplies',
    'Home Decor', 'Furniture', 'Kitchenware', 'Hardware Tools',
    'Automotive', 'Books', 'Sports & Fitness', 'Gardening',
    'Mobile Accessories', 'Computers & Laptops', 'Jewelry', 'Watches',
  ];

  List<String> selectedCategories = [];

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => endDate = date);
    }
  }

  Future<void> _saveDiscount() async {
    if (titleController.text.isEmpty ||
        percentageController.text.isEmpty ||
        startDate == null ||
        endDate == null ||
        selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('discounts').add({
      'title': titleController.text,
      'percentage': percentageController.text,
      'startDate': "${startDate!.day}/${startDate!.month}/${startDate!.year}",
      'endDate': "${endDate!.day}/${endDate!.month}/${endDate!.year}",
      'categories': selectedCategories,
      'createdAt': DateTime.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Discount"),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Discount Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: percentageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Discount Percentage (%)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Start Date
            ListTile(
              leading: const Icon(Icons.calendar_month, color: primaryGreen),
              title: Text(startDate == null
                  ? "Select Start Date"
                  : "Start Date: ${startDate!.day}/${startDate!.month}/${startDate!.year}"),
              onTap: _pickStartDate,
            ),

            // End Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: primaryGreen),
              title: Text(endDate == null
                  ? "Select End Date"
                  : "End Date: ${endDate!.day}/${endDate!.month}/${endDate!.year}"),
              onTap: _pickEndDate,
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Categories",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...categories.map((category) {
              return CheckboxListTile(
                activeColor: primaryGreen,
                title: Text(category),
                value: selectedCategories.contains(category),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedCategories.add(category);
                    } else {
                      selectedCategories.remove(category);
                    }
                  });
                },
              );
            }),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveDiscount,
              child: const Text(
                "Save Discount",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
