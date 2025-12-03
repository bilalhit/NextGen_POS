import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesGraphPage extends StatefulWidget {
  const SalesGraphPage({super.key});

  @override
  State<SalesGraphPage> createState() => _SalesGraphPageState();
}

class _SalesGraphPageState extends State<SalesGraphPage> {
  bool showWeekly = true;
  List<Map<String, dynamic>> salesData = [];
  double totalSales = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSalesData();
  }

  Future<void> fetchSalesData() async {
    setState(() => isLoading = true);

    final now = DateTime.now();
    final startDate = showWeekly
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month - 1, 1);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Bills')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          salesData = [];
          totalSales = 0;
          isLoading = false;
        });
        return;
      }

      final groupedData = <String, double>{};
      double total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['total'] ?? 0).toDouble();
        final date = (data['createdAt'] as Timestamp).toDate();

        final key = showWeekly
            ? DateFormat('EEE').format(date) // e.g. Mon, Tue
            : DateFormat('MMM').format(date); // e.g. Jan, Feb

        groupedData[key] = (groupedData[key] ?? 0) + amount;
        total += amount;
      }

      final sortedData = groupedData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      setState(() {
        totalSales = total;
        salesData =
            sortedData.map((e) => {'label': e.key, 'value': e.value}).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sales data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Overview'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.green),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between weekly and monthly
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showWeekly ? 'Weekly Sales' : 'Monthly Sales',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: showWeekly,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() {
                      showWeekly = val;
                      fetchSalesData();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Total Sales: Rs. ${totalSales.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: salesData.isEmpty
                  ? const Center(
                child: Text(
                  'No sales data available',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < salesData.length) {
                            return Text(
                              salesData[index]['label'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toInt().toString(),
                            style:
                            const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(salesData.length, (i) {
                    final val =
                    salesData[i]['value'] as double;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: Colors.orange,
                          width: 20,
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
