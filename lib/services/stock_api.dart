import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple DTO for historical price points
class TimeSeriesPrice {
  final DateTime time;
  final double price;
  TimeSeriesPrice(this.time, this.price);
}

class StockApi {
  // Used for symbol search
  static const _finnKey = 'd0ah87hr01qm3l9ldmmgd0ah87hr01qm3l9ldmn0';
  // Vantage key
  static const _avKey  = 'EOZ6Z0BVW221C5BK';

  /// Search for symbols/descriptions via Finnhub
  static Future<List<Map<String, String>>> search(String query) async {
    final url = Uri.parse(
      'https://finnhub.io/api/v1/search?q=$query&token=$_finnKey',
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

  /// Get current quote via Alpha Vantage GLOBAL_QUOTE
  static Future<double?> getQuote(String symbol) async {
    final url = Uri.parse(
      'https://www.alphavantage.co/query'
          '?function=GLOBAL_QUOTE'
          '&symbol=$symbol'
          '&apikey=$_avKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body);
    final quote = body['Global Quote']?['05. price'];
    return quote != null ? double.tryParse(quote) : null;
  }

  /// Fetch last ~30 trading days of closes via Alpha Vantage TIME_SERIES_DAILY
  static Future<List<TimeSeriesPrice>> getHistorical(String symbol) async {
    final url = Uri.parse(
      'https://www.alphavantage.co/query'
          '?function=TIME_SERIES_DAILY'
          '&symbol=$symbol'
          '&apikey=$_avKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body);
    final daily = body['Time Series (Daily)'] as Map<String, dynamic>?;
    if (daily == null) return [];

    // Parse into a list, sort by date ascending:
    final entries = daily.entries
        .map((e) {
      final dt = DateTime.parse(e.key);
      final close = double.tryParse(e.value['4. close']) ?? 0;
      return TimeSeriesPrice(dt, close);
    })
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // Take only the last 30 days (or fewer if <30 available)
    final start = entries.length > 30 ? entries.length - 30 : 0;
    return entries.sublist(start);
  }
}
