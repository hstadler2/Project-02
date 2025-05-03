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
    try {
      final hist = await StockApi.getHistorical(widget.symbol);
      final quote = await StockApi.getQuote(widget.symbol);
      setState(() {
        _history = hist;
        _currentPrice = quote;
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
        body: Center(child: Text('No historical data available')),
      );
    }

    double rawInterval = (_history.length / 5).floorToDouble();
    final interval = rawInterval < 1.0 ? 1.0 : rawInterval;

    double percentChange =
        ((_currentPrice! - _history.first.price) / _history.first.price) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text('\$${widget.symbol.toUpperCase()}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _currentPrice != null
                  ? '\$${_currentPrice!.toStringAsFixed(2)}'
                  : '–',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              '${percentChange.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 18,
                color: percentChange >= 0 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 16),
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) =>
                            Text('\$${value.toStringAsFixed(2)}'),
                      ),
                    ),
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
