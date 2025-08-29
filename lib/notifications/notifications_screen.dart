import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                size: 60,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you about your achievements,\nworkout reminders, and more!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 