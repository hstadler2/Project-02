import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/stock_api.dart';

class StockDetail extends StatefulWidget {
  final String symbol;
  StockDetail({required this.symbol});

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
    final hist = await StockApi.getHistorical(widget.symbol);
    final quote = await StockApi.getQuote(widget.symbol);
    setState(() {
      _history = hist;
      _currentPrice = quote;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If there's no historical data at all, show a message
    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
        body: Center(child: Text('No historical data available')),
      );
    }

    // Compute a non-zero interval for the bottom titles
    double rawInterval = (_history.length / 5).floorToDouble();
    final interval = rawInterval < 1.0 ? 1.0 : rawInterval;

    return Scaffold(
      appBar: AppBar(
        title: Text('\$${widget.symbol.toUpperCase()}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Current price
            Text(
              _currentPrice != null
                  ? '\$${_currentPrice!.toStringAsFixed(2)}'
                  : '–',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Line chart
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _history
                          .map((dp) => FlSpot(
                        dp.time.millisecondsSinceEpoch.toDouble(),
                        dp.price,
                      ))
                          .toList(),
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        getTitlesWidget: (value, _) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Text('${date.month}/${date.day}');
                        },
                      ),
                    ),
                    leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  gridData: FlGridData(show: false),
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
