import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/onboarding_login.dart';
import 'screens/signup.dart';
import 'screens/watchlist_dashboard.dart';
import 'screens/stock_search.dart';
import 'screens/stock_detail.dart';
import 'screens/news_feed.dart';
import 'screens/profile_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // bro, connect to Firebase
  );
  runApp(StockTrackerApp());
}

class StockTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockTracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (_) => OnboardingLogin(),
        '/signup': (_) => SignUpScreen(),
        '/watchlist': (_) => WatchlistDashboard(),
        '/search': (_) => StockSearch(),
        '/news': (_) => NewsFeed(),
        '/profile': (_) => ProfileSettings(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final symbol = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => StockDetail(symbol: symbol),
          );
        }
        return null;
      },
    );
  }
}
