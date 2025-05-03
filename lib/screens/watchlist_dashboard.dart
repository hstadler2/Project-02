import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchlistDashboard extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('watchlist')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Your watchlist is empty.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final symbol = docs[i].id;
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(symbol),
                subtitle: Text(
                  'Added: ${data['addedAt'] != null ? (data['addedAt'] as Timestamp).toDate() : '—'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('watchlist')
                      .doc(symbol)
                      .delete(),
                ),
                onTap: () => Navigator.of(context).pushNamed(
                  '/detail',
                  arguments: symbol,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
