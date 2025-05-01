import 'package:flutter/material.dart';

class NewsFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market News'),
      ),
      body: ListView.builder(
        itemCount: 5, // dummy count
        itemBuilder: (context, index) => ListTile(
          title: Text('News headline #\$index'),
          subtitle: Text('Snippet of the article...'),
          onTap: () {}, // TODO: open article
        ),
      ),
    );
  }
}