import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/stock_api.dart';

/// Displays your watchlist with Current Price or Holding Duration views.
class WatchlistDashboard extends StatefulWidget {
  const WatchlistDashboard({Key? key}) : super(key: key);

  @override
  _WatchlistDashboardState createState() => _WatchlistDashboardState();
}

class _WatchlistDashboardState extends State<WatchlistDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _viewMode = 'Current Price';
  final _viewModes = ['Current Price', 'Holding Duration'];

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final watchRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('watchlist');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/news'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // View selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('View:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _viewMode,
                  items: _viewModes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _viewMode = val);
                  },
                ),
              ],
            ),
          ),

          // Watchlist stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              watchRef.orderBy('addedAt', descending: true).snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Your watchlist is empty.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final symbol = docs[i].id;
                    final data   = docs[i].data()! as Map<String, dynamic>;
                    final addedAt =
                    (data['addedAt'] as Timestamp).toDate();

                    // Subtitle based on view
                    Widget subtitle;
                    if (_viewMode == 'Current Price') {
                      subtitle = FutureBuilder<double?>(
                        future: StockApi.getLatestPrice(symbol),
                        builder: (ctx, qs) {
                          if (qs.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading…');
                          }
                          final price = qs.data;
                          if (price == null) {
                            return const Text('N/A');
                          }
                          // match the detail-page style
                          return Text(
                            NumberFormat.simpleCurrency()
                                .format(price),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          );
                        },
                      );
                    } else {
                      final daysHeld = DateTime.now()
                          .difference(addedAt)
                          .inDays;
                      final label = daysHeld > 0
                          ? '$daysHeld day${daysHeld > 1 ? 's' : ''}'
                          : '<1 day';
                      subtitle = Text('Held: $label');
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: ListTile(
                        title: Text(symbol),
                        subtitle: subtitle,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              watchRef.doc(symbol).delete(),
                        ),
                        onTap: () => Navigator.of(context)
                            .pushNamed('/detail', arguments: symbol),
                      ),
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
