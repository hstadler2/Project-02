import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_api.dart';

class StockDetail extends StatefulWidget {
  final String symbol;
  const StockDetail({required this.symbol});

  @override
  _StockDetailState createState() => _StockDetailState();
}

class _StockDetailState extends State<StockDetail> {
  bool _loading = true;
  List<TimeSeriesPrice> _history = [];
  double? _currentPrice;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid    = FirebaseAuth.instance.currentUser!.uid;
    final symbol = widget.symbol.toUpperCase();

    // 1) Load cached history from Firestore
    final localSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('historical')
        .doc(symbol)
        .collection('prices')
        .orderBy(FieldPath.documentId)
        .get();

    final local = localSnap.docs.map((d) {
      final date = DateTime.parse(d.id);
      return TimeSeriesPrice(
        date,
        (d.data()['price'] as num).toDouble(),
      );
    }).toList();

    // 2) Decide where to fetch from
    DateTime from;
    if (local.isNotEmpty) {
      from = local.last.time.add(const Duration(days: 1));
    } else {
      from = DateTime.now().subtract(const Duration(days: 30));
    }

    // 3) Fetch missing slice from Finnhub
    final missing = await StockApi.getHistoricalRange(
      symbol,
      from: from,
      to: DateTime.now(),
    );

    // 4) Batch-write missing to Firestore
    final batch = FirebaseFirestore.instance.batch();
    final pricesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('historical')
        .doc(symbol)
        .collection('prices');

    for (final dp in missing) {
      final id = dp.time.toIso8601String().substring(0, 10); // “YYYY-MM-DD”
      batch.set(pricesCol.doc(id), {
        'price': dp.price,
        'fetchedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // 5) Fetch current quote
    final quote = await StockApi.getQuote(symbol);

    // 6) Merge + render
    setState(() {
      _history      = [...local, ...missing];
      _currentPrice = quote;
      _loading      = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbol.toUpperCase();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('\$$symbol')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('\$$symbol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current price
            Text(
              _currentPrice != null
                  ? '\$${_currentPrice!.toStringAsFixed(2)}'
                  : '–',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chart or “no data”
            Expanded(
              child: _history.isEmpty
                  ? const Center(child: Text('No historical data available'))
                  : LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _history.map((dp) {
                        return FlSpot(
                          dp.time.millisecondsSinceEpoch.toDouble(),
                          dp.price,
                        );
                      }).toList(),
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // interval ≥1
                        interval: (_history.length / 5).clamp(1, double.infinity),
                        getTitlesWidget: (value, _) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.month}/${date.day}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
