import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Sign-up screen: create new Firebase Auth user.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final pw = _passwordController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        throw FirebaseAuthException(
            code: 'invalid-email', message: 'Enter a valid email');
      }
      if (pw.length < 6) {
        throw FirebaseAuthException(
            code: 'weak-password',
            message: 'Password must be at least 6 characters');
      }
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pw);
      Navigator.of(context).pushReplacementNamed('/watchlist');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                      onPressed: _signup, child: const Text('Create Account')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
