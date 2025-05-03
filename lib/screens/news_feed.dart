// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

class NewsFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market News'),
      ),
      body: ListView.builder(
        itemCount: 5, // dummy count
        itemBuilder: (context, index) => ListTile(
          title: const Text('News headline #\$index'),
          subtitle: const Text('Snippet of the article...'),
          onTap: () {}, // TODO: open article
        ),
      ),
    );
  }
}