import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/news_api.dart';

class NewsFeed extends StatefulWidget {
  @override
  _NewsFeedState createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  List<Map<String, String>> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final articles = await NewsApi.getHeadlines();
      setState(() {
        _articles = articles;
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load news')),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Market News')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_articles[index]['title'] ?? ''),
          subtitle: Text(_articles[index]['description'] ?? ''),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Article')),
                  body: WebViewWidget(
                    controller: WebViewController()
                      ..loadRequest(Uri.parse(_articles[index]['url']!)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
