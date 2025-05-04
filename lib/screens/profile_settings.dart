import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // for themeNotifier

/// Displays user email, dark mode switch, and sign-out button.
class ProfileSettings extends StatelessWidget {
  const ProfileSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'unknown@';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(email),
                subtitle: const Text('Email'),
              ),
            ),
            const SizedBox(height: 24),
            // Dark mode toggle
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeNotifier.value == ThemeMode.dark,
              onChanged: (val) {
                themeNotifier.value =
                val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
