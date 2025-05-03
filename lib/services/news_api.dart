import 'dart:convert';
import 'package:http/http.dart' as http;


class NewsApi {
  static const _apiKey = 'YOUR_NEWSAPI_KEY';
  static const _baseUrl = 'https://newsapi.org/v2/top-headlines';

  static Future<List<Map<String, String>>> getHeadlines() async {
    final response = await http.get(
      Uri.parse('$_baseUrl?country=us&apiKey=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List articles = data['articles'];
      return articles.map<Map<String, String>>((article) {
        return {
          'title': article['title'] ?? '',
          'description': article['description'] ?? '',
          'url': article['url'] ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}
