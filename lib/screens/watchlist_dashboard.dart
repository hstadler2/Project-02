import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchlistDashboard extends StatefulWidget {
  @override
  _WatchlistDashboardState createState() => _WatchlistDashboardState();
}

class _WatchlistDashboardState extends State<WatchlistDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Tech', 'Crypto'];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    Query watchlistQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('watchlist');

    if (_selectedCategory != 'All') {
      watchlistQuery = watchlistQuery.where('category',
          isEqualTo: _selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Watchlist'),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (val) {
                setState(() => _selectedCategory = val!);
              },
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: watchlistQuery
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError)
                  return Center(child: Text('Error: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('Your watchlist is empty.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final symbol = docs[i].id;
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(symbol),
                      subtitle: Text(
                          'Category: ${data['category'] ?? 'Uncategorized'}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .collection('watchlist')
                              .doc(symbol)
                              .delete();
                        },
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/detail', arguments: symbol);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
