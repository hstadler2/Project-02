import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple DTO for historical price points
class TimeSeriesPrice {
  final DateTime time;
  final double price;
  TimeSeriesPrice(this.time, this.price);
}

class StockApi {

  static const _apiKey = 'd0ah87hr01qm3l9ldmmgd0ah87hr01qm3l9ldmn0';

  /// Search for symbols/descriptions
  static Future<List<Map<String, String>>> search(String query) async {
    final url = Uri.parse(
      'https://finnhub.io/api/v1/search?q=$query&token=$_apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body);
    final List results = body['result'] ?? [];
    return results.map<Map<String, String>>((item) {
      return {
        'symbol': item['symbol'] as String,
        'description': (item['description'] as String?) ?? '',
      };
    }).toList();
  }

  /// Get current quote (last close)
  static Future<double?> getQuote(String symbol) async {
    final url = Uri.parse(
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$_apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body);
    return (body['c'] as num?)?.toDouble();
  }

  /// Fetch the last 30 days of daily closes
  static Future<List<TimeSeriesPrice>> getHistorical(String symbol) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
    final to = now.millisecondsSinceEpoch ~/ 1000;
    final url = Uri.parse(
      'https://finnhub.io/api/v1/stock/candle'
          '?symbol=$symbol'
          '&resolution=D'
          '&from=$from'
          '&to=$to'
          '&token=$_apiKey',
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
