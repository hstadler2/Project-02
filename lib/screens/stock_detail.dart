import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/stock_api.dart';

/// Shows a 30-day price chart with “current” price & % change.
/// “Current” now = the last daily close from Yahoo (matching the watchlist).
class StockDetail extends StatefulWidget {
  final String symbol;
  const StockDetail({Key? key, required this.symbol}) : super(key: key);

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
    setState(() => _loading = true);
    final hist = await StockApi.getHistorical(widget.symbol);

    // set the “current” price to the last close in history
    final latest = hist.isNotEmpty ? hist.last.price : null;

    setState(() {
      _history      = hist;
      _currentPrice = latest;
      _loading      = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbol.toUpperCase();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('\$$sym')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('\$$sym')),
        body: const Center(child: Text('No historical data available')),
      );
    }

    // build chart points
    final spots = List<FlSpot>.generate(
      _history.length,
          (i) => FlSpot(i.toDouble(), _history[i].price),
    );
    final count = _history.length.toDouble();
    final step  = (count - 1) / 4;

    // X-axis labels (5 evenly spaced dates)
    final dateLabels = List.generate(5, (i) {
      final dt = _history[(step * i).round()].time;
      return '${dt.month}/${dt.day}';
    });

    // Y-axis min/max
    final prices = _history.map((e) => e.price);
    final minY   = prices.reduce((a, b) => a < b ? a : b);
    final maxY   = prices.reduce((a, b) => a > b ? a : b);

    // compute % change & format current price
    final first     = _history.first.price;
    final current   = _currentPrice ?? first;
    final pctChange = ((current - first) / first) * 100;
    final priceFmt  = NumberFormat.simpleCurrency().format(current);

    return Scaffold(
      appBar: AppBar(title: Text('\$$sym')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // “current” price
            Text(priceFmt,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            // % change
            Text('${pctChange.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: pctChange >= 0 ? Colors.green : Colors.red)),
            const SizedBox(height: 16),
            // the 30-day line chart
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: count - 1,
                  minY: minY * 0.98,
                  maxY: maxY * 1.02,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles     : true,
                        interval       : step,
                        getTitlesWidget: (v, _) {
                          final ix = (v / step).round().clamp(0, 4);
                          return Text(dateLabels[ix],
                              style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles     : true,
                        interval       : (maxY - minY) / 4,
                        reservedSize   : 60,
                        getTitlesWidget: (v, _) => Text(
                          NumberFormat.simpleCurrency().format(v),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
