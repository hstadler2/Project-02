import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/stock_api.dart';

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
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
        body: const Center(child: Text('No historical data available')),
      );
    }

    // Map our history into FlSpots
    final spots = List<FlSpot>.generate(
      _history.length,
          (i) => FlSpot(i.toDouble(), _history[i].price),
    );

    // Prepare X-axis date labels (5 evenly spaced points)
    const labelCount = 5;
    final step = (_history.length - 1) / (labelCount - 1);
    final dateLabels = List<String>.generate(labelCount, (i) {
      final dt = _history[(step * i).round()].time;
      return '${dt.month}/${dt.day}';
    });

    // Find min/max for Y bounds
    final prices = _history.map((e) => e.price);
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text('\$${widget.symbol.toUpperCase()}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current price
            Text(
              _currentPrice != null
                  ? NumberFormat.simpleCurrency().format(_currentPrice)
                  : '–',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // The polished line chart
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (_history.length - 1).toDouble(),
                  minY: minY * 0.98,
                  maxY: maxY * 1.02,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: step,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          final labelIx = (idx / step).round();
                          if (labelIx >= 0 && labelIx < dateLabels.length) {
                            return Text(
                              dateLabels[labelIx],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxY - minY) / 4,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.simpleCurrency().format(value),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
