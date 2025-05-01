import 'package:flutter/material.dart';

class StockDetail extends StatelessWidget {
  final String symbol;
  StockDetail({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('\$${symbol.toUpperCase()}'),
      ),
      body: Center(
        child: Text('Historical chart and data for $symbol'), // TODO: add charts
      ),
    );
  }
}