import 'package:flutter/material.dart';

class WatchlistDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Watchlist Dashboard'),
      ),
      body: Center(
        child: Text('Bro, your watchlist will show up here'), // TODO: hook up Firestore
      ),
    );
  }
}