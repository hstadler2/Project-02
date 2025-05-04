import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_api.dart';  // now has SearchResult

/// UI for searching tickers and adding/removing them from your watchlist.
class StockSearch extends StatefulWidget {
  const StockSearch({Key? key}) : super(key: key);

  @override
  _StockSearchState createState() => _StockSearchState();
}

class _StockSearchState extends State<StockSearch> {
  final _controller = TextEditingController();
  final _user       = FirebaseAuth.instance.currentUser;
  List<SearchResult> _results  = [];     // <-- SearchResult works again
  bool _isLoading    = false;
  Set<String> _watchlist = {};

  @override
  void initState() {
    super.initState();
    // keep _watchlist in sync
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
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
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _results.clear();
    });
    try {
      _results = await StockApi.search(q);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Search failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleWatchlist(String symbol) {
    if (_user == null) return;
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
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Symbol or company name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.search), onPressed: _search),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final item = _results[i];
                  final inList = _watchlist.contains(item.symbol);
                  return ListTile(
                    title: Text(item.symbol),
                    subtitle: Text(item.description),
                    trailing: IconButton(
                      icon: Icon(inList ? Icons.remove_circle : Icons.add_circle),
                      color: inList ? Colors.red : Colors.green,
                      onPressed: () => _toggleWatchlist(item.symbol),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
