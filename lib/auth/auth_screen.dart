import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: const Center(
        child: Text('Authentication Screen - Coming Soon'),
      ),
    );
  }
} 