// lib/screens/stock_search.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/stock_api.dart';

class StockSearch extends StatefulWidget {
  @override
  _StockSearchState createState() => _StockSearchState();
}

class _StockSearchState extends State<StockSearch> {
  final _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  Set<String> _watchlist = {};

  @override
  void initState() {
    super.initState();
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('watchlist')
          .snapshots()
          .listen((snap) {
        setState(() {
          _watchlist = snap.docs.map((d) => d.id).toSet();
        });
      });
    }
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _isLoading = true;
      _results = [];
    });
    final list = await StockApi.search(q);
    setState(() {
      _results = list;
      _isLoading = false;
    });
  }

  void _toggleWatchlist(String symbol) {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('watchlist')
        .doc(symbol);
    if (_watchlist.contains(symbol)) {
      ref.delete();
    } else {
      ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Stocks')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter symbol or company name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            SizedBox(height: 12),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _search, child: Text('Search')),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final sym = _results[i]['symbol']!;
                  final desc = _results[i]['description']!;
                  final inList = _watchlist.contains(sym);
                  return ListTile(
                    title: Text(sym),
                    subtitle: Text(desc),
                    trailing: IconButton(
                      icon:
                      Icon(inList ? Icons.remove_circle : Icons.add_circle),
                      onPressed: () => _toggleWatchlist(sym),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
