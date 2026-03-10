import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../recordbook/recordbookpage.dart';
import 'registerpage.dart';
import 'resetpasswordpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (credential.user != null) {
        if (!mounted) return;
        
        // Show dialog asking whether to load from cloud or use local
        final choice = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Load Cloud Data?'),
            content: const Text('Would you like to load your latest account data from the cloud, or keep the current local data? (Loading from cloud will overwrite current local changes)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('local'),
                child: const Text('Keep Local'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('cloud'),
                child: const Text('Load Cloud'),
              ),
            ],
          ),
        );
        
        if (choice == 'cloud') {
          try {
            final snapshot = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              RecordBookData.balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
              if (data['startDate'] != null) {
                RecordBookData.startDate = DateTime.parse(data['startDate']);
              }
              if (data['endDate'] != null) {
                RecordBookData.endDate = DateTime.parse(data['endDate']);
              }
              if (data['categories'] != null) {
                final cats = data['categories'] as List<dynamic>;
                RecordBookData.categories = cats.map((c) => SpendingCategory.fromJson(c as Map<String, dynamic>)).toList();
              }
            }
          } catch (e) {
            _showMessage('Failed to sync cloud data. Proceeding with local data.');
          }
        }
      }
      
      if (!mounted) return;
      _goToAppShell();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Login failed.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('An error occurred during login.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _buildFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFFB8C5D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(width: 1.5, color: Color(0xFF002D72)),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _openReset() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
    );
  }

  void _goToAppShell() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 420.0;
    return Scaffold(
      backgroundColor: const Color(0xFF004AAD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004AAD),
        elevation: 0,
        leading: const BackButton(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final loginHeight = constraints.maxHeight * 0.60;
            return SingleChildScrollView(
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/Logo.png',
                              width: 160,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'SGUARD',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          minHeight: loginHeight,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, -8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: _buildFieldDecoration('Email'),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: _buildFieldDecoration('Password'),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.trim().length < 6) {
                                        return 'Password should be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _openReset,
                                      child: const Text('Reset Password'),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _rememberMe = value);
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      const Flexible(
                                        child: Text('Remember me'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('LOGIN'),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _showMessage('Google sign-in is coming soon.');
                                    },
                                    icon: const Icon(Icons.login),
                                    label: const Text('Sign in using Google'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 20),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Don’t Have an Account? '),
                                      TextButton(
                                        onPressed: _openRegister,
                                        child: const Text('Create an Account'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
