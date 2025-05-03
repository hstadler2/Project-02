import 'package:flutter/material.dart';

class ProfileSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: const Center(
        child: Text('Sign in/out and preferences go here'), // TODO: Firebase Auth
      ),
    );
  }
}