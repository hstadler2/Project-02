// lib/services/stock_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;


const _finnhubKey = 'd0ah87hr01qm3l9ldmmgd0ah87hr01qm3l9ldmn0';

class StockApi {
  /// Search endpoint
  static Future<List<Map<String, String>>> search(String query) async {
    final url = Uri.parse(
        'https://finnhub.io/api/v1/search?q=$query&token=$_finnhubKey');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body);
    final List results = body['result'] ?? [];
    return results.map<Map<String, String>>((item) {
      return {
        'symbol': item['symbol'] as String,
        'description': item['description'] as String? ?? '',
      };
    }).toList();
  }

  /// Current quote (closing) price
  static Future<double?> getQuote(String symbol) async {
    final url = Uri.parse(
        'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$_finnhubKey');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body);
    return (body['c'] as num?)?.toDouble();
  }

  /// Historical candles for the last 30 days
  static Future<List<TimeSeriesPrice>> getHistorical(String symbol) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
    final to = now.millisecondsSinceEpoch ~/ 1000;
    final url = Uri.parse(
      'https://finnhub.io/api/v1/stock/candle?symbol=$symbol'
          '&resolution=D&from=$from&to=$to&token=$_finnhubKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body);
    final times = (body['t'] as List).cast<int>();
    final closes = (body['c'] as List).cast<num>();
    return List.generate(times.length, (i) {
      return TimeSeriesPrice(
        DateTime.fromMillisecondsSinceEpoch(times[i] * 1000),
        closes[i].toDouble(),
      );
    });
  }
}

/// Simple time-series data class for charts_flutter
class TimeSeriesPrice {
  final DateTime time;
  final double price;
  TimeSeriesPrice(this.time, this.price);
}
