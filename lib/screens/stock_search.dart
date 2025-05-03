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
  final _user = FirebaseAuth.instance.currentUser;
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  Set<String> _watchlist = {};

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
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
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _results.clear();
    });
    final list = await StockApi.search(query);
    setState(() {
      _results = list;
      _isLoading = false;
    });
  }

  void _toggleWatchlist(String symbol) {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
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
      appBar: AppBar(title: const Text('Search Stocks')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter symbol or company name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _search,
              child: const Text('Search'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final sym = _results[i]['symbol']!;
                  final desc = _results[i]['description']!;
                  final inList = _watchlist.contains(sym);
                  return ListTile(
                    title: Text(sym),
                    subtitle: Text(desc),
                    trailing: IconButton(
                      icon: Icon(inList
                          ? Icons.remove_circle
                          : Icons.add_circle),
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
