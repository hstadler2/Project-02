import 'dart:convert';
import 'package:http/http.dart' as http;

/// Holds a timestamped price point.
class TimeSeriesPrice {
  final DateTime time;
  final double price;
  TimeSeriesPrice(this.time, this.price);
}

/// Simple DTO for a stock search result.
class SearchResult {
  final String symbol;
  final String description;
  SearchResult({required this.symbol, required this.description});
}

/// Central API for stocks:
/// • Finnhub for search & news
/// • AlphaVantage for real-time quotes (optional)
/// • Yahoo Finance for 1-month history (daily) & latest close
class StockApi {
  static const _finnKey = 'd0ah87hr01qm3l9ldmmgd0ah87hr01qm3l9ldmn0';
  static const _avKey   = 'EOZ6Z0BVW221C5BK';

  /// 1) Search symbols via Finnhub → [SearchResult]
  static Future<List<SearchResult>> search(String q) async {
    final uri = Uri.https('finnhub.io', '/api/v1/search', {
      'q': q,
      'token': _finnKey,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body) as Map<String, dynamic>;
    final raw  = body['result'] as List<dynamic>? ?? [];
    return raw.map((e) {
      return SearchResult(
        symbol:      e['symbol']      as String,
        description: e['description'] as String? ?? '',
      );
    }).toList();
  }

  /// 2) (Optional) Real-time quote via AlphaVantage GLOBAL_QUOTE
  static Future<double?> getQuote(String symbol) async {
    final uri = Uri.https('www.alphavantage.co', '/query', {
      'function': 'GLOBAL_QUOTE',
      'symbol'  : symbol,
      'apikey'  : _avKey,
    });
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final raw = resp.body.trim();
      if (raw.startsWith('<')) return null; // HTML rate-limit page
      final body = json.decode(raw) as Map<String, dynamic>;
      if (body.containsKey('Note') || body.containsKey('Error Message')) {
        return null;
      }
      final priceStr = body['Global Quote']?['05. price'] as String?;
      return priceStr != null ? double.tryParse(priceStr) : null;
    } catch (_) {
      return null;
    }
  }

  /// 3) Last ~30 days daily closes via Yahoo Finance chart API
  static Future<List<TimeSeriesPrice>> getHistorical(String symbol) async {
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$symbol',
      {'range': '1mo', 'interval': '1d'},
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return [];
      final body    = json.decode(resp.body) as Map<String, dynamic>;
      final results = (body['chart']?['result'] ?? []) as List<dynamic>;
      if (results.isEmpty) return [];

      final meta       = results[0] as Map<String, dynamic>;
      final timestamps = List<int>.from(
          meta['timestamp'] as List<dynamic>? ?? []);
      final quoteData  = meta['indicators']?['quote']?[0]?['close']
      as List<dynamic>?;

      if (quoteData == null || timestamps.length != quoteData.length) {
        return [];
      }

      final list = <TimeSeriesPrice>[];
      for (var i = 0; i < timestamps.length; i++) {
        final dt    = DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);
        final price = (quoteData[i] as num).toDouble();
        list.add(TimeSeriesPrice(dt, price));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// 4) Helper: latest close = last element of 1-month history
  static Future<double?> getLatestPrice(String symbol) async {
    try {
      final hist = await getHistorical(symbol);
      return hist.isNotEmpty ? hist.last.price : null;
    } catch (_) {
      return null;
    }
  }
}
