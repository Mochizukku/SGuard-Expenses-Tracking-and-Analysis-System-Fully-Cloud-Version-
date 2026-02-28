import 'package:flutter/material.dart';

class ProfileActionPage extends StatelessWidget {
  const ProfileActionPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 2,
      ),
      body: Center(
        child: Text(
          'The $title page is under construction.',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
