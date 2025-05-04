import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsApi {
  static const _apiKey = 'd0ah87hr01qm3l9ldmmgd0ah87hr01qm3l9ldmn0';

  static Future<List<Map<String, String>>> getHeadlines() async {
    final uri = Uri.https('finnhub.io', '/api/v1/news', {
      'category': 'general',
      'token':    _apiKey,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

    final raw = resp.body.trim();
    if (raw.startsWith('<')) throw Exception('Rate-limited or invalid response');

    final List<dynamic> data = json.decode(raw) as List<dynamic>;
    return data.map((item) => {
      'title'      : item['headline'] as String? ?? '',
      'description': item['summary']  as String? ?? '',
      'url'        : item['url']      as String? ?? '',
    }).toList();
  }
}
