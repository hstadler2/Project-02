import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login screen with email/password, validation, and navigation.
class OnboardingLogin extends StatefulWidget {
  const OnboardingLogin({Key? key}) : super(key: key);

  @override
  _OnboardingLoginState createState() => _OnboardingLoginState();
}

class _OnboardingLoginState extends State<OnboardingLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
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
          .signInWithEmailAndPassword(email: email, password: pw);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            children: [
              const FlutterLogo(size: 72),
              const SizedBox(height: 24),
              Text(
                'Welcome to StockTracker',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.indigo),
              ),
              const SizedBox(height: 32),
              Card(
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
                          onPressed: _login, child: const Text('Login')),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/signup'),
                        child: const Text('Don’t have an account? Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
